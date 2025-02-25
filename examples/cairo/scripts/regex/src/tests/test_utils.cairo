use regex::token::{Token};
use regex::regex::{Regex, RegexTrait};

// Helper function to compare tokens for testing
pub fn tokens_are_equal(actual: Array<Token>, expected: Array<Token>) -> bool {
    if actual.len() != expected.len() {
        return false;
    }

    let mut i = 0;
    let mut result = true;
    while i < actual.len() {
        let actual_token = *actual.at(i);
        let expected_token = *expected.at(i);

        match (actual_token, expected_token) {
            (Token::Literal(a), Token::Literal(b)) => { if a != b {
                result = false;
                break;
            } },
            (
                Token::CharClass((a_start, a_end)), Token::CharClass((b_start, b_end)),
            ) => { if a_start != b_start || a_end != b_end {
                result = false;
                break;
            } },
            (Token::Wildcard, Token::Wildcard) => {},
            (Token::ZeroOrOne, Token::ZeroOrOne) => {},
            (Token::OneOrMore, Token::OneOrMore) => {},
            (Token::ZeroOrMore, Token::ZeroOrMore) => {},
            _ => {
                result = false;
                break;
            },
        }

        i += 1;
    };

    result
}
