// Import StringTrait and StringCompatible from the string_utility library
use string_utility::{StringTrait, StringCompatible};

fn main() {
    // Initialize an empty string using the StringTrait constructor
    let mut text = StringTrait::new("");

    // Create the first string segment with "Hello"
    let mut part1 = StringTrait::new("Hello");
    // Convert the first segment to uppercase
    part1 = part1.to_uppercase();

    // Create the second string segment with additional whitespace
    let mut part2 = StringTrait::new("   World   ");
    // Trim the extra whitespace from the second segment
    part2 = part2.trim();

    // Append both segments together in the final string
    text.concatenate(@part1);
    text.concatenate(@part2);

    // Convert the final string to a ByteArray type and print the result
    println!("{}", text.to_bytes());
}
