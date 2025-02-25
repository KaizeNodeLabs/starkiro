#[cfg(test)]
mod tests {
    use regex::token::{Token};
    use regex::regex::{Regex, RegexTrait};


    #[test]
    fn test_zero_or_more_token() {
        let regex = RegexTrait::new("*");

        assert(*regex.pattern.at(0) == Token::ZeroOrMore, 'expected ZeroOrMore token');
    }
    #[test]
    fn test_one_or_more_token() {
        let regex = RegexTrait::new("+");

        assert(*regex.pattern.at(0) == Token::OneOrMore, 'expected OneOrMore token');
    }
    #[test]
    fn test_zero_or_one_token() {
        let regex = RegexTrait::new("?");

        assert(*regex.pattern.at(0) == Token::ZeroOrOne, 'expected ZeroOrOne token');
    }
    #[test]
    fn test_wildcard_token() {
        let regex = RegexTrait::new(".");

        assert(*regex.pattern.at(0) == Token::Wildcard, 'expected Wildcard token');
    }
    // #[test]
// fn test_char_class_token() {
//     let regex = RegexTrait::new("h[a-e]llo");

    //     assert(*regex.pattern.at(0) == Token::CharClass, 'wrong CharClass token');
// }
// #[test]
// fn test_literal_token() {
//     let regex = RegexTrait::new("hello");

    //     assert(*regex.pattern.at(0) == Token::Literal, 'expected Literal token');
// }
}
