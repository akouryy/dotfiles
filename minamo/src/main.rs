mod capture;
mod storage;

use std::ffi::{OsStr, OsString};
use std::fs::File;
use std::io;
use std::mem::ManuallyDrop;
use std::os::fd::FromRawFd;
use std::os::unix::fs::FileTypeExt;
use std::os::unix::process::CommandExt;
use std::path::Path;
use std::process::{Command, exit};

fn main() {
    let args: Vec<OsString> = std::env::args_os().collect();
    if args.len() < 2 {
        eprintln!("usage: minamo <prog> [ARGS...]");
        exit(2);
    }
    let prog = args[1].as_os_str();
    let rest = &args[2..];
    if stdin_is_fifo()
        && let Ok(session) = capture::prepare(&prog_name(prog), prog, rest)
    {
        exit(session.run());
    }
    let err = Command::new(prog).args(rest).exec();
    let prog = prog.to_string_lossy();
    if err.kind() == io::ErrorKind::NotFound {
        eprintln!("minamo: {prog}: command not found");
        exit(127);
    } else {
        eprintln!("minamo: {prog}: {err}");
        exit(126);
    }
}

fn prog_name(prog: &OsStr) -> String {
    Path::new(prog)
        .file_name()
        .unwrap_or(prog)
        .to_string_lossy()
        .into_owned()
}

fn stdin_is_fifo() -> bool {
    let stdin = ManuallyDrop::new(unsafe { File::from_raw_fd(libc::STDIN_FILENO) });
    stdin
        .metadata()
        .map(|meta| meta.file_type().is_fifo())
        .unwrap_or(false)
}
