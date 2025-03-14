use crate::utils::{ byte_to_morse, char_from_byte, char_from_morse };

// Encode text to Morse code
pub fn encode(text: ByteArray) -> ByteArray {
    let mut result: ByteArray = "";
    let text_len = text.len();
    let space = byte_to_morse::get_morse_code(32);

    for i in 0..text_len {
        let mut ch_byte = text.at(i).unwrap();
        if ch_byte == 32 { // ASCII 32 is space
            result.append(@space); // Extra space for word separation
        } else {
            let morse = byte_to_morse::get_morse_code(ch_byte);
            result.append(@morse); // Append Morse code

            if i != text_len - 1 {
                result.append(@space);   // Space after Morse code
            }
        }
    }
    result
}

// Encode text to Morse code
pub fn decode(morse_text: ByteArray) -> ByteArray {
    let mut result: ByteArray = "";
    let mut current_symbol: ByteArray = "";
    let text_len = morse_text.len();
    let space: ByteArray = " ";

    for i in 0..text_len {
        let mut ch_byte = morse_text.at(i).unwrap();
        
        if ch_byte != 32 { // ASCII 32 is space
            let ch = char_from_byte::get_char_from_byte(ch_byte);
            current_symbol.append(@ch);
        } else {

            let mut next_ch_byte = morse_text.at(i + 1).unwrap();

            
            let morse = char_from_morse::get_char_from_morse(current_symbol);
            result.append(@morse);
            current_symbol = "";

            if next_ch_byte == 32 {
                result.append(@space);
            }
        }
    }
    let morse = char_from_morse::get_char_from_morse(current_symbol);
    result.append(@morse);
    result
}

fn main() {
    // Example usage (optional)
    let input = "Gideon Bature";
    let encoded = encode(input);

    println!("Encoded: {}", encoded);

    let input1 = "--. .-. .- -.-. .  .- -. -.. .-. . .--  .- .--- --- --. ..";
    let decoded = decode(input1);
    println!("Decoded: {}", decoded);
}