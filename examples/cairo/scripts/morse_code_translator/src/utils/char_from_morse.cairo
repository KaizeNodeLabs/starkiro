// Helper function to map Morse code (ByteArray) to Characters (ByteArray)
pub fn get_char_from_morse(ch: ByteArray) -> ByteArray {
    if ch == " " {       // Space remains a space.
        " "
    } else if ch == ".-" { // 'A'
        "A"
    } else if ch == "-..." { // 'B'
        "B"
    } else if ch == "-.-." { // 'C'
        "C"
    } else if ch == "-.." { // 'D'
        "D"
    } else if ch == "." { // 'E'
        "E"
    } else if ch == "..-." { // 'F'
        "F"
    } else if ch == "--." { // 'G'
        "G"
    } else if ch == "...." { // 'H'
        "H"
    } else if ch == ".." { // 'I'
        "I"
    } else if ch == ".---" { // 'J'
        "J"
    } else if ch == "-.-" { // 'K'
        "K"
    } else if ch == ".-.." { // 'L'
        "L"
    } else if ch == "--" { // 'M'
        "M"
    } else if ch == "-." { // 'N'
        "N"
    } else if ch == "---" { // 'O'
        "O"
    } else if ch == ".--." { // 'P'
        "P"
    } else if ch == "--.-" { // 'Q'
        "Q"
    } else if ch == ".-." { // 'R'
        "R"
    } else if ch == "..." { // 'S'
        "S"
    } else if ch == "-" { // 'T'
        "T"
    } else if ch == "..-" { // 'U'
        "U"
    } else if ch == "...-" { // 'V'
        "V"
    } else if ch == ".--" { // 'W'
        "W"
    } else if ch == "-..-" { // 'X'
        "X"
    } else if ch == "-.--" { // 'Y'
        "Y"
    } else if ch == "--.." { // 'Z'
        "Z"
    } else if ch == "-----" { // '0'
        "0"
    } else if ch == ".----" { // '1'
        "1"
    } else if ch == "..---" { // '2'
        "2"
    } else if ch == "...--" { // '3'
        "3"
    } else if ch == "....-" { // '4'
        "4"
    } else if ch == "....." { // '5'
        "5"
    } else if ch == "-...." { // '6'
        "6"
    } else if ch == "--..." { // '7'
        "7"
    } else if ch == "---.." { // '8'
        "8"
    } else if ch == "----." { // '9'
        "9"
    } else if ch == "--..--" { // ',' (comma)
        ","
    } else if ch == ".-.-.-" { // '.' (period)
        "."
    } else if ch == "..--.." { // '?' (question mark)
        "?"
    } else if ch == "-..-." { // '/' (slash)
        "/"
    } else if ch == "-....-" { // '-' (dash)
        "-"
    } else if ch == "-.--." { // '(' (open parenthesis)
        "("
    } else if ch == "-.--.-" { // ')' (close parenthesis)
        ")"
    } else {             // Unknown characters
        ""
    }
}
