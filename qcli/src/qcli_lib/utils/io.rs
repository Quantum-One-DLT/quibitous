use serde::de::DeserializeOwned;
use std::{
    io::{stdin, stdout, BufRead, BufReader, Error, Write},
    path::{Path, PathBuf},
};
use thiserror::Error;

/// open the given file path as a writable stream, or stdout if no path
/// provided
pub fn open_file_write<P: AsRef<Path>>(path: &Option<P>) -> Result<impl Write, Error> {
    match path {
        Some(path) => {
            let writer = std::fs::OpenOptions::new()
                .create(true)
                .write(true)
                .read(false)
                .append(false)
                .truncate(true)
                .open(path)?;
            Ok(Box::new(writer) as Box<dyn Write>)
        }
        None => Ok(Box::new(stdout()) as Box<dyn Write>),
    }
}

/// open the given file path as a readable stream, or stdin if no path
/// provided
pub fn open_file_read<P: AsRef<Path>>(path: &Option<P>) -> Result<impl BufRead, Error> {
    match path {
        Some(path) => {
            let reader = std::fs::OpenOptions::new()
                .create(false)
                .write(false)
                .read(true)
                .append(false)
                .open(path)?;
            Ok(Box::new(BufReader::new(reader)) as Box<dyn BufRead>)
        }
        None => Ok(Box::new(BufReader::new(stdin())) as Box<dyn BufRead>),
    }
}

pub fn path_to_path_buf<P: AsRef<Path>>(path: &Option<P>) -> PathBuf {
    path.as_ref()
        .map(|path| path.as_ref().to_path_buf())
        .unwrap_or_default()
}

pub fn read_line<P: AsRef<Path>>(path: &Option<P>) -> Result<String, Error> {
    let mut line = String::new();
    open_file_read(path)?.read_line(&mut line)?;
    Ok(line.trim_end().to_string())
}

#[derive(Debug, Error)]
pub enum ReadYamlError {
    #[error("could not read input")]
    Io(#[from] Error),
    #[error("input contains malformed yaml")]
    Yaml(#[from] serde_yaml::Error),
}

pub fn read_yaml<D: DeserializeOwned>(path: &Option<impl AsRef<Path>>) -> Result<D, ReadYamlError> {
    let reader = open_file_read(path)?;
    let yaml = serde_yaml::from_reader(reader)?;
    Ok(yaml)
}

pub fn ask_yes_or_no(with_output: bool) -> std::io::Result<bool> {
    if with_output {
        print!("Continue? Yes[y] or No[n]? ");
        std::io::stdout().flush()?;
    }
    let mut buff = String::new();
    std::io::stdin().read_line(&mut buff)?;
    Ok(matches!(buff.to_ascii_lowercase().trim_end(), "yes" | "y"))
}
