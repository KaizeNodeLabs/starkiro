use core::byte_array::ByteArray;
use regex::regex::{Regex, RegexTrait};

fn main() {
    // Example 1: Creating a new regex and checking if text matches a pattern
    println!("== Example 1: new & matches ==");
    let email_pattern: ByteArray = "[a-z0-9]+@[a-z]+.[a-z]+";
    let mut regex = RegexTrait::new(email_pattern);
    
    let valid_email: ByteArray = "user@example.com";
    let invalid_email: ByteArray = "invalid-email";
    
    println!("Valid email: {}", valid_email);
    println!("Matches pattern? {}", regex.matches(valid_email));
    
    println!("Invalid email: {}", invalid_email);
    println!("Matches pattern? {}", regex.matches(invalid_email));

    // Example 2: Finding the first occurrence of a pattern
    println!("== Example 2: find ==");
    let text: ByteArray = "Contact us at support@company.com or sales@company.com";
    let mut email_regex: Regex = RegexTrait::new("[a-z]+@[a-z]+.[a-z]+");
    
    match email_regex.find(text) {
        Option::Some((start, end)) => {
            let mut email = "";
            let mut i = start;
            while i < end {
                email.append_byte(text.at(i).unwrap());
                i += 1;
            };
            println!("Found email: {}", email);
            println!("Position: {} to {}", start, end);
        },
        Option::None => {
            println!("No email found in text");
        }
    }

    // Example 3: Finding all occurrences of a pattern
    println!("== Example 3: find_all ==");
    let log_text: ByteArray = "2024-01-15 ERROR Database connection failed//2024-01-15 ERROR Authentication error//2024-01-15 INFO Retry successful";
    let mut error_regex: Regex = RegexTrait::new("ERROR.*");
    let matches = error_regex.find_all(log_text);
    
    println!("Found {} error messages:", matches.len());
    let mut i = 0;
    while i < matches.len() {
        let (start, end) = *matches.at(i);
        let mut error_msg = "";
        let mut j = start;
        while j < end {
            error_msg.append_byte(log_text.at(j).unwrap());
            j += 1;
        };
        println!("  {}: {}", i + 1, error_msg);
        i += 1;
    };

    // Example 4: Replacing patterns in text
    println!("== Example 4: replace ==");
    let sensitive_text: ByteArray = "My credit card is 1234-5678-9012-3456 and my SSN is 123-45-6789";
    
    // Replace credit card numbers
    let mut cc_regex: Regex = RegexTrait::new("[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}");
    let masked_cc = cc_regex.replace(sensitive_text, "XXXX-XXXX-XXXX-XXXX");
    println!("After masking credit card:");
    println!("{}", masked_cc);
    
    // Also replace SSN
    let mut ssn_regex: Regex = RegexTrait::new("[0-9]{3}-[0-9]{2}-[0-9]{4}");
    let fully_masked = ssn_regex.replace(masked_cc, "XXX-XX-XXXX");
    println!("After masking SSN:");
    println!("{}", fully_masked);

    // Example 5: Matching character classes
    println!("== Example 5: Character Classes ==");
    let mut digit_regex: Regex = RegexTrait::new("[0-9]+");
    let text_with_numbers: ByteArray = "abc123def456";
    
    let matches = digit_regex.find_all(text_with_numbers);
    println!("Found {} number sequences:", matches.len());
    
    let mut i = 0;
    while i < matches.len() {
        let (start, end) = *matches.at(i);
        let mut number = "";
        let mut j = start;
        while j < end {
            number.append_byte(text_with_numbers.at(j).unwrap());
            j += 1;
        };
        println!("  {}: {}", i + 1, number);
        i += 1;
    };

    // Example 6: Wildcards
    println!("== Example 6: Wildcards ==");
    let mut wildcard_regex: Regex = RegexTrait::new("c.t");
    let words: ByteArray = "cat cut cot cit";
    
    let matches = wildcard_regex.find_all(words);
    println!("Words matching 'c.t' pattern:");
    
    let mut i = 0;
    while i < matches.len() {
        let (start, end) = *matches.at(i);
        let mut word = "";
        let mut j = start;
        while j < end {
            word.append_byte(words.at(j).unwrap());
            j += 1;
        };
        println!("  {}", word);
        i += 1;
    };

    // Example 7: Quantifiers
    println!("== Example 7: Quantifiers ==");
    let text: ByteArray = "color colour flavor flavour";
    
    // Zero or one occurrence (American/British spelling)
    let mut color_regex: Regex = RegexTrait::new("colou?r");
    let matches = color_regex.find_all(text);
    
    println!("Words matching 'colou?r' (zero or one 'u'):");
    let mut i = 0;
    while i < matches.len() {
        let (start, end) = *matches.at(i);
        let mut word = "";
        let mut j = start;
        while j < end {
            word.append_byte(text.at(j).unwrap());
            j += 1;
        };
        println!("  {}", word);
        i += 1;
    };
    
    // One or more occurrences
    let mut letters_regex: Regex = RegexTrait::new("a+");
    let repeated_text: ByteArray = "a aa aaa aaaa";
    let matches = letters_regex.find_all(repeated_text);
    
    println!("Sequences matching 'a+' (one or more 'a'):");
    let mut i = 0;
    while i < matches.len() {
        let (start, end) = *matches.at(i);
        let mut sequence = "";
        let mut j = start;
        while j < end {
            sequence.append_byte(repeated_text.at(j).unwrap());
            j += 1;
        };
        println!("  {}: {} a's", i + 1, end - start);
        i += 1;
    };

    println!("== End of Examples ==");
}
