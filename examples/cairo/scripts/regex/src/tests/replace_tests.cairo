#[cfg(test)]
mod replace_tests {
    use regex::regex::{Regex, RegexTrait};
    use regex::tests::test_utils::assert_equal_bytearrays;


    #[test]
    fn test_replace_literal() {
        // Simple literal pattern
        let pattern_str: ByteArray = "cat";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "dog";

        // Basic replacement
        let input: ByteArray = "The cat sat on the mat";
        let result = regex.replace(input, replacement.clone());

        // Convert result back to string for comparison
        let expected: ByteArray = "The dog sat on the mat";
        assert_equal_bytearrays(result, expected);

        // Multiple replacements
        let input: ByteArray = "cat cat cat";
        let result2 = regex.replace(input, replacement.clone());

        let expected: ByteArray = "dog dog dog";
        assert_equal_bytearrays(result2, expected);

        // No replacements
        let input: ByteArray = "The dog sat on the mat";
        let result3 = regex.replace(input, replacement.clone());

        let expected: ByteArray = "The dog sat on the mat";
        assert_equal_bytearrays(result3, expected);
    }

    #[test]
    fn test_replace_with_wildcard() {
        // Pattern with wildcard
        let pattern_str: ByteArray = "c.t";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "dog";

        // Replace different variants
        let input: ByteArray = "cat cut cot";
        let result = regex.replace(input, replacement.clone());

        let expected: ByteArray = "dog dog dog";
        assert_equal_bytearrays(result, expected);
    }

    #[test]
    fn test_replace_with_character_class() {
        // Pattern with character class
        let pattern_str: ByteArray = "[0-9]+";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "NUM";

        // Replace digit sequences
        let input: ByteArray = "abc123def456";
        let result = regex.replace(input, replacement.clone());

        let expected: ByteArray = "abcNUMdefNUM";
        assert_equal_bytearrays(result, expected);
    }

    #[test]
    fn test_replace_with_quantifiers() {
        // Pattern with one or more quantifier
        let pattern_str: ByteArray = "a+";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "X";

        // Replace sequences of 'a's
        let input: ByteArray = "a aa aaa";
        let result = regex.replace(input, replacement.clone());

        let expected: ByteArray = "X X X";
        assert_equal_bytearrays(result, expected);

        // Pattern with zero or one quantifier
        let pattern: ByteArray = "colou?r";
        let mut regex2 = RegexTrait::new(pattern);
        let replacement: ByteArray = "hue";

        let input: ByteArray = "color and colour";
        let result2 = regex2.replace(input, replacement.clone());

        let expected2 = "hue and hue";
        assert_equal_bytearrays(result2, expected2);
    }

    #[test]
    fn test_replace_edge_cases() {
        // Empty pattern
        let pattern_str1 = "";
        let mut regex1 = RegexTrait::new(pattern_str1);
        let replacement1 = "X";

        let input1 = "abc";
        let result1 = regex1.replace(input1.clone(), replacement1);

        assert!(
            result1.len() >= input1.clone().len(),
            "Empty pattern replace should at least preserve input length",
        );

        // Empty replacement
        let pattern: ByteArray = "cat";
        let mut regex2 = RegexTrait::new(pattern);
        let replacement: ByteArray = "";

        let input: ByteArray = "The cat sat on the mat";
        let result2 = regex2.replace(input, replacement.clone());

        let expected2 = "The  sat on the mat";
        assert_equal_bytearrays(result2, expected2);

        // Empty input
        let pattern: ByteArray = "cat";
        let mut regex3 = RegexTrait::new(pattern);
        let replacement: ByteArray = "dog";

        let input: ByteArray = "";
        let result3 = regex3.replace(input, replacement.clone());

        let expected: ByteArray = "";
        assert_equal_bytearrays(result3, expected);
    }

    #[test]
    fn test_replace_complex_patterns() {
        // Complex pattern with multiple features
        let pattern_str: ByteArray = "a[0-9]+b";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "X";

        let input: ByteArray = "a123b foo a456b bar a7b";
        let result = regex.replace(input, replacement.clone());

        let expected: ByteArray = "X foo X bar X";
        assert_equal_bytearrays(result, expected);
    }

    #[test]
    fn test_replace_overlapping() {
        // Test replacing potentially overlapping patterns
        // Most regex engines find non-overlapping matches
        let pattern_str: ByteArray = "aba";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "X";

        let input: ByteArray = "ababababa";
        let result = regex.replace(input.clone(), replacement.clone());

        // For non-overlapping matches, we expect "XbXbX" or "XXX" depending on implementation
        assert!(result.len() < input.clone().len(), "Replacement should be shorter than original");
    }

    #[test]
    fn test_replace_with_longer_text() {
        // Replace with longer text
        let pattern_str: ByteArray = "cat";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "elephant";

        let input: ByteArray = "The cat sat on the mat";
        let result = regex.replace(input, replacement.clone());

        let expected: ByteArray = "The elephant sat on the mat";
        assert_equal_bytearrays(result, expected);
    }

    #[test]
    fn test_replace_at_boundaries() {
        // Replace at start, middle, and end
        let pattern_str: ByteArray = "x";
        let mut regex = RegexTrait::new(pattern_str);
        let replacement: ByteArray = "Y";

        let input: ByteArray = "xabcx123x";
        let result = regex.replace(input, replacement.clone());

        let expected: ByteArray = "YabcY123Y";
        assert_equal_bytearrays(result, expected);
    }
}
