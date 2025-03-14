fn main() {
    // Example usage (optional)
    let input = "GEEKS-FOR-GEEKS";
    let encoded = encode(input);

    println!("Encoded: {}", encoded);
}

// Helper function to map ASCII characters (felt252) to Morse code (ByteArray)
fn get_morse_code(ch: u8) -> ByteArray {
    if ch == 32 {       // ' '
        " "
    } else if ch == 65 || ch == 97 { // 'A'
        ".-"
    } else if ch == 66 || ch == 98 { // 'B'
        "-..."
    } else if ch == 67 || ch == 99 { // 'C'
        "-.-."
    } else if ch == 68 || ch == 100 { // 'D'
        "-.."
    } else if ch == 69 || ch == 101 { // 'E'
        "."
    } else if ch == 70 || ch == 102 { // 'F'
        "..-."
    } else if ch == 71 || ch == 103 { // 'G'
        "--."
    } else if ch == 72 || ch == 104 { // 'H'
        "...."
    } else if ch == 73 || ch == 105 { // 'I'
        ".."
    } else if ch == 74 || ch == 106 { // 'J'
        ".---"
    } else if ch == 75 || ch == 107 { // 'K'
        "-.-"
    } else if ch == 76 || ch == 108 { // 'L'
        ".-.."
    } else if ch == 77 || ch == 109 { // 'M'
        "--"
    } else if ch == 78 || ch == 110 { // 'N'
        "-."
    } else if ch == 79 || ch == 111 { // 'O'
        "---"
    } else if ch == 80 || ch == 112 { // 'P'
        ".--."
    } else if ch == 81 || ch == 113 { // 'Q'
        "--.-"
    } else if ch == 82 || ch == 114 { // 'R'
        ".-."
    } else if ch == 83 || ch == 115 { // 'S'
        "..."
    } else if ch == 84 || ch == 116 { // 'T'
        "-"
    } else if ch == 85 || ch == 117 { // 'U'
        "..-"
    } else if ch == 86 || ch == 118 { // 'V'
        "...-"
    } else if ch == 87 || ch == 119 { // 'W'
        ".--"
    } else if ch == 88 || ch == 120 { // 'X'
        "-..-"
    } else if ch == 89 || ch == 121 { // 'Y'
        "-.--"
    } else if ch == 90 || ch == 122 { // 'Z'
        "--.."
    } else if ch == 48 { // '0'
        "-----"
    } else if ch == 49 { // '1'
        ".----"
    } else if ch == 50 { // '2'
        "..---"
    } else if ch == 51 { // '3'
        "...--"
    } else if ch == 52 { // '4'
        "....-"
    } else if ch == 53 { // '5'
        "....."
    } else if ch == 54 { // '6'
        "-..."
    } else if ch == 55 { // '7'
        "--..."
    } else if ch == 56 { // '8'
        "---.."
    } else if ch == 57 { // '9'
        "----."
    } else if ch == 44 { // ','
        "--..--"
    } else if ch == 46 { // '.'
        ".-.-.-"
    } else if ch == 63 { // '?'
        "..--.."
    } else if ch == 47 { // '/'
        "-..-."
    } else if ch == 45 { // '-'
        "-....-"
    } else if ch == 40 { // '('
        "-.--."
    } else if ch == 41 { // ')'
        "-.--.-"
    } else {             // Unknown characters
        ""
    }
}

// Encode text to Morse code, mimicking the Python logic
fn encode(text: ByteArray) -> ByteArray {
    let mut result: ByteArray = "";
    let text_len = text.len();
    let space = get_morse_code(32);

    for i in 0..text_len {
        let mut ch_byte = text.at(i).unwrap();
        if ch_byte == 32 { // ASCII 32 is space
            result.append(@space); // Extra space for word separation
        } else {
            let morse = get_morse_code(ch_byte);
            result.append(@morse); // Append Morse code
            result.append(@space);   // Space after Morse code
        }
    }
    result
}
