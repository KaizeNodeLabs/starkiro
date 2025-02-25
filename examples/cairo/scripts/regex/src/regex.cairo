// Basic Regex Utility Implementation for Cairo
// Implements a simplified regex engine with support for essential pattern matching

#[derive(Drop, Copy, PartialEq)]
pub enum Token {
    Literal: felt252,
    Wildcard,
    CharClass: (felt252, felt252), // Start and end characters
    ZeroOrOne, // ?
    OneOrMore, // +
    ZeroOrMore // *
}

#[derive(Drop)]
pub struct Regex {
    pub pattern: Array<Token>,
}

// Initialization and pattern parsing logic
pub trait RegexTrait {
    fn new(pattern_str: ByteArray) -> Regex;
}

impl RegexImpl of RegexTrait {
    // Create a new Regex instance from a pattern string
    fn new(pattern_str: ByteArray) -> Regex {
        let mut pattern = ArrayTrait::new();
        let mut i = 0;
        let len = pattern_str.len();

        while i < len {
            let char = pattern_str.at(i).unwrap();

            // Parse special characters
            if char == 42 { //*
                pattern.append(Token::ZeroOrMore);
            } else if char == 43 { //+
                pattern.append(Token::OneOrMore);
            } else if char == 63 { // ?
                pattern.append(Token::ZeroOrOne);
            } else if char == 46 { // .
                pattern.append(Token::Wildcard);
            } else if char == 91 && i + 2 < len { // [
                // Parse character class [a-z]
                i += 1;
                let start_char = pattern_str.at(i).unwrap();

                // Check for range notation
                if i
                    + 2 < len
                        && pattern_str.at(i + 1).unwrap() == 45
                        && pattern_str.at(i + 3).unwrap() == 93 {
                    i += 2;
                    let end_char = pattern_str.at(i).unwrap();
                    pattern.append(Token::CharClass((start_char.into(), end_char.into())));
                    i += 1; // Skip closing bracket
                } else {
                    // Handle single character class
                    pattern.append(Token::Literal(start_char.into()));
                    // Find closing bracket
                    while i < len && pattern_str.at(i).unwrap() != 93 {
                        i += 1;
                    }
                }
            } else {
                // Regular character
                pattern.append(Token::Literal(char.into()));
            }

            i += 1;
        };

        Regex { pattern }
    }
}

