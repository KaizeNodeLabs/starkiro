use string_utility::string_utility::{StringTrait};
use core::byte_array::ByteArray;

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

#[test]
fn test_to_lowercase() {
    // Test basic uppercase to lowercase
    let string1 = StringTrait::new("HELLO");
    let result1 = string1.to_lowercase();
    assert(result1.data == "hello", 'basic lowercase failed');

    // Test mixed case
    let string2 = StringTrait::new("HeLLo WoRLD");
    let result2 = string2.to_lowercase();
    assert(result2.data == "hello world", 'mixed case failed');

    // Test already lowercase
    let string3 = StringTrait::new("hello");
    let result3 = string3.to_lowercase();
    assert(result3.data == "hello", 'already lowercase failed');

    // Test with numbers and symbols
    let string4 = StringTrait::new("HELLO123!@#");
    let result4 = string4.to_lowercase();
    assert(result4.data == "hello123!@#", 'special chars failed');

    // Test empty string
    let empty = StringTrait::new("");
    let result5 = empty.to_lowercase();
    assert(result5.data == "", 'empty string failed');
}

#[test]
fn test_to_uppercase() {
    // Test basic lowercase to uppercase
    let string1 = StringTrait::new("hello");
    let result1 = string1.to_uppercase();
    assert(result1.data == "HELLO", 'basic uppercase failed');

    // Test mixed case
    let string2 = StringTrait::new("HeLLo WoRLD");
    let result2 = string2.to_uppercase();
    assert(result2.data == "HELLO WORLD", 'mixed case failed');

    // Test already uppercase
    let string3 = StringTrait::new("HELLO");
    let result3 = string3.to_uppercase();
    assert(result3.data == "HELLO", 'already uppercase failed');

    // Test with numbers and symbols
    let string4 = StringTrait::new("hello123!@#");
    let result4 = string4.to_uppercase();
    assert(result4.data == "HELLO123!@#", 'special chars failed');

    // Test empty string
    let empty = StringTrait::new("");
    let result5 = empty.to_uppercase();
    assert(result5.data == "", 'empty string failed');
}

#[test]
fn test_trim() {
    // Test basic space trimming
    let string1 = StringTrait::new("  hello  ");
    let result1 = string1.trim();
    assert(result1.data == "hello", 'basic trim failed');

    // Test with tabs and newlines
    let string2 = StringTrait::new("\t\n hello world \r\n");
    let result2 = string2.trim();
    assert(result2.data == "hello world", 'mixed whitespace failed');

    // Test with no trim needed
    let string3 = StringTrait::new("hello");
    let result3 = string3.trim();
    assert(result3.data == "hello", 'no trim needed failed');

    // Test with internal spaces
    let string4 = StringTrait::new("   hello   world   ");
    let result4 = string4.trim();
    assert(result4.data == "hello   world", 'internal spaces failed');

    // Test all whitespace string
    let string5 = StringTrait::new("   \t\n\r   ");
    let result5 = string5.trim();
    assert(result5.data == "", 'all whitespace failed');

    // Test empty string
    let empty = StringTrait::new("");
    let result6 = empty.trim();
    assert(result6.data == "", 'empty string failed');
}

#[test]
fn test_substring() {
    let test_string = StringTrait::new("Hello World");

    // Test basic substring
    let result1 = test_string.substring(6, 11);
    assert(result1.data == "World", 'basic substring failed');

    // Test from start
    let result2 = test_string.substring(0, 5);
    assert(result2.data == "Hello", 'start substring failed');

    // Test single character
    let result3 = test_string.substring(0, 1);
    assert(result3.data == "H", 'single char failed');

    // Test invalid start index
    let result4 = test_string.substring(12, 15);
    assert(result4.data == "", 'invalid start failed');

    // Test invalid end index
    let result5 = test_string.substring(0, 15);
    assert(result5.data == "", 'invalid end failed');

    // Test start >= end
    let result6 = test_string.substring(5, 2);
    assert(result6.data == "", 'invalid range failed');

    // Test empty string
    let empty = StringTrait::new("");
    let result7 = empty.substring(0, 1);
    assert(result7.data == "", 'empty string failed');

    // Test middle substring
    let result8 = test_string.substring(3, 8);
    assert(result8.data == "lo Wo", 'middle substring failed');
}

#[test]
fn test_generic_replace() {
    let sentence = StringTrait::new("This is an old banana.");

    // Test with both String arguments
    let target = StringTrait::new("old");
    let replacement = StringTrait::new("amazing");
    let result1 = sentence.replace(target, replacement);
    assert(result1.data == "This is an amazing banana.", 'str-str replace failed');

    // Test with ByteArray and String
    let target: ByteArray = "old";
    let replacement = StringTrait::new("amazing");
    let result2 = sentence.replace(target, replacement);
    assert(result2.data == "This is an amazing banana.", 'bytes-str replace failed');

    // Test with String and ByteArray
    let target = StringTrait::new("old");
    let replacement: ByteArray = "amazing";
    let result3 = sentence.replace(target, replacement);
    assert(result3.data == "This is an amazing banana.", 'str-bytes replace failed');

    // Test with both ByteArray arguments
    let target: ByteArray = "old";
    let replacement: ByteArray = "amazing";
    let result4 = sentence.replace(target, replacement);
    assert(result4.data == "This is an amazing banana.", 'bytes-bytes replace failed');
}

#[test]
fn test_generic_contains() {
    let sentence = StringTrait::new("This is an old banana.");

    // Test with String pattern
    let pattern = StringTrait::new("old");
    assert(sentence.contains(pattern), 'str contains failed');

    // Test with ByteArray pattern
    let pattern: ByteArray = "old";
    assert(sentence.contains(pattern), 'bytes contains failed');

    // Test non-matching String pattern
    let non_match = StringTrait::new("new");
    assert(!sentence.contains(non_match), 'str non-match failed');

    // Test non-matching ByteArray pattern
    let non_match: ByteArray = "new";
    assert(!sentence.contains(non_match), 'bytes non-match failed');
}

#[test]
fn test_generic_edge_cases() {
    let sentence = StringTrait::new("Hello World");
    let empty_str = StringTrait::new("");
    let empty: ByteArray = "";

    // Empty string and pattern combination
    assert(empty_str.contains(empty), 'empty-empty failed');

    // Replace with empty string/pattern
    let empty_str = StringTrait::new("");
    let empty: ByteArray = "";
    let result1 = sentence.replace(empty_str, empty);
    assert(result1.data == sentence.data, 'empty replace failed');

    // Replace with longer/shorter replacements
    let target: ByteArray = "o";
    let replacement: ByteArray = "oo";
    let result2 = sentence.replace(target, replacement);
    assert(result2.data == "Helloo Woorld", 'longer replace failed');

    // Case sensitivity
    let word: ByteArray = "hello";
    let word_str = StringTrait::new("hello");
    assert(!sentence.contains(word), 'case sensitivity bytes failed');
    assert(!sentence.contains(word_str), 'case sensitivity str failed');
}
