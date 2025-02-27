#[cfg(test)]
mod find_tests {
    use regex::regex::{RegexTrait};

    #[test]
    fn test_find_literal() {
        // Simple literal pattern
        let pattern_str: ByteArray = "hello";
        let mut regex = RegexTrait::new(pattern_str.into());

        // Find in the beginning
        let input1: ByteArray = "hello world";
        let result1 = regex.find(input1.into());
        assert!(result1.is_some(), "Should find 'hello' at the beginning");
        let (start1, end1) = result1.unwrap();
        assert!(start1 == 0, "Should start at position 0");
        assert!(end1 == 5, "Should end at position 5");

        // Find in the middle
        let input2: ByteArray = "say hello there";
        let result2 = regex.find(input2.into());
        assert!(result2.is_some(), "Should find 'hello' in the middle");
        let (start2, end2) = result2.unwrap();
        assert!(start2 == 4, "Should start at position 4");
        assert!(end2 == 9, "Should end at position 9");

        // Find at the end
        let input3: ByteArray = "goodbye hello";
        let result3 = regex.find(input3.into());
        assert!(result3.is_some(), "Should find 'hello' at the end");
        let (start3, end3) = result3.unwrap();
        assert!(start3 == 8, "Should start at position 8");
        assert!(end3 == 13, "Should end at position 13");

        // Not found
        let input4: ByteArray = "hi there";
        let result4 = regex.find(input4.into());
        assert!(result4.is_none(), "Should not find 'hello'");
    }

    #[test]
    fn test_find_with_wildcard() {
        // Pattern with wildcard
        let pattern_str: ByteArray = "h.llo";
        let mut regex = RegexTrait::new(pattern_str.into());

        // Find various matches
        let input1: ByteArray = "hello and hallo";
        let result1 = regex.find(input1.into());
        assert!(result1.is_some(), "Should find 'hello'");
        let (start1, end1) = result1.unwrap();
        assert!(start1 == 0, "Should start at position 0");
        assert!(end1 == 5, "Should end at position 5");

        // Test finding the second match
        let input2: ByteArray = "hello and hallo";
        let result2 = regex.find(input2.into());
        assert!(result2.is_some(), "Should find a match");
    }

    #[test]
    fn test_find_with_character_class() {
        // Pattern with character class
        let pattern_str: ByteArray = "[0-9]+";
        let mut regex = RegexTrait::new(pattern_str.into());

        // Find digits
        let input1: ByteArray = "abc123def";
        let result1 = regex.find(input1.into());
        assert!(result1.is_some(), "Should find digits");
        let (start1, end1) = result1.unwrap();
        assert!(start1 == 3, "Should start at position 3");
        assert!(end1 == 6, "Should end at position 6");

        // Find at beginning
        let input2: ByteArray = "456abc";
        let result2 = regex.find(input2.into());
        assert!(result2.is_some(), "Should find digits at beginning");
        let (start2, end2) = result2.unwrap();
        assert!(start2 == 0, "Should start at position 0");
        assert!(end2 == 3, "Should end at position 3");

        // No digits
        let input3: ByteArray = "abcdef";
        let result3 = regex.find(input3.into());
        assert!(result3.is_none(), "Should not find any digits");
    }

    #[test]
    fn test_find_with_quantifiers() {
        // Pattern with zero or one quantifier
        let pattern_str: ByteArray = "colou?r";
        let mut regex1 = RegexTrait::new(pattern_str.into());

        let input1: ByteArray = "I like color and colour";
        let result1 = regex1.find(input1.into());
        assert!(result1.is_some(), "Should find 'color'");
        let (start1, end1) = result1.unwrap();
        assert!(start1 == 7, "Should start at position 7");
        assert!(end1 == 12, "Should end at position 12");

        // Pattern with one or more quantifier
        let pattern_str: ByteArray = "go+gle";
        let mut regex2 = RegexTrait::new(pattern_str.into());

        let input2: ByteArray = "I use gogle, google, and gooogle for search";
        let result2 = regex2.find(input2.into());
        assert!(result2.is_some(), "Should find 'gogle'");
        let (start2, end2) = result2.unwrap();
        assert!(start2 == 6, "Should start at position 6");
        assert!(end2 == 11, "Should end at position 11");

        // Pattern with zero or more quantifier
        let pattern_str: ByteArray = "go*gle";
        let mut regex3 = RegexTrait::new(pattern_str.into());

        let input3: ByteArray = "I use ggle and google";
        let result3 = regex3.find(input3.into());
        assert!(result3.is_some(), "Should find 'ggle'");
        let (start3, end3) = result3.unwrap();
        assert!(start3 == 6, "Should start at position 6");
        assert!(end3 == 10, "Should end at position 10");
    }

    #[test]
    fn test_find_edge_cases() {
        // Empty pattern
        let pattern_str: ByteArray = "";
        let mut regex1 = RegexTrait::new(pattern_str.into());

        let input1: ByteArray = "hello";
        let result1 = regex1.find(input1.into());
        assert!(result1.is_some(), "Empty pattern should match at beginning");
        let (start1, end1) = result1.unwrap();
        assert!(start1 == 0, "Should start at position 0");
        assert!(end1 == 0, "Should end at position 0");

        // Pattern longer than text
        let pattern_str: ByteArray = "abcdefghij";
        let mut regex2 = RegexTrait::new(pattern_str.into());

        let input2: ByteArray = "abcde";
        let result2 = regex2.find(input2.into());
        assert!(result2.is_none(), "Should not find pattern longer than text");

        // Find in empty text
        let pattern_str: ByteArray = "abc";
        let mut regex3 = RegexTrait::new(pattern_str.into());

        let input3: ByteArray = "";
        let result3 = regex3.find(input3.into());
        assert!(result3.is_none(), "Should not find in empty text");
    }

    #[test]
    fn test_find_overlapping() {
        // Test finding overlapping patterns
        let pattern_str: ByteArray = "ana";
        let mut regex = RegexTrait::new(pattern_str.into());

        let input: ByteArray = "banana";
        let result = regex.find(input.into());
        assert!(result.is_some(), "Should find 'ana'");
        let (start, end) = result.unwrap();
        // The first 'ana' in 'banana' starts at position 1
        assert!(start == 1, "Should start at position 1");
        assert!(end == 4, "Should end at position 4");
    }

    #[test]
    fn test_find_complex_patterns() {
        // More complex pattern with multiple features
        let pattern_str: ByteArray = "a[0-9]+b?c*";
        let mut regex = RegexTrait::new(pattern_str.into());

        let input1: ByteArray = "xa123bc hello";
        let result1 = regex.find(input1.into());
        assert!(result1.is_some(), "Should find complex pattern");
        let (start1, end1) = result1.unwrap();
        assert!(start1 == 1, "Should start at position 1");
        assert!(end1 == 7, "Should end at position 7");

        let input2: ByteArray = "a456 a7bccc";
        let result2 = regex.find(input2.into());
        assert!(result2.is_some(), "Should find complex pattern");
        let (start2, end2) = result2.unwrap();
        assert!(start2 == 0, "Should start at position 0");
        assert!(end2 == 4, "Should end at position 4");
    }
}
