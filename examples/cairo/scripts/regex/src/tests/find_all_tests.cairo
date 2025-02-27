#[cfg(test)]
mod find_all_tests {
    use regex::regex::{RegexTrait};

    #[test]
    fn test_find_all_literal() {
        // Simple literal pattern
        let pattern_str: ByteArray = "cat";
        let mut regex = RegexTrait::new(pattern_str);

        // Find multiple occurrences
        let input: ByteArray = "cat dog cat fish cat";
        let results = regex.find_all(input);

        assert!(results.len() == 3, "Should find 3 occurrences of 'cat'");

        // Check first match
        let (start1, end1) = *results.at(0);
        assert!(start1 == 0, "First match should start at position 0");
        assert!(end1 == 3, "First match should end at position 3");

        // Check second match
        let (start2, end2) = *results.at(1);
        assert!(start2 == 8, "Second match should start at position 8");
        assert!(end2 == 11, "Second match should end at position 11");

        // Check third match
        let (start3, end3) = *results.at(2);
        assert!(start3 == 17, "Third match should start at position 17");
        assert!(end3 == 20, "Third match should end at position 20");
    }

    #[test]
    fn test_find_all_with_wildcard() {
        // Pattern with wildcard
        let pattern_str: ByteArray = "c.t";
        let mut regex = RegexTrait::new(pattern_str);

        // Find various matches
        let input: ByteArray = "cat cut cot c@t";
        let results = regex.find_all(input);

        assert!(results.len() == 4, "Should find 4 matches of 'c.t'");

        // Check all matches
        let (start1, end1) = *results.at(0);
        assert!(start1 == 0, "First match should start at position 0");
        assert!(end1 == 3, "First match should end at position 3");

        let (start2, end2) = *results.at(1);
        assert!(start2 == 4, "Second match should start at position 4");
        assert!(end2 == 7, "Second match should end at position 7");

        let (start3, end3) = *results.at(2);
        assert!(start3 == 8, "Third match should start at position 8");
        assert!(end3 == 11, "Third match should end at position 11");

        let (start4, end4) = *results.at(3);
        assert!(start4 == 12, "Fourth match should start at position 12");
        assert!(end4 == 15, "Fourth match should end at position 15");
    }

    #[test]
    fn test_find_all_with_character_class() {
        // Pattern with character class
        let pattern_str: ByteArray = "[0-9]+";
        let mut regex = RegexTrait::new(pattern_str);

        // Find all sequences of digits
        let input: ByteArray = "abc123def456ghi789";
        let results = regex.find_all(input);

        assert!(results.len() == 3, "Should find 3 sequences of digits");

        // Check matches
        let (start1, end1) = *results.at(0);
        assert!(start1 == 3, "First match should start at position 3");
        assert!(end1 == 6, "First match should end at position 6");

        let (start2, end2) = *results.at(1);
        assert!(start2 == 9, "Second match should start at position 9");
        assert!(end2 == 12, "Second match should end at position 12");

        let (start3, end3) = *results.at(2);
        assert!(start3 == 15, "Third match should start at position 15");
        assert!(end3 == 18, "Third match should end at position 18");
    }

    #[test]
    fn test_find_all_with_quantifiers() {
        // Pattern with one or more quantifier
        let pattern_str: ByteArray = "a+";
        let mut regex = RegexTrait::new(pattern_str);

        // Find all sequences of one or more 'a's
        let input: ByteArray = "a aa aaa baab";
        let results = regex.find_all(input);

        assert!(results.len() == 4, "Should find 5 sequences of 'a's");

        // Check matches
        let (start1, end1) = *results.at(0);
        assert!(start1 == 0, "First match should start at position 0");
        assert!(end1 == 1, "First match should end at position 1");

        let (start2, end2) = *results.at(1);
        assert!(start2 == 2, "Second match should start at position 2");
        assert!(end2 == 4, "Second match should end at position 4");

        let (start3, end3) = *results.at(2);
        assert!(start3 == 5, "Third match should start at position 5");
        assert!(end3 == 8, "Third match should end at position 8");

        let (start4, end4) = *results.at(3);
        assert!(start4 == 10, "Fourth match should start at position 10");
        assert!(end4 == 12, "Fourth match should end at position 12");
    }

    #[test]
    fn test_find_all_overlapping_patterns() {
        let pattern_str: ByteArray = "aba";
        let mut regex = RegexTrait::new(pattern_str);

        let input: ByteArray = "ababababa";
        let results = regex.find_all(input);

        assert!(results.len() == 2, "Should find 2 non-overlapping 'aba's");

        let (start1, end1) = *results.at(0);
        assert!(start1 == 0, "First match should start at position 0");
        assert!(end1 == 3, "First match should end at position 3");

        let (start2, end2) = *results.at(1);
        assert!(start2 == 4, "Second match should start at position 4");
        assert!(end2 == 7, "Second match should end at position 7");
    }

    #[test]
    fn test_find_all_edge_cases() {
        // Empty pattern
        let pattern_str: ByteArray = "";
        let mut regex1 = RegexTrait::new(pattern_str);

        let input1: ByteArray = "abc";
        let results1 = regex1.find_all(input1);
        // Behavior varies among regex engines for empty pattern
        // Some implementations find positions between each character
        // Others find the start of each character
        assert!(results1.len() >= 1, "Empty pattern should match at least once");

        // No matches
        let pattern_str: ByteArray = "xyz";
        let mut regex2 = RegexTrait::new(pattern_str);

        let input2: ByteArray = "abc";
        let results2 = regex2.find_all(input2);
        assert!(results2.len() == 0, "Should find no matches");

        // Empty input
        let pattern_str: ByteArray = "abc";
        let mut regex3 = RegexTrait::new(pattern_str);

        let input3: ByteArray = "";
        let results3 = regex3.find_all(input3);
        assert!(results3.len() == 0, "Should find no matches in empty input");
    }

    #[test]
    fn test_find_all_complex_patterns() {
        // Pattern with multiple features
        let pattern_str: ByteArray = "[a-z]+[0-9]";
        let mut regex = RegexTrait::new(pattern_str);

        let input: ByteArray = "abc1 def2 ghi3 jkl";
        let results = regex.find_all(input);

        assert!(results.len() == 3, "Should find 3 matches");

        // Check matches
        let (start1, end1) = *results.at(0);
        assert!(start1 == 0, "First match should start at position 0");
        assert!(end1 == 4, "First match should end at position 4");

        let (start2, end2) = *results.at(1);
        assert!(start2 == 5, "Second match should start at position 5");
        assert!(end2 == 9, "Second match should end at position 9");

        let (start3, end3) = *results.at(2);
        assert!(start3 == 10, "Third match should start at position 10");
        assert!(end3 == 14, "Third match should end at position 14");
    }

    #[test]
    fn test_find_all_adjacent_matches() {
        // Test finding matches that are right next to each other
        let pattern_str: ByteArray = "[0-9]+";
        let mut regex = RegexTrait::new(pattern_str);

        let input: ByteArray = "123x456x789";
        let results = regex.find_all(input);

        assert!(results.len() == 3, "Should find 3 sequences of digits");

        // Check matches
        let (start1, end1) = *results.at(0);
        assert!(start1 == 0, "First match should start at position 0");
        assert!(end1 == 3, "First match should end at position 3");

        let (start2, end2) = *results.at(1);
        assert!(start2 == 4, "Second match should start at position 4");
        assert!(end2 == 7, "Second match should end at position 7");

        let (start3, end3) = *results.at(2);
        assert!(start3 == 8, "Third match should start at position 8");
        assert!(end3 == 11, "Third match should end at position 11");
    }

    #[test]
    fn test_find_all_optional_elements() {
        // Pattern with optional elements
        let pattern_str: ByteArray = "colou?r";
        let mut regex = RegexTrait::new(pattern_str);

        let input: ByteArray = "I prefer color but colour is also acceptable";
        let results = regex.find_all(input.clone());

        assert!(results.len() == 2, "Should find both 'color' and 'colour'");

        // Check matches
        let (start1, _) = *results.at(0);
        assert!(
            (input.clone().at(start1).unwrap() == 'c'
                && input.clone().at(start1 + 1).unwrap() == 'o'),
            "First match should be 'color' or 'colour'",
        );

        let (start2, _) = *results.at(1);
        assert!(
            (input.clone().at(start2).unwrap() == 'c'
                && input.clone().at(start2 + 1).unwrap() == 'o'),
            "Second match should be 'color' or 'colour'",
        );
    }
}
