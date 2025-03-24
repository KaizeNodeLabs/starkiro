use core::fmt::{Error, Formatter};

/// Equivalent to `{:02}` formatting for n < 100.
pub(crate) fn write_hundreds(ref f: Formatter, n: u8) -> Result<(), Error> {
    if n >= 100 {
        return Result::Err(Error {});
    }

    f.buffer.append_byte('0' + n / 10);
    f.buffer.append_byte('0' + n % 10);
    Result::Ok(())
}
