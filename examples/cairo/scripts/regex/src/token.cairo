#[derive(Drop, Copy, PartialEq)]
pub enum Token {
    Literal: felt252,
    Wildcard,
    CharClass: (felt252, felt252), // Start and end characters
    ZeroOrOne, // ?
    OneOrMore, // +
    ZeroOrMore // *
}
// impl TokenIntoFelt252 of Into<Genre, felt252> {
//     fn into(self: Token) -> felt252 {
//         match self {
//             Token::Literal(l) => l,
//             Token::Wildcard => 46, // ASCII value of '*'
//             Token::CharClass(s, e) => ,
//         }
// }}

// impl Felt252TryIntoToken of TryInto<felt252, Genre> {}

impl TokenIntoFelt252 of Into<Token, felt252> {
    fn into(self: Token) -> felt252 {
        match self {
            Token::Literal(l) => l,
            Token::Wildcard => 46, // ASCII value of '.'
            Token::CharClass((
                _, _,
            )) => 91, // ASCII value of '[' (representing the start of a class)
            Token::ZeroOrOne => 63, // ASCII value of '?'
            Token::OneOrMore => 43, // ASCII value of '+'
            Token::ZeroOrMore => 42 // ASCII value of '*'
        }
    }
}

