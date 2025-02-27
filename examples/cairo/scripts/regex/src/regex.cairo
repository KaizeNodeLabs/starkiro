//! Basic Regex Utility for Cairo
//! Implementation of a simplified regex engine supporting essential pattern matching features.

use regex::token::{Token};

/// A regular expression pattern compiled into a sequence of tokens
#[derive(Drop)]
pub struct Regex {
    pub pattern: Array<Token>,
}

/// Core regex operations trait
pub trait RegexTrait {
    /// Create a new Regex instance from a pattern string
    ///
    /// # Arguments
    /// * `pattern_str` - A string representing the regex pattern
    fn new(pattern_str: ByteArray) -> Regex;

    /// Check if the entire text matches the pattern
    ///
    /// # Arguments
    /// * `text` - The input text to match against the pattern
    ///
    /// # Returns
    /// `true` if the entire text matches the pattern, `false` otherwise
    fn matches(ref self: Regex, text: ByteArray) -> bool;

    /// Find the first occurrence of the pattern in the text
    ///
    /// # Arguments
    /// * `text` - The input text to search for the pattern
    ///
    /// # Returns
    /// `Option<(usize, usize)>` - Start and end positions of the first match, or None if no match
    /// found
    fn find(ref self: Regex, text: ByteArray) -> Option<(usize, usize)>;

    /// Find all occurrences of the pattern in the text
    ///
    /// # Arguments
    /// * `text` - The input text to search for the pattern
    ///
    /// # Returns
    /// A span of tuples containing start and end positions of all matches
    fn find_all(ref self: Regex, text: ByteArray) -> Span<(usize, usize)>;

    /// Replace all occurrences of the pattern with the replacement text
    ///
    /// # Arguments
    /// * `text` - The input text to perform replacements on
    /// * `replacement` - The text to insert in place of matches
    ///
    /// # Returns
    /// A new text with all matches replaced
    fn replace(ref self: Regex, text: ByteArray, replacement: ByteArray) -> ByteArray;
}

impl RegexImpl of RegexTrait {
    fn new(pattern_str: ByteArray) -> Regex {
        let mut pattern = ArrayTrait::new();
        let mut i = 0;
        let len = pattern_str.len();

        while i < len {
            let char = pattern_str.at(i).unwrap();

            // Parse special characters
            if char == 42 { // *
                if pattern.len() > 0 {
                    pattern.append(Token::ZeroOrMore);
                } else {
                    pattern.append(Token::Literal(char.into()));
                }
            } else if char == 43 { // +
                if pattern.len() > 0 {
                    pattern.append(Token::OneOrMore);
                } else {
                    pattern.append(Token::Literal(char.into()));
                }
            } else if char == 63 { // ?
                if pattern.len() > 0 {
                    pattern.append(Token::ZeroOrOne);
                } else {
                    pattern.append(Token::Literal(char.into()));
                }
            } else if char == 46 { // .
                pattern.append(Token::Wildcard);
            } else if char == 91 && i + 3 < len { // [
                // Parse character class [a-z]
                i += 1;
                let start_char = pattern_str.at(i).unwrap();

                // Check for range notation
                if pattern_str.at(i + 1).unwrap() == 45 && pattern_str.at(i + 3).unwrap() == 93 {
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

    fn matches(ref self: Regex, text: ByteArray) -> bool {
        let result = self._match(text.clone(), 0, 0);
        let res = match result {
            Option::Some((end_pos, _)) => { end_pos == text.clone().len() },
            Option::None => false,
        };

        res
    }

    fn find(ref self: Regex, text: ByteArray) -> Option<(usize, usize)> {
        let mut start_pos = 0;
        let text_len = text.clone().len();
        let mut result: Option<(usize, usize)> = Option::None;

        while start_pos < text_len {
            let match_result = self._match(text.clone(), start_pos, 0);
            match match_result {
                Option::Some((
                    end_pos, _,
                )) => {
                    result = Option::Some((start_pos, end_pos));
                    break;
                },
                Option::None => start_pos += 1,
            }
        };

        result
    }

    fn find_all(ref self: Regex, text: ByteArray) -> Span<(usize, usize)> {
        let mut matches = ArrayTrait::new();
        let mut start_pos = 0;
        let text_len = text.clone().len();

        while start_pos < text_len {
            let match_result = self._match(text.clone(), start_pos, 0);
            match match_result {
                Option::Some((
                    end_pos, _,
                )) => {
                    matches.append((start_pos, end_pos));
                    // Move past this match to find the next one
                    start_pos = if end_pos > start_pos {
                        end_pos
                    } else {
                        start_pos + 1
                    };
                },
                Option::None => start_pos += 1,
            }
        };

        matches.span()
    }

    fn replace(ref self: Regex, text: ByteArray, replacement: ByteArray) -> ByteArray {
        let mut result: ByteArray = "";
        let mut last_end = 0;
        let text_len = text.clone().len();

        // Find all matches and replace them
        let matches = self.find_all(text.clone());
        let matches_len = matches.len();

        let mut i = 0;
        while i < matches_len {
            let (start, end) = *matches.at(i);

            // Copy text from last_end to start
            let mut j = last_end;
            while j < start {
                result.append_byte(text.clone().at(j).unwrap());
                j += 1;
            };

            // Append replacement text
            let mut k = 0;
            while k < replacement.len() {
                result.append_byte(replacement.at(k).unwrap());
                k += 1;
            };

            last_end = end;
            i += 1;
        };

        // Copy remaining text
        let mut j = last_end;
        while j < text_len {
            result.append_byte(text.clone().at(j).unwrap());
            j += 1;
        };

        result
    }
}

/// Internal helper trait for regex matching
trait RegexHelperTrait {
    /// Match a pattern starting from a specific position
    ///
    /// # Arguments
    /// * `text` - The input text to match against
    /// * `text_pos` - The position in the text to start matching
    /// * `pattern_pos` - The position in the pattern to start matching
    ///
    /// # Returns
    /// `Option<(usize, usize)>` - End position in text and pattern if matched, or None
    fn _match(
        ref self: Regex, text: ByteArray, text_pos: usize, pattern_pos: usize,
    ) -> Option<(usize, usize)>;
}

impl RegexHelperImpl of RegexHelperTrait {
    fn _match(
        ref self: Regex, text: ByteArray, text_pos: usize, pattern_pos: usize,
    ) -> Option<(usize, usize)> {
        // Successful match - reached end of pattern
        if pattern_pos >= self.pattern.len() {
            return Option::Some((text_pos, pattern_pos));
        }

        // Get current token
        let current_token = *self.pattern.at(pattern_pos);

        // Check if at end of text
        let at_end_of_text = text_pos >= text.clone().len();

        match current_token {
            Token::Literal(c) => {
                // Can't match literal at end of text
                if at_end_of_text {
                    return Option::None;
                }

                let current_char = text.at(text_pos).unwrap();

                if c == current_char.into() {
                    return self._match(text.clone(), text_pos + 1, pattern_pos + 1);
                } else {
                    // Check for zero-match quantifiers
                    if is_next_token_zero_quantifier(@self.pattern, pattern_pos) {
                        // Skip both the current token and its quantifier
                        return self._match(text.clone(), text_pos, pattern_pos + 2);
                    }
                }
            },
            Token::Wildcard => {
                // Can't match wildcard at end of text
                if at_end_of_text {
                    return Option::None;
                }

                return self._match(text.clone(), text_pos + 1, pattern_pos + 1);
            },
            Token::CharClass((
                start, end,
            )) => {
                // Can't match character class at end of text
                if at_end_of_text {
                    return Option::None;
                }

                let current_char: u8 = text.at(text_pos).unwrap().try_into().unwrap();
                if _is_in_range(current_char, start.try_into().unwrap(), end.try_into().unwrap()) {
                    return self._match(text.clone(), text_pos + 1, pattern_pos + 1);
                } else {
                    // Check for zero-match quantifiers
                    if is_next_token_zero_quantifier(@self.pattern, pattern_pos) {
                        // Skip both the current token and its quantifier
                        return self._match(text.clone(), text_pos, pattern_pos + 2);
                    }
                }
            },
            Token::ZeroOrOne => {
                if pattern_pos > 0 {
                    let prev_token = *self.pattern.at(pattern_pos - 1);

                    // First try skipping (0 case)
                    let skip_result = self._match(text.clone(), text_pos, pattern_pos + 1);
                    if skip_result.is_some() {
                        return skip_result;
                    }

                    // Then try matching (1 case) if not at end of text
                    if !at_end_of_text {
                        let current_char = text.at(text_pos).unwrap();
                        if _match_token(prev_token, current_char.into()) {
                            return self._match(text.clone(), text_pos + 1, pattern_pos + 1);
                        }
                    }
                }
            },
            Token::OneOrMore => {
                if pattern_pos > 0 {
                    let prev_token = *self.pattern.at(pattern_pos - 1);

                    // Must match at least once
                    if at_end_of_text {
                        return self._match(text.clone(), text_pos, pattern_pos + 1);
                    }

                    let current_char = text.at(text_pos).unwrap();
                    if _match_token(prev_token, current_char.into()) {
                        // Try to match more occurrences
                        let match_more = self._match(text.clone(), text_pos + 1, pattern_pos);
                        if match_more.is_some() {
                            return match_more;
                        }

                        // Otherwise, move to next token
                        return self._match(text.clone(), text_pos + 1, pattern_pos + 1);
                    } else {
                        // Try continuing with the next token
                        return self._match(text.clone(), text_pos, pattern_pos + 1);
                    }
                }
            },
            Token::ZeroOrMore => {
                if pattern_pos > 0 {
                    let prev_token = *self.pattern.at(pattern_pos - 1);

                    // First try skipping (0 case)
                    let skip_result = self._match(text.clone(), text_pos, pattern_pos + 1);
                    if skip_result.is_some() {
                        return skip_result;
                    }

                    // Then try matching multiple (more case) if not at end of text
                    if !at_end_of_text {
                        let current_char = text.at(text_pos).unwrap();
                        if _match_token(prev_token, current_char.into()) {
                            return self._match(text.clone(), text_pos + 1, pattern_pos);
                        }
                    }
                }
            },
        }

        Option::None
    }
}

/// Check if a character matches a token
///
/// # Arguments
/// * `token` - The token to match against
/// * `char` - The character to check
///
/// # Returns
/// `true` if the character matches the token, `false` otherwise
fn _match_token(token: Token, char: felt252) -> bool {
    match token {
        Token::Literal(c) => c == char,
        Token::Wildcard => true,
        Token::CharClass((
            start, end,
        )) => _is_in_range(
            char.try_into().unwrap(), start.try_into().unwrap(), end.try_into().unwrap(),
        ),
        _ => false // Quantifiers themselves don't match characters
    }
}

/// Check if a character is within a range
///
/// # Arguments
/// * `char` - The character to check
/// * `start` - The start of the range (inclusive)
/// * `end` - The end of the range (inclusive)
///
/// # Returns
/// `true` if the character is within the range, `false` otherwise
fn _is_in_range(char: u8, start: u8, end: u8) -> bool {
    char >= start && char <= end
}

/// Check if the next token is a quantifier that allows zero matches
///
/// # Arguments
/// * `pattern` - The token pattern array
/// * `current_pos` - The current position in the pattern
///
/// # Returns
/// `true` if the next token is a zero-match quantifier, `false` otherwise
fn is_next_token_zero_quantifier(pattern: @Array<Token>, current_pos: usize) -> bool {
    // Check if there is a next token
    if current_pos + 1 >= pattern.len() {
        return false;
    }

    // Get the next token
    let next_token = *pattern.at(current_pos + 1);

    // Check if it's a quantifier that allows zero matches
    match next_token {
        Token::ZeroOrOne => true,
        Token::ZeroOrMore => true,
        _ => false // OneOrMore requires at least one match
    }
}
