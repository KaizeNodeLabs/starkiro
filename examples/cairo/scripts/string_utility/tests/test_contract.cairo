use string_utility::{String, StringTrait};

#[test]
fn test_new() {
    let string = StringTrait::new();
    assert(string.len() == 0, 'new string should be empty');
}

#[test]
fn test_len() {
    // Test empty string
    let empty_string = StringTrait::new();
    assert(empty_string.len() == 0, 'empty string length failed');

    // Test non-empty string
    let data: ByteArray = "Hello";
    let string = String { data };
    assert(string.len() == 5, 'basic length failed');

    // Test string with spaces
    let data: ByteArray = "Hello World";
    let string_with_spaces = String { data };
    assert(string_with_spaces.len() == 11, 'string with spaces len failed');
}

#[test]
fn test_concatenate() {
    // Test basic concatenation
    let data: ByteArray = "Hello";
    let mut str1 = String { data };
    let data: ByteArray = " World";
    let str2 = String { data };
    str1.concatenate(@str2);
    assert(str1.data == "Hello World", 'basic concat failed');

    // Test concatenating with empty string
    let data: ByteArray = "Hello";
    let mut str3 = String { data };
    let empty = StringTrait::new();
    str3.concatenate(@empty);
    assert(str3.data == "Hello", 'concat with empty failed');

    // Test concatenating to empty string
    let mut empty = StringTrait::new();
    let data: ByteArray = "Hello";
    let str4 = String { data };
    empty.concatenate(@str4);
    assert(empty.data == "Hello", 'empty concat failed');
}

#[test]
fn test_starts_with() {
    let data: ByteArray = "Hello World";
    let string = String { data };

    // Test basic prefix
    let data: ByteArray = "Hello";
    let prefix1 = String { data };
    assert(string.starts_with(@prefix1), 'basic prefix failed');

    // Test full string as prefix
    let data: ByteArray = "Hello World";
    let prefix2 = String { data };
    assert(string.starts_with(@prefix2), 'full string prefix failed');

    // Test empty prefix
    let empty = StringTrait::new();
    assert(string.starts_with(@empty), 'empty prefix failed');

    // Test non-matching prefix
    let data: ByteArray = "World";
    let prefix3 = String { data };
    assert(!string.starts_with(@prefix3), 'non-matching prefix failed');

    // Test prefix longer than string
    let data: ByteArray = "Hello World!";
    let prefix4 = String { data };
    assert(!string.starts_with(@prefix4), 'long prefix failed');
}

#[test]
fn test_ends_with() {
    let data: ByteArray = "Hello World";
    let string = String { data };

    // Test basic suffix
    let data: ByteArray = "World";
    let suffix1 = String { data };
    assert(string.ends_with(@suffix1), 'basic suffix failed');

    // Test full string as suffix
    let data: ByteArray = "Hello World";
    let suffix2 = String { data };
    assert(string.ends_with(@suffix2), 'full string suffix failed');

    // Test empty suffix
    let empty = StringTrait::new();
    assert(string.ends_with(@empty), 'empty suffix failed');

    // Test non-matching suffix
    let data: ByteArray = "Hello";
    let suffix3 = String { data };
    assert(!string.ends_with(@suffix3), 'non-matching suffix failed');

    // Test suffix longer than string
    let data: ByteArray = "Hello World!";
    let suffix4 = String { data };
    assert(!string.ends_with(@suffix4), 'long suffix failed');
}

#[test]
fn test_greeting_concatenation() {
    let data: ByteArray = "Hello";
    let mut greeting = String { data };
    let data: ByteArray = " Alice";
    let name = String { data };
    greeting.concatenate(@name);
    assert(greeting.data == "Hello Alice", 'greeting creation failed');
}

#[test]
fn test_email_domain_validation() {
    let data: ByteArray = "user@example.com";
    let email = String { data };
    let data: ByteArray = ".com";
    let domain = String { data };
    assert(email.ends_with(@domain), 'email domain validation failed');
}

#[test]
fn test_url_protocol_validation() {
    let data: ByteArray = "https://example.com";
    let url = String { data };
    let data: ByteArray = "https://";
    let protocol = String { data };
    assert(url.starts_with(@protocol), 'url protocol validation failed');
}

#[test]
fn test_multiple_string_manipulation() {
    let mut text = StringTrait::new();

    let data: ByteArray = "Hello";
    let part1 = String { data };
    text.concatenate(@part1);
    assert(text.data == "Hello", 'first append failed');

    let data: ByteArray = " World";
    let part2 = String { data };
    text.concatenate(@part2);
    assert(text.len() == 11, 'final length incorrect');
    assert(text.data == "Hello World", 'final content incorrect');
}
