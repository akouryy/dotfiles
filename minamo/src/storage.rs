use std::fs::{DirBuilder, File, OpenOptions};
use std::hash::{BuildHasher, RandomState};
use std::io;
use std::os::unix::fs::{DirBuilderExt, OpenOptionsExt};
use std::path::{Path, PathBuf};

const MAX_ATTEMPTS: usize = 100;

pub fn create(prog_name: &str) -> io::Result<(PathBuf, File)> {
    let dir = Path::new("/tmp/minamo");
    DirBuilder::new().recursive(true).mode(0o700).create(dir)?;
    std::iter::repeat_with(|| open_once(dir, prog_name))
        .take(MAX_ATTEMPTS)
        .find(|result| !matches!(result, Err(err) if err.kind() == io::ErrorKind::AlreadyExists))
        .unwrap_or_else(|| Err(io::ErrorKind::AlreadyExists.into()))
}

fn open_once(dir: &Path, prog_name: &str) -> io::Result<(PathBuf, File)> {
    let suffix = &format!("{:016x}", RandomState::new().hash_one(0u64))[..6];
    let path = dir.join(format!("{prog_name}-{suffix}.txt"));
    let file = OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(0o600)
        .open(&path)?;
    Ok((path, file))
}

pub fn human_size(bytes: u64) -> String {
    const UNITS: [&str; 6] = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"];
    let mut value = bytes as f64;
    let mut unit = 0;
    while value >= 1023.5 && unit < UNITS.len() - 1 {
        value /= 1024.0;
        unit += 1;
    }
    if value.fract() == 0.0 || value >= 99.95 {
        format!("{value:.0} {}", UNITS[unit])
    } else {
        format!("{value:.1} {}", UNITS[unit])
    }
}
