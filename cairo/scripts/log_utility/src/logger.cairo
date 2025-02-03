fn main() {
    log(LogLevel::Info, "This is the info message.");
    warning("Secret key about to be exposed!");
}

#[derive(Copy, Drop)]
enum LogLevel {
    Info,
    Warning,
    Error,
    Debug
}

fn log(log_level: LogLevel, message: ByteArray) {
    let mut log_message: ByteArray = match log_level {
        LogLevel::Info => "[INFO]: ",
        LogLevel::Warning => "[WARN]: ",
        LogLevel::Error => "[ERROR]: ",
        LogLevel::Debug => "[DEBUG]: ",
        _ => panic!("Err: Try using Info, Warning, Error, or Debug")
    };

    log_message.append(@message);
    println!("{}", log_message);
    
}

fn info(message: ByteArray) {
    log(LogLevel::Info, message);
}

fn warning(message: ByteArray) {
    log(LogLevel::Warning, message);
}

fn error(message: ByteArray) {
    log(LogLevel::Error, message);
}

fn debug(message: ByteArray) {
    log(LogLevel::Debug, message);
}