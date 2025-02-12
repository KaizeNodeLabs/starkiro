use core::byte_array::ByteArray;

/// A string type
#[derive(Drop, Clone)]
pub struct String {
    pub data: ByteArray,
}

pub trait StringTrait {
    /// Create a new string
    fn new() -> String;
    /// Get the length of the string
    fn len(self: @String) -> usize;
    /// Concatenate two strings
    fn concatenate(ref self: String, other: @String);
    /// Check if a string starts with a prefix
    fn starts_with(self: @String, prefix: @String) -> bool;
    /// Check if a string ends with a suffix
    fn ends_with(self: @String, suffix: @String) -> bool;
}

impl StringImpl of StringTrait {
    /// Create a new string
    /// Returns:
    /// - A new string
    fn new() -> String {
        String { data: Default::default() }
    }

    /// Get the length of the string
    /// Arguments:
    /// - self: The string to get the length of
    /// Returns:
    /// - The length of the string
    fn len(self: @String) -> usize {
        self.data.len()
    }

    /// Concatenate two strings
    /// Arguments:
    /// - self: The string to concatenate to
    /// - other: The string to concatenate
    fn concatenate(ref self: String, other: @String) {
        self.data.append(other.data);
    }

    /// Check if a string starts with a prefix
    /// Arguments:
    /// - self: The string to check
    /// - prefix: The prefix to check for
    /// Returns:
    /// - true if the string starts with the prefix, false otherwise
    fn starts_with(self: @String, prefix: @String) -> bool {
        // If prefix is longer than string, return false
        if prefix.len() > self.len() {
            return false;
        }

        let mut i: usize = 0;
        loop {
            if i >= prefix.len() {
                break true;
            }

            match (self.data.at(i), prefix.data.at(i)) {
                (Option::Some(a), Option::Some(b)) => { if a != b {
                    break false;
                } },
                (_, _) => { break false; },
            }

            i += 1;
        }
    }

    /// Check if a string ends with a suffix
    /// Arguments:
    /// - self: The string to check
    /// - suffix: The suffix to check for
    /// Returns:
    /// - true if the string ends with the suffix, false otherwise
    fn ends_with(self: @String, suffix: @String) -> bool {
        // If suffix is longer than string, return false
        if suffix.len() > self.len() {
            return false;
        }

        let start_pos = self.len() - suffix.len();
        let mut i: usize = 0;

        loop {
            if i >= suffix.len() {
                break true;
            }

            match (self.data.at(start_pos + i), suffix.data.at(i)) {
                (Option::Some(a), Option::Some(b)) => { if a != b {
                    break false;
                } },
                (_, _) => { break false; },
            }

            i += 1;
        }
    }
}

