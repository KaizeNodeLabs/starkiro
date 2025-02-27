#[cfg(test)]
mod matches_tests {
    use regex::token::{Token};
    use regex::regex::{Regex, RegexTrait};

    #[test]
    fn test_literal_exact_match() {
        let pattern_str: ByteArray = "hello";
        let mut regex = RegexTrait::new(pattern_str);

        // Exact match
        let input1: ByteArray = "hello";
        assert!(regex.matches(input1.into()), "Should match exact pattern");

        // Prefix match
        let input2: ByteArray = "hello world";
        assert!(!regex.matches(input2.into()), "Should not match when input has extra characters");

        // Partial match
        let input3: ByteArray = "hell";
        assert!(!regex.matches(input3.into()), "Should not match incomplete pattern");

        // No match
        let input4: ByteArray = "bye";
        assert!(!regex.matches(input4.into()), "Should not match different text");
    }

    #[test]
    fn test_wildcard_match() {
        let pattern_str: ByteArray = "h.llo";
        let mut regex = RegexTrait::new(pattern_str);

        // Various wildcard matches
        let input1: ByteArray = "hello";
        assert!(regex.matches(input1.into()), "Should match 'hello'");

        let input2: ByteArray = "hallo";
        assert!(regex.matches(input2.into()), "Should match 'hallo'");

        let input3: ByteArray = "h9llo";
        assert!(regex.matches(input3.into()), "Should match 'h9llo'");

        // Non matches
        let input4: ByteArray = "hllo";
        assert!(!regex.matches(input4.into()), "Should not match 'hllo' - missing character");

        let input5: ByteArray = "helloextra";
        assert!(!regex.matches(input5.into()), "Should not match when input has extra characters");
    }

    #[test]
    fn test_zero_or_one_match() {
        let pattern_str: ByteArray = "colou?r";
        let mut regex = RegexTrait::new(pattern_str);

        // With optional character
        let input1: ByteArray = "colour";
        assert!(regex.matches(input1.into()), "Should match 'colour'");

        // Without optional character
        let input2: ByteArray = "color";
        assert!(regex.matches(input2.into()), "Should match 'color'");

        // Non matches
        let input3: ByteArray = "colouur";
        //TODO assert!(!regex.matches(input3.into()), "Should not match 'colouur' - too many 'u's");

        let input4: ByteArray = "colours";
        assert!(!regex.matches(input4.into()), "Should not match 'colours' - extra character");
    }

    #[test]
    fn test_this_one() {
        let pattern_str: ByteArray = "colou?r";
        let mut regex = RegexTrait::new(pattern_str);

        // Without optional character
        let input2: ByteArray = "color";
        assert!(regex.matches(input2.into()), "Should match 'color'");
    }

    #[test]
    fn test_one_or_more_match() {
        let pattern_str: ByteArray = "a+b";
        let mut regex = RegexTrait::new(pattern_str);

        // Single occurrence
        let input1: ByteArray = "ab";
        assert!(regex.matches(input1.into()), "Should match 'ab'");

        // Multiple occurrences
        let input2: ByteArray = "aab";
        assert!(regex.matches(input2.into()), "Should match 'aab'");

        let input3: ByteArray = "aaaab";
        assert!(regex.matches(input3.into()), "Should match 'aaaab'");

        // Non matches
        let input4: ByteArray = "b";
        assert!(!regex.matches(input4.into()), "Should not match 'b' - missing required 'a'");

        let input5: ByteArray = "abc";
        assert!(!regex.matches(input5.into()), "Should not match 'abc' - extra character");
    }

    #[test]
    fn test_zero_or_more_match() {
        let pattern_str: ByteArray = "a*b";
        let mut regex = RegexTrait::new(pattern_str);

        // Zero occurrences
        let input1: ByteArray = "b";
        assert!(regex.matches(input1.into()), "Should match 'b'");

        // Single occurrence
        let input2: ByteArray = "ab";
        assert!(regex.matches(input2.into()), "Should match 'ab'");

        // Multiple occurrences
        let input3: ByteArray = "aaab";
        assert!(regex.matches(input3.into()), "Should match 'aaab'");

        // Non matches
        let input4: ByteArray = "bb";
        assert!(!regex.matches(input4.into()), "Should not match 'bb' - extra character");

        let input5: ByteArray = "aaa";
        assert!(!regex.matches(input5.into()), "Should not match 'aaa' - missing 'b'");
    }

    #[test]
    fn test_character_class_match() {
        let pattern_str: ByteArray = "h[a-z]llo";
        let mut regex = RegexTrait::new(pattern_str);

        // Various valid matches
        let input1: ByteArray = "hallo";
        assert!(regex.matches(input1.into()), "Should match 'hallo'");

        let input2: ByteArray = "hello";
        assert!(regex.matches(input2.into()), "Should match 'hello'");

        let input3: ByteArray = "hzllo";
        assert!(regex.matches(input3.into()), "Should match 'hzllo'");

        // Non matches
        let input4: ByteArray = "h9llo";
        assert!(!regex.matches(input4.into()), "Should not match 'h9llo' - digit not in class");

        let input5: ByteArray = "hAllo";
        assert!(!regex.matches(input5.into()), "Should not match 'hAllo' - uppercase not in class");

        let input6: ByteArray = "hlo";
        assert!(!regex.matches(input6.into()), "Should not match 'hlo' - missing character");
    }

    #[test]
    fn test_numeric_character_class() {
        let pattern_str: ByteArray = "[0-9]+";
        let mut regex = RegexTrait::new(pattern_str);

        // Single digit
        let input1: ByteArray = "5";
        assert!(regex.matches(input1.into()), "Should match single digit");

        // Multiple digits
        let input2: ByteArray = "12345";
        assert!(regex.matches(input2.into()), "Should match multiple digits");

        // Non matches
        let input3: ByteArray = "12a45";
        assert!(!regex.matches(input3.into()), "Should not match with non-digit");

        let input4: ByteArray = "";
        assert!(!regex.matches(input4.into()), "Should not match empty string");
    }

    #[test]
    fn test_combined_patterns() {
        // Test digit followed by optional letter and any character
        let pattern_str: ByteArray = "[0-9][a-z]?.";
        let mut regex = RegexTrait::new(pattern_str);

        // With optional letter
        let input1: ByteArray = "5a!";
        assert!(regex.matches(input1.into()), "Should match '5a!'");

        // Without optional letter
        let input2: ByteArray = "5!";
        assert!(regex.matches(input2.into()), "Should match '5!'");

        // Non matches
        let input3: ByteArray = "5";
        assert!(!regex.matches(input3.into()), "Should not match '5' - missing final char");

        let input4: ByteArray = "5ab";
        assert!(regex.matches(input4.into()), "Should match '5ab'");
    }

    #[test]
    fn test_edge_cases() {
        // Empty pattern should match only empty string
        let empty_pattern: ByteArray = "";
        let non_empty_string: ByteArray = "a";
        let mut empty_regex = RegexTrait::new(empty_pattern.clone());

        assert!(
            empty_regex.matches(empty_pattern.clone()), "Empty pattern should match empty string",
        );
        assert!(
            !empty_regex.matches(non_empty_string),
            "Empty pattern should not match non-empty string",
        );

        // Pattern with just wildcards
        let wildcard_pattern: ByteArray = "...";
        let mut wildcard_regex = RegexTrait::new(wildcard_pattern);
        let two_chars: ByteArray = "ab";
        let three_chars: ByteArray = "abc";
        let four_chars: ByteArray = "abcd";

        assert!(wildcard_regex.matches(three_chars), "Wildcard pattern should match any 3 chars");
        assert!(
            !wildcard_regex.matches(four_chars), "Wildcard pattern should not match more chars",
        );
        assert!(
            !wildcard_regex.matches(two_chars), "Wildcard pattern should not match fewer chars",
        );

        // Pattern with multiple quantifiers
        let multi_quant_pattern: ByteArray = "a?b+c*";
        let mut multi_quant_regex = RegexTrait::new(multi_quant_pattern);
        let bbc: ByteArray = "bbc";
        let abc: ByteArray = "abc";
        let abbc: ByteArray = "abbc";
        let abbccc: ByteArray = "abbccc";
        let abb: ByteArray = "abb";
        let ac: ByteArray = "ac";

        assert!(multi_quant_regex.matches(bbc), "Should match with optional a missing");
        assert!(multi_quant_regex.matches(abc), "Should match with optional a present");
        assert!(multi_quant_regex.matches(abbc), "Should match with multiple b's");
        //TODO
        // assert!(multi_quant_regex.matches(abbccc), "Should match with multiple c's");
        // assert!(multi_quant_regex.matches(abb), "Should match with zero c's");
        assert!(!multi_quant_regex.matches(ac), "Should not match missing required b");
    }
}
