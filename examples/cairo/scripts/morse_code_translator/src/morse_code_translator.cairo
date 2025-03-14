// use core::to_byte_array::FormatAsByteArray;
// use core::dict::Felt252Dict;
// use core::iter::Iterator;

// fn main() {

// }

// // Create a mapping from characters to morse code
// fn create_char_to_morse() -> Felt252Dict<felt252> {
//     let mut map: Felt252Dict<felt252> = Default::default();

//     map.insert('A', '.-');
//     map.insert('B', '-...');
//     map.insert('C', '-.-.');
//     map.insert('D', '-..');
//     map.insert('E', '.');
//     map.insert('F', '..-.');
//     map.insert('G', '--.');
//     map.insert('H', '....');
//     map.insert('I', '..');
//     map.insert('J', '.---');
//     map.insert('K', '-.-');
//     map.insert('L', '.-..');
//     map.insert('M', '--');
//     map.insert('N', '-.');
//     map.insert('O', '---');
//     map.insert('P', '.--.');
//     map.insert('Q', '--.-');
//     map.insert('R', '.-.');
//     map.insert('S', '...');
//     map.insert('T', '-');
//     map.insert('U', '..-');
//     map.insert('V', '...-');
//     map.insert('W', '.--');
//     map.insert('X', '-..-');
//     map.insert('Y', '-.--');
//     map.insert('Z', '--..');
//     map.insert('1', '.----');
//     map.insert('2', '..---');
//     map.insert('3', '...--');
//     map.insert('4', '....-');
//     map.insert('5', '.....');
//     map.insert('6', '-....');
//     map.insert('7', '--...');
//     map.insert('8', '---..');
//     map.insert('9', '----.');
//     map.insert('0', '-----');
//     map.insert(',', '--..--');
//     map.insert('.', '.-.-.-');
//     map.insert('?', '..--..');
//     map.insert('/', '-..-.');
//     map.insert('-', '-....-');
//     map.insert('(', '-.--.');
//     map.insert(')', '-.--.-');
//     map
// }



// // Create a reverse mapping from morse code to characters
// fn create_morse_to_char() -> Felt252Dict<felt252> {

//     let mut map: Felt252Dict<felt252> = Default::default();

//     map.insert('.-', 'A');
//     map.insert('-...', 'B');
//     map.insert('-.-.', 'C', );
//     map.insert('-..', 'D');
//     map.insert('.', 'E');
//     map.insert('..-.', 'F');
//     map.insert('--.', 'G');
//     map.insert('....', 'H');
//     map.insert('..', 'I');
//     map.insert('.---', 'J');
//     map.insert('-.-', 'K');
//     map.insert('.-..', 'L');
//     map.insert('--', 'M');
//     map.insert('-.', 'N');
//     map.insert('---', 'O');
//     map.insert('.--.', 'P');
//     map.insert('--.-', 'Q');
//     map.insert('.-.', 'R');
//     map.insert('...', 'S');
//     map.insert('-', 'T');
//     map.insert('..-', 'U');
//     map.insert('...-', 'V');
//     map.insert('.--', 'W');
//     map.insert('-..-', 'X');
//     map.insert('-.--', 'Y');
//     map.insert('--..', 'Z');
//     map.insert('.----', '1');
//     map.insert('..---', '2');
//     map.insert('...--', '3');
//     map.insert('....-', '4');
//     map.insert('.....', '5');
//     map.insert('-....', '6');
//     map.insert('--...', '7');
//     map.insert('---..', '8');
//     map.insert('----.', '9');
//     map.insert('-----', '0');
//     map.insert('--..--', ',');
//     map.insert('.-.-.-', '.');
//     map.insert('..--..', '?');
//     map.insert('-..-.', '/');
//     map.insert('-....-', '-');
//     map.insert('-.--.', '(');
//     map.insert('-.--.-', ')');
//     map
// }

// fn ascii_code_to_char() -> Felt252Dict<felt252> {
//     let mut map: Felt252Dict<felt252> = Default::default();

//     // Uppercase Letters: 'A' (65) to 'Z' (90)
//     map.insert('65', 'A');
//     map.insert('66', 'B');
//     map.insert('67', 'C');
//     map.insert('68', 'D');
//     map.insert('69', 'E');
//     map.insert('70', 'F');
//     map.insert('71', 'G');
//     map.insert('72', 'H');
//     map.insert('73', 'I');
//     map.insert('74', 'J');
//     map.insert('75', 'K');
//     map.insert('76', 'L');
//     map.insert('77', 'M');
//     map.insert('78', 'N');
//     map.insert('79', 'O');
//     map.insert('80', 'P');
//     map.insert('81', 'Q');
//     map.insert('82', 'R');
//     map.insert('83', 'S');
//     map.insert('84', 'T');
//     map.insert('85', 'U');
//     map.insert('86', 'V');
//     map.insert('87', 'W');
//     map.insert('88', 'X');
//     map.insert('89', 'Y');
//     map.insert('90', 'Z');

//     // Digits: '0' (48) to '9' (57)
//     map.insert('48', '0');
//     map.insert('49', '1');
//     map.insert('50', '2');
//     map.insert('51', '3');
//     map.insert('52', '4');
//     map.insert('53', '5');
//     map.insert('54', '6');
//     map.insert('55', '7');
//     map.insert('56', '8');
//     map.insert('57', '9');

//     // Punctuation Marks
//     map.insert('44', ',');  // Comma
//     map.insert('46', '.');  // Period
//     map.insert('63', '?');  // Question mark
//     map.insert('47', '/');  // Slash
//     map.insert('45', '-');  // Hyphen
//     map.insert('40', '(');  // Left parenthesis
//     map.insert('41', ')');  // Right parenthesis

//     map
// }

// // Encode text to Morse code
// fn encode(text: @ByteArray) -> Array<felt252> {
//     let mut char_to_morse = create_char_to_morse();
//     let mut converter = ascii_code_to_char();
//     let mut arr = array![];
    
//     let text_len = text.len();

//     for i in 0..text_len {
//         let mut ch_byte = text.at(i).unwrap();
//         let mut ch: felt252 = ch_byte.into();

//         let mut key = converter.get(ch);
//         let code = char_to_morse.get(key);
        
//         arr.append(code);
//     }
//     arr
// }