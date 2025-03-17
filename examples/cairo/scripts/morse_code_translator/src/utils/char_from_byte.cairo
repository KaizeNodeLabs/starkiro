// Helper function to map ASCII numbers (u8) to characters (ByteArray)
pub fn get_char_from_byte(ch: u8) -> ByteArray {
    if ch == 32 {       // ' '
        " "
    } else if ch == 46 { // '.'
        "."
    } else if ch == 45 { // '-'
        "-"
    } else {             // Unknown characters
        ""
    }
}
