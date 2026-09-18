use std::ffi::{OsStr, OsString};
use std::fs::File;
use std::io::{self, IsTerminal, PipeReader, PipeWriter, Read, Write};
use std::mem::ManuallyDrop;
use std::os::fd::{AsFd, AsRawFd, BorrowedFd, FromRawFd, OwnedFd, RawFd};
use std::os::unix::process::ExitStatusExt;
use std::path::{Path, PathBuf};
use std::process::{Child, Command, ExitStatus, Stdio};
use std::sync::atomic::{AtomicBool, AtomicI32, Ordering};
use std::thread;

use nix::errno::Errno;
use nix::fcntl::{FcntlArg, FdFlag, fcntl};
use nix::poll::{PollFd, PollFlags, PollTimeout, poll};
use nix::pty::{OpenptyResult, Winsize, openpty};
use nix::sys::signal::{SaFlags, SigAction, SigHandler, SigSet, Signal, sigaction, signal};
use nix::sys::termios::{OutputFlags, tcgetattr};
use xxhash_rust::xxh3::Xxh3;

use crate::storage;

const CHUNK_SIZE: usize = 128 * 1024;
const SAVE_LIMIT: u64 = 4 << 30;
const DRAIN_LIMIT: u64 = 256 << 20;

static CHILD_PID: AtomicI32 = AtomicI32::new(0);
static WAKE_FD: AtomicI32 = AtomicI32::new(-1);
static MASTER_FD: AtomicI32 = AtomicI32::new(-1);
static TERMINATING: AtomicBool = AtomicBool::new(false);
static CHILD_EXITED: AtomicBool = AtomicBool::new(false);

nix::ioctl_read_bad!(tiocgwinsz, libc::TIOCGWINSZ, Winsize);
nix::ioctl_write_ptr_bad!(tiocswinsz, libc::TIOCSWINSZ, Winsize);

pub struct Session {
    prog_name: String,
    save_path: PathBuf,
    save_file: File,
    child: Child,
    input_writer: PipeWriter,
    input_reader: PipeReader,
    output_reader: OwnedFd,
    wake_reader: PipeReader,
    wake_writer: PipeWriter,
}

struct Measured {
    total: u64,
    hash: u64,
}

#[derive(Default)]
struct InputResult {
    total: u64,
    hash: u64,
    saved: u64,
    written: u64,
    stopped_early: bool,
}

struct InputState {
    save_file: Option<File>,
    writer: Option<PipeWriter>,
    hasher: Xxh3,
    result: InputResult,
}

pub fn prepare(prog_name: &str, prog: &OsStr, args: &[OsString]) -> io::Result<Session> {
    let (save_path, save_file) =
        storage::create(prog_name).inspect_err(|err| eprintln!("minamo: {err}"))?;
    spawn(prog_name, prog, args, save_path.clone(), save_file).inspect_err(|_| {
        let _ = std::fs::remove_file(&save_path);
    })
}

fn spawn(
    prog_name: &str,
    prog: &OsStr,
    args: &[OsString],
    save_path: PathBuf,
    save_file: File,
) -> io::Result<Session> {
    let (child_stdin, input_writer) = io::pipe()?;
    let input_reader = child_stdin.try_clone()?;
    let (wake_reader, wake_writer) = io::pipe()?;
    let (output_reader, child_stdout) = open_output_channel()?;
    let mut command = Command::new(prog);
    command
        .args(args)
        .stdin(Stdio::from(child_stdin))
        .stdout(Stdio::from(child_stdout));
    let child = command.spawn()?;
    Ok(Session {
        prog_name: prog_name.to_owned(),
        save_path,
        save_file,
        child,
        input_writer,
        input_reader,
        output_reader,
        wake_reader,
        wake_writer,
    })
}

fn open_output_channel() -> io::Result<(OwnedFd, OwnedFd)> {
    let stdout = io::stdout();
    let pty = if stdout.is_terminal() {
        open_pty(stdout.as_fd()).ok()
    } else {
        None
    };
    match pty {
        Some(pty) => {
            MASTER_FD.store(pty.master.as_raw_fd(), Ordering::SeqCst);
            Ok((pty.master, pty.slave))
        }
        None => {
            let (reader, writer) = io::pipe()?;
            Ok((reader.into(), writer.into()))
        }
    }
}

fn open_pty(tty: BorrowedFd) -> nix::Result<OpenptyResult> {
    let mut termios = tcgetattr(tty)?;
    termios.output_flags.remove(OutputFlags::OPOST);
    let winsize = winsize_of(tty.as_raw_fd())?;
    let pty = openpty(&winsize, &termios)?;
    fcntl(&pty.master, FcntlArg::F_SETFD(FdFlag::FD_CLOEXEC))?;
    fcntl(&pty.slave, FcntlArg::F_SETFD(FdFlag::FD_CLOEXEC))?;
    Ok(pty)
}

fn winsize_of(fd: RawFd) -> nix::Result<Winsize> {
    let mut winsize = Winsize {
        ws_row: 0,
        ws_col: 0,
        ws_xpixel: 0,
        ws_ypixel: 0,
    };
    unsafe { tiocgwinsz(fd, &mut winsize) }?;
    Ok(winsize)
}

impl Session {
    pub fn run(self) -> i32 {
        let Session {
            prog_name,
            save_path,
            save_file,
            mut child,
            input_writer,
            mut input_reader,
            output_reader,
            wake_reader,
            mut wake_writer,
        } = self;
        CHILD_PID.store(child.id() as i32, Ordering::SeqCst);
        WAKE_FD.store(wake_writer.as_raw_fd(), Ordering::SeqCst);
        install_signal_handlers();

        let input_thread = thread::spawn(move || run_input(save_file, input_writer, wake_reader));
        let output_thread = thread::spawn(move || run_output(output_reader));

        let status = child.wait();
        CHILD_EXITED.store(true, Ordering::SeqCst);
        let _ = wake_writer.write_all(b"x");
        let drained = io::copy(&mut input_reader, &mut io::sink()).unwrap_or(0);
        let output = output_thread.join().unwrap();
        let input = input_thread.join().unwrap();

        let consumed = input.written.saturating_sub(drained);
        let identical = input.total == output.total && input.hash == output.hash;
        if input.total > 0 && consumed > 0 && !identical {
            eprintln!("{}", notice(&prog_name, &save_path, &input));
        } else {
            let _ = std::fs::remove_file(&save_path);
        }
        exit_code(status)
    }
}

fn install_signal_handlers() {
    let terminate = SigAction::new(
        SigHandler::Handler(on_terminate),
        SaFlags::SA_RESTART,
        SigSet::empty(),
    );
    let winch = SigAction::new(
        SigHandler::Handler(on_winch),
        SaFlags::SA_RESTART,
        SigSet::empty(),
    );
    unsafe {
        let _ = signal(Signal::SIGPIPE, SigHandler::SigIgn);
        let _ = sigaction(Signal::SIGINT, &terminate);
        let _ = sigaction(Signal::SIGTERM, &terminate);
        let _ = sigaction(Signal::SIGWINCH, &winch);
    }
}

extern "C" fn on_terminate(sig: libc::c_int) {
    TERMINATING.store(true, Ordering::SeqCst);
    let pid = CHILD_PID.load(Ordering::SeqCst);
    if pid > 0 {
        unsafe {
            libc::kill(pid, sig);
        }
    }
    let wake = WAKE_FD.load(Ordering::SeqCst);
    if wake >= 0 {
        unsafe {
            libc::write(wake, b"x".as_ptr().cast(), 1);
        }
    }
}

extern "C" fn on_winch(_: libc::c_int) {
    let master = MASTER_FD.load(Ordering::SeqCst);
    if master >= 0
        && let Ok(winsize) = winsize_of(libc::STDOUT_FILENO)
    {
        let _ = unsafe { tiocswinsz(master, &winsize) };
    }
}

fn run_input(save_file: File, input_writer: PipeWriter, wake_reader: PipeReader) -> InputResult {
    let mut stdin = unsafe { File::from_raw_fd(libc::STDIN_FILENO) };
    let mut buf = vec![0u8; CHUNK_SIZE];
    let mut state = InputState {
        save_file: Some(save_file),
        writer: Some(input_writer),
        hasher: Xxh3::new(),
        result: InputResult::default(),
    };
    let mut open = true;
    while open {
        match wait_readable(&stdin, &wake_reader) {
            Ok(ready) => {
                let child_exited = CHILD_EXITED.load(Ordering::SeqCst);
                if TERMINATING.load(Ordering::SeqCst) || child_exited && state.save_file.is_none() {
                    open = false;
                    state.result.stopped_early = true;
                } else if ready {
                    match stdin.read(&mut buf) {
                        Ok(0) => open = false,
                        Ok(n) => {
                            open = process_chunk(&buf[..n], &mut state);
                            state.result.stopped_early = !open;
                        }
                        Err(err) if err.kind() == io::ErrorKind::Interrupted => {}
                        Err(_) => open = false,
                    }
                }
            }
            Err(_) => {
                open = false;
                state.result.stopped_early = true;
            }
        }
    }
    state.result.hash = state.hasher.digest();
    state.result
}

fn wait_readable(stdin: &File, mut wake_reader: &PipeReader) -> io::Result<bool> {
    let mut fds = [
        PollFd::new(stdin.as_fd(), PollFlags::POLLIN),
        PollFd::new(wake_reader.as_fd(), PollFlags::POLLIN),
    ];
    match poll(&mut fds, PollTimeout::NONE) {
        Ok(_) => {
            let stdin_ready = has_events(&fds[0]);
            if has_events(&fds[1]) {
                let mut sink = [0u8; 16];
                let _ = wake_reader.read(&mut sink);
            }
            Ok(stdin_ready)
        }
        Err(Errno::EINTR) => Ok(false),
        Err(err) => Err(err.into()),
    }
}

fn has_events(fd: &PollFd) -> bool {
    fd.revents().map(|flags| !flags.is_empty()).unwrap_or(false)
}

fn process_chunk(chunk: &[u8], state: &mut InputState) -> bool {
    state.result.total += chunk.len() as u64;
    state.hasher.update(chunk);
    if let Some(file) = &mut state.save_file {
        let take = (SAVE_LIMIT - state.result.saved).min(chunk.len() as u64) as usize;
        let written = file.write_all(&chunk[..take]).is_ok();
        if written {
            state.result.saved += take as u64;
        }
        if !written || state.result.saved >= SAVE_LIMIT {
            state.save_file = None;
        }
    }
    let child_alive = !CHILD_EXITED.load(Ordering::SeqCst);
    match state.writer.as_mut() {
        Some(writer) if child_alive => {
            if writer.write_all(chunk).is_ok() {
                state.result.written += chunk.len() as u64;
            } else {
                state.writer = None;
            }
            true
        }
        _ => {
            state.writer = None;
            let read_after_exit = state.result.total - state.result.written;
            read_after_exit < DRAIN_LIMIT && state.save_file.is_some()
        }
    }
}

fn run_output(reader: OwnedFd) -> Measured {
    let mut reader = File::from(reader);
    let mut stdout = ManuallyDrop::new(unsafe { File::from_raw_fd(libc::STDOUT_FILENO) });
    let mut buf = vec![0u8; CHUNK_SIZE];
    let mut hasher = Xxh3::new();
    let mut total = 0u64;
    let mut open = true;
    while open {
        match reader.read(&mut buf) {
            Ok(0) => open = false,
            Ok(n) => {
                total += n as u64;
                hasher.update(&buf[..n]);
                open = stdout.write_all(&buf[..n]).is_ok();
            }
            Err(err) if err.kind() == io::ErrorKind::Interrupted => {}
            Err(_) => open = false,
        }
    }
    Measured {
        total,
        hash: hasher.digest(),
    }
}

fn notice(prog_name: &str, path: &Path, input: &InputResult) -> String {
    let path = path.display();
    if input.stopped_early || input.saved < input.total {
        let saved = storage::human_size(input.saved);
        format!("{prog_name}: saved the first {saved} of the raw input in {path}")
    } else {
        let total = storage::human_size(input.total);
        format!("{prog_name}: saved the raw input in {path} ({total})")
    }
}

fn exit_code(status: io::Result<ExitStatus>) -> i32 {
    match status {
        Ok(status) => status
            .code()
            .or_else(|| status.signal().map(|sig| 128 + sig))
            .unwrap_or(1),
        Err(_) => 1,
    }
}
