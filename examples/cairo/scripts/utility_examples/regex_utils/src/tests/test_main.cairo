#[cfg(test)]
mod test_main {
    use regex::regex::{Regex, RegexTrait};

    #[test]
    fn test_new_and_matches() {
        // Simple email-like pattern (simplified for this regex engine)
        let pattern: ByteArray = "[a-z]+@[a-z]+.[a-z]+";
        let mut regex: Regex = RegexTrait::new(pattern);

        // Valid email should match
        let valid_email: ByteArray = "user@example.com";
        assert!(regex.matches(valid_email.clone()), "Valid email should match pattern");

        // Invalid email should not match
        let invalid_email: ByteArray = "invalid-email";
        assert!(!regex.matches(invalid_email.clone()), "Invalid email should not match pattern");
    }

    #[test]
    fn test_find() {
        let text: ByteArray = "Contact us at support@company.com for help";
        let pattern: ByteArray = "[a-z]+@[a-z]+.[a-z]+";
        let mut regex = RegexTrait::new(pattern);

        // Should find the email in the text
        let result = regex.find(text.clone());
        assert!(result.is_some(), "Should find email in text");

        match result {
            Option::Some((start, end)) => {
                assert!(start == 14, "Email should start at position 14");
                assert!(end == 33, "Email should end at position 33");

                // Extract the matched part
                let mut matched_text = "";
                let mut i = start;
                while i < end {
                    matched_text.append_byte(text.at(i).unwrap());
                    i += 1;
                };
                assert!(matched_text == "support@company.com", "Should extract correct email");
            },
            Option::None => { 
                assert!(false, "Email not found but should be found"); 
            },
        }

        // Test with no match
        let no_email_text: ByteArray = "This text has no email addresses";
        assert!(regex.find(no_email_text.clone()).is_none(), "Should not find email in text without email");
    }

    #[test]
    fn test_find_all() {
        // Use simpler text that matches the basic pattern better
        let text: ByteArray = "user@site.com admin@site.org test@site.net";
        let pattern: ByteArray = "[a-z]+@[a-z]+.[a-z]+";
        let mut regex = RegexTrait::new(pattern);

        // Should find all three emails
        let matches = regex.find_all(text.clone());
        assert!(matches.len() == 3, "Should find 3 email addresses");

        // Check first match
        let (start1, end1) = *matches.at(0);
        let mut email1 = "";
        let mut i = start1;
        while i < end1 {
            email1.append_byte(text.at(i).unwrap());
            i += 1;
        };
        assert!(email1 == "user@site.com", "First email should be user@site.com");

        // Check second match
        let (start2, end2) = *matches.at(1);
        let mut email2 = "";
        let mut i = start2;
        while i < end2 {
            email2.append_byte(text.at(i).unwrap());
            i += 1;
        };
        assert!(email2 == "admin@site.org", "Second email should be admin@site.org");

        // Check third match
        let (start3, end3) = *matches.at(2);
        let mut email3 = "";
        let mut i = start3;
        while i < end3 {
            email3.append_byte(text.at(i).unwrap());
            i += 1;
        };
        assert!(email3 == "test@site.net", "Third email should be test@site.net");
    }

    #[test]
    fn test_replace() {
        let text: ByteArray = "Credit card: 1234-5678-9012-3456";
        // Use a simpler pattern without {4} repetition syntax
        let pattern: ByteArray = "[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]";
        let replacement: ByteArray = "XXXX-XXXX-XXXX-XXXX";
        let mut regex = RegexTrait::new(pattern);

        // Replace credit card number with masked version
        let result = regex.replace(text.clone(), replacement.clone());
        assert!(result == "Credit card: XXXX-XXXX-XXXX-XXXX", "Credit card should be masked");

        // Test multiple replacements
        let multi_text: ByteArray = "Cards: 1234-5678-9012-3456 and 9876-5432-1098-7654";
        let multi_result = regex.replace(multi_text.clone(), replacement.clone());
        assert!(
            multi_result == "Cards: XXXX-XXXX-XXXX-XXXX and XXXX-XXXX-XXXX-XXXX",
            "Both credit cards should be masked",
        );
    }

    #[test]
    fn test_character_classes() {
        // Test digit character class
        let digit_pattern: ByteArray = "[0-9]+";
        let mut digit_regex = RegexTrait::new(digit_pattern);

        let text: ByteArray = "abc123def456";
        let matches = digit_regex.find_all(text.clone());
        assert!(matches.len() == 2, "Should find 2 number sequences");

        // Check first match (123)
        let (start1, end1) = *matches.at(0);
        assert!(start1 == 3, "First number should start at position 3");
        assert!(end1 == 6, "First number should end at position 6");

        // Check second match (456)
        let (start2, end2) = *matches.at(1);
        assert!(start2 == 9, "Second number should start at position 9");
        assert!(end2 == 12, "Second number should end at position 12");

        // Test letter character class
        let letter_pattern: ByteArray = "[a-z]+";
        let mut letter_regex = RegexTrait::new(letter_pattern);

        let alpha_matches = letter_regex.find_all(text.clone());
        assert!(alpha_matches.len() == 2, "Should find 2 letter sequences");

        // Check first match (abc)
        let (alpha_start1, alpha_end1) = *alpha_matches.at(0);
        assert!(alpha_start1 == 0, "First letter sequence should start at position 0");
        assert!(alpha_end1 == 3, "First letter sequence should end at position 3");
    }

    #[test]
    fn test_wildcards() {
        let pattern: ByteArray = "c.t";
        let mut regex = RegexTrait::new(pattern);

        let text: ByteArray = "cat cut cot cit";
        let matches = regex.find_all(text.clone());
        assert!(matches.len() == 4, "Should match all 4 words");

        // Test specific text with wildcard
        let specific_text: ByteArray = "cat";
        assert!(regex.matches(specific_text.clone()), "cat should match c.t pattern");

        let non_matching: ByteArray = "car";
        assert!(!regex.matches(non_matching.clone()), "car should not match c.t pattern");
    }

    #[test]
    fn test_quantifiers() {
        // Test zero or one quantifier
        let optional_pattern: ByteArray = "colou?r";
        let mut optional_regex = RegexTrait::new(optional_pattern);

        let american: ByteArray = "color";
        let british: ByteArray = "colour";

        assert!(optional_regex.matches(american.clone()), "color should match colou?r");
        assert!(optional_regex.matches(british.clone()), "colour should match colou?r");

        // Test one or more quantifier
        let one_plus_pattern: ByteArray = "a+";
        let mut one_plus_regex = RegexTrait::new(one_plus_pattern);

        let text: ByteArray = "a aa aaa";
        let matches = one_plus_regex.find_all(text.clone());
        assert!(matches.len() == 3, "Should find 3 sequences of a's");

        // Check lengths of matches
        let (start1, end1) = *matches.at(0);
        let (start2, end2) = *matches.at(1);
        let (start3, end3) = *matches.at(2);

        assert!(end1 - start1 == 1, "First sequence should be 1 character");
        assert!(end2 - start2 == 2, "Second sequence should be 2 characters");
        assert!(end3 - start3 == 3, "Third sequence should be 3 characters");
    }
}
