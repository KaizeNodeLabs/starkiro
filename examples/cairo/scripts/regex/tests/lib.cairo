#[cfg(test)]
mod tests {
    use regex::regex::{RegexTrait, Regex, Token};

    #[test]
    fn test() {
        let regex = RegexTrait::new("?");

        assert(*regex.pattern.at(0) == Token::ZeroOrOne, 'wrong token');
    }
}
