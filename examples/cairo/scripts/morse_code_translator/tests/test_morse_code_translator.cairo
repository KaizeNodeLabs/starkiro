use morse_code_translator::morse_code_translator::{ encode, decode };

/// Encoding Tests

#[test]
fn test_text_to_morse() {
    let text: ByteArray = "GRACE ANDREW AJOGI";

    let encoded = encode(text);

    assert(encoded == "--. .-. .- -.-. .  .- -. -.. .-. . .--  .- .--- --- --. ..", 'encoding not correct');
}

#[test]
fn test_lowercase_text_to_morse() {
    let text: ByteArray = "grace andrew ajogi";

    let encoded = encode(text);

    assert(encoded == "--. .-. .- -.-. .  .- -. -.. .-. . .--  .- .--- --- --. ..", 'encoding not correct');
}

#[test]
fn test_mixcase_text_to_morse() {
    let text: ByteArray = "GraCe AnDREw ajOgI";

    let encoded = encode(text);

    assert(encoded == "--. .-. .- -.-. .  .- -. -.. .-. . .--  .- .--- --- --. ..", 'encoding not correct');
}

fn test_empty_text_to_morse() {
    let text: ByteArray = "";

    let encoded = encode(text);

    assert(encoded == "", 'encoding not correct');
}

/// Decoding Tests

#[test]
fn test_morse_to_text() {
    let morse: ByteArray = "--. .. -.. . --- -.  -... .- - ..- .-. .";

    let decoded = decode(morse);

    assert(decoded == "GIDEON BATURE", 'decoding not correct');
}

#[test]
fn test_empty_morse_to_text() {
    let morse: ByteArray = "";

    let decoded = decode(morse);

    assert(decoded == "", 'decoding not correct');
}
