#[cfg(test)]
mod tests {
    use regex::token::{Token};
    use regex::regex::{Regex, RegexTrait};
    use regex::tests::test_utils::tokens_are_equal;


    #[test]
    fn test_literal_pattern() {
        let pattern_str: ByteArray = "hello";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('h'.into()));
        expected.append(Token::Literal('e'.into()));
        expected.append(Token::Literal('l'.into()));
        expected.append(Token::Literal('l'.into()));
        expected.append(Token::Literal('o'.into()));

        assert!(tokens_are_equal(regex.pattern, expected), "Literal pattern parsing failed");
    }

    #[test]
    fn test_wildcard_pattern() {
        let pattern_str: ByteArray = "h.llo";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('h'.into()));
        expected.append(Token::Wildcard);
        expected.append(Token::Literal('l'.into()));
        expected.append(Token::Literal('l'.into()));
        expected.append(Token::Literal('o'.into()));

        assert!(tokens_are_equal(regex.pattern, expected), "Wildcard pattern parsing failed");
    }

    #[test]
    fn test_zero_or_one_pattern() {
        let pattern_str: ByteArray = "colou?r";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('c'.into()));
        expected.append(Token::Literal('o'.into()));
        expected.append(Token::Literal('l'.into()));
        expected.append(Token::Literal('o'.into()));
        expected.append(Token::Literal('u'.into()));
        expected.append(Token::ZeroOrOne);
        expected.append(Token::Literal('r'.into()));

        assert!(tokens_are_equal(regex.pattern, expected), "Zero or one pattern parsing failed");
    }

    #[test]
    fn test_one_or_more_pattern() {
        let pattern_str: ByteArray = "a+b";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('a'.into()));
        expected.append(Token::OneOrMore);
        expected.append(Token::Literal('b'.into()));

        assert!(tokens_are_equal(regex.pattern, expected), "One or more pattern parsing failed");
    }

    #[test]
    fn test_zero_or_more_pattern() {
        let pattern_str: ByteArray = "a*b";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('a'.into()));
        expected.append(Token::ZeroOrMore);
        expected.append(Token::Literal('b'.into()));

        assert!(tokens_are_equal(regex.pattern, expected), "Zero or more pattern parsing failed");
    }

    #[test]
    fn test_character_class_pattern() {
        let pattern_str: ByteArray = "h[a-z]llo";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('h'.into()));
        expected.append(Token::CharClass(('a'.into(), 'z'.into())));
        expected.append(Token::Literal('l'.into()));
        expected.append(Token::Literal('l'.into()));
        expected.append(Token::Literal('o'.into()));

        assert!(
            tokens_are_equal(regex.pattern, expected), "Character class pattern parsing failed",
        );
    }

    #[test]
    fn test_numeric_character_class() {
        let pattern_str: ByteArray = "[0-9]+";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::CharClass(('0'.into(), '9'.into())));
        expected.append(Token::OneOrMore);

        assert!(
            tokens_are_equal(regex.pattern, expected), "Numeric character class parsing failed",
        );
    }

    #[test]
    fn test_mixed_pattern() {
        let pattern_str: ByteArray = "a[b-d]+e?f*g.";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('a'.into()));
        expected.append(Token::CharClass(('b'.into(), 'd'.into())));
        expected.append(Token::OneOrMore);
        expected.append(Token::Literal('e'.into()));
        expected.append(Token::ZeroOrOne);
        expected.append(Token::Literal('f'.into()));
        expected.append(Token::ZeroOrMore);
        expected.append(Token::Literal('g'.into()));
        expected.append(Token::Wildcard);

        assert!(tokens_are_equal(regex.pattern, expected), "Mixed pattern parsing failed");
    }

    #[test]
    fn test_empty_pattern() {
        let pattern_str: ByteArray = "";
        let regex = RegexTrait::new(pattern_str.into());

        let expected = ArrayTrait::new();

        assert!(tokens_are_equal(regex.pattern, expected), "Empty pattern parsing failed");
    }

    // #[test]
    // fn test_special_chars_as_literals() {
    //     // Testing special characters when they should be treated as literals
    //     let pattern_str: ByteArray = "\\*\\+\\?\\.\\\\\\/";
    //     let regex = RegexTrait::new(pattern_str);

    //     let mut expected = ArrayTrait::new();
    //     expected.append(Token::Literal('\\'.into()));
    //     expected.append(Token::Literal('*'.into()));
    //     expected.append(Token::Literal('\\'.into()));
    //     expected.append(Token::Literal('+'.into()));
    //     expected.append(Token::Literal('\\'.into()));
    //     expected.append(Token::Literal('?'.into()));
    //     expected.append(Token::Literal('\\'.into()));
    //     expected.append(Token::Literal('.'.into()));
    //     expected.append(Token::Literal('\\'.into()));
    //     expected.append(Token::Literal('\\'.into()));
    //     expected.append(Token::Literal('\\'.into()));
    //     expected.append(Token::Literal('/'.into()));

    //     assert!(
    //         tokens_are_equal(regex.pattern, expected), "Special chars as literals parsing
    //         failed",
    //     );
    // }

    #[test]
    fn test_malformed_character_class() {
        // Testing a malformed character class [a (missing closing bracket)
        let pattern_str: ByteArray = "test[a";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('t'.into()));
        expected.append(Token::Literal('e'.into()));
        expected.append(Token::Literal('s'.into()));
        expected.append(Token::Literal('t'.into()));
        expected.append(Token::Literal('['.into()));
        expected.append(Token::Literal('a'.into()));

        assert!(
            tokens_are_equal(regex.pattern, expected), "Malformed character class parsing failed",
        );
    }

    #[test]
    fn test_trailing_special_char() {
        // Testing a pattern that ends with a special character
        let pattern_str: ByteArray = "abc+";
        let regex = RegexTrait::new(pattern_str);

        let mut expected = ArrayTrait::new();
        expected.append(Token::Literal('a'.into()));
        expected.append(Token::Literal('b'.into()));
        expected.append(Token::Literal('c'.into()));
        expected.append(Token::OneOrMore);

        assert!(tokens_are_equal(regex.pattern, expected), "Trailing special char parsing failed");
    }
    // #[test]
// fn test_email_pattern() {
//     // Test a practical example like an email pattern
//     let pattern_str: ByteArray = "[a-z]+@[a-z]+\\.[a-z]+";
//     let regex = RegexTrait::new(pattern_str);

    //     let mut expected = ArrayTrait::new();
//     expected.append(Token::CharClass(('a'.into(), 'z'.into())));
//     expected.append(Token::OneOrMore);
//     expected.append(Token::Literal('@'.into()));
//     expected.append(Token::CharClass(('a'.into(), 'z'.into())));
//     expected.append(Token::OneOrMore);
//     expected.append(Token::Literal('\\'.into()));
//     expected.append(Token::Literal('.'.into()));
//     expected.append(Token::CharClass(('a'.into(), 'z'.into())));
//     expected.append(Token::OneOrMore);

    //     assert!(tokens_are_equal(regex.pattern, expected), "Email pattern parsing failed");
// }
}
