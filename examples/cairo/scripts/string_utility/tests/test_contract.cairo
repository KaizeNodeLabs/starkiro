use string_utility::{StringTrait};

#[test]
fn test_new() {
    let string = StringTrait::new("");
    assert(string.len() == 0, 'new string should be empty');
}

#[test]
fn test_len() {
    // Test empty string
    let empty_string = StringTrait::new("");
    assert(empty_string.len() == 0, 'empty string length failed');

    // Test non-empty string
    let string = StringTrait::new("Hello");
    assert(string.len() == 5, 'basic length failed');

    // Test string with spaces
    let string_with_spaces = StringTrait::new("Hello World");
    assert(string_with_spaces.len() == 11, 'string with spaces len failed');
}

#[test]
fn test_concatenate() {
    // Test basic concatenation
    let mut str1 = StringTrait::new("Hello");
    let str2 = StringTrait::new(" World");
    str1.concatenate(@str2);
    assert(str1.data == "Hello World", 'basic concat failed');

    // Test concatenating with empty string
    let mut str3 = StringTrait::new("Hello");
    let empty = StringTrait::new("");
    str3.concatenate(@empty);
    assert(str3.data == "Hello", 'concat with empty failed');

    // Test concatenating to empty string
    let mut empty = StringTrait::new("");
    let str4 = StringTrait::new("Hello");
    empty.concatenate(@str4);
    assert(empty.data == "Hello", 'empty concat failed');
}

#[test]
fn test_starts_with() {
    let string = StringTrait::new("Hello World");

    // Test basic prefix
    let prefix1 = StringTrait::new("Hello");
    assert(string.starts_with(@prefix1), 'basic prefix failed');

    // Test full string as prefix
    let prefix2 = StringTrait::new("Hello World");
    assert(string.starts_with(@prefix2), 'full string prefix failed');

    // Test empty prefix
    let empty = StringTrait::new("");
    assert(string.starts_with(@empty), 'empty prefix failed');

    // Test non-matching prefix
    let prefix3 = StringTrait::new("World");
    assert(!string.starts_with(@prefix3), 'non-matching prefix failed');

    // Test prefix longer than string
    let prefix4 = StringTrait::new("Hello World!");
    assert(!string.starts_with(@prefix4), 'long prefix failed');
}

#[test]
fn test_ends_with() {
    let string = StringTrait::new("Hello World");

    // Test basic suffix
    let suffix1 = StringTrait::new("World");
    assert(string.ends_with(@suffix1), 'basic suffix failed');

    // Test full string as suffix
    let suffix2 = StringTrait::new("Hello World");
    assert(string.ends_with(@suffix2), 'full string suffix failed');

    // Test empty suffix
    let empty = StringTrait::new("");
    assert(string.ends_with(@empty), 'empty suffix failed');

    // Test non-matching suffix
    let suffix3 = StringTrait::new("Hello");
    assert(!string.ends_with(@suffix3), 'non-matching suffix failed');

    // Test suffix longer than string
    let suffix4 = StringTrait::new("Hello World!");
    assert(!string.ends_with(@suffix4), 'long suffix failed');
}

#[test]
fn test_greeting_concatenation() {
    let mut greeting = StringTrait::new("Hello");
    let name = StringTrait::new(" Alice");
    greeting.concatenate(@name);
    assert(greeting.data == "Hello Alice", 'greeting creation failed');
}

#[test]
fn test_email_domain_validation() {
    let email = StringTrait::new("user@example.com");
    let domain = StringTrait::new(".com");
    assert(email.ends_with(@domain), 'email domain validation failed');
}

#[test]
fn test_url_protocol_validation() {
    let url = StringTrait::new("https://example.com");
    let protocol = StringTrait::new("https://");
    assert(url.starts_with(@protocol), 'url protocol validation failed');
}

#[test]
fn test_multiple_string_manipulation() {
    let mut text = StringTrait::new("");

    let part1 = StringTrait::new("Hello");
    text.concatenate(@part1);
    assert(text.data == "Hello", 'first append failed');

    let part2 = StringTrait::new(" World");
    text.concatenate(@part2);
    assert(text.len() == 11, 'final length incorrect');
    assert(text.data == "Hello World", 'final content incorrect');
}
