use core::byte_array::ByteArray;

/// A string type
#[derive(Drop, Clone)]
pub struct String {
    pub data: ByteArray,
}

pub trait StringTrait {
    /// Create a new string
    fn new(data: ByteArray) -> String;
    /// Get the length of the string
    fn len(self: @String) -> usize;
    /// Concatenate two strings
    fn concatenate(ref self: String, other: @String);
    /// Check if a string starts with a prefix
    fn starts_with(self: @String, prefix: @String) -> bool;
    /// Check if a string ends with a suffix
    fn ends_with(self: @String, suffix: @String) -> bool;
    /// Convert string to lowercase
    fn to_lowercase(self: @String) -> String;
    /// Convert string to uppercase
    fn to_uppercase(self: @String) -> String;
    /// Remove whitespace from start and end of string
    fn trim(self: @String) -> String;
    /// Get a portion of the string between start (inclusive) and end (exclusive) indices
    fn substring(self: @String, start: usize, end: usize) -> String;
    /// Replace all occurrences of target with replacement
    /// Generic types T and U must implement StringCompatible
    fn replace<T, +StringCompatible<T>, +Drop<T>, U, +StringCompatible<U>, +Drop<U>>(
        self: @String, target: T, replacement: U,
    ) -> String;
    /// Check if string contains a pattern
    /// Generic type T must implement StringCompatible
    fn contains<T, +StringCompatible<T>, +Drop<T>>(self: @String, pattern: T) -> bool;
}

/// Trait for types that can be used in string operations
pub trait StringCompatible<T> {
    fn to_bytes(self: T) -> ByteArray;
}

// Implement for String
impl StringCompatibleString of StringCompatible<String> {
    fn to_bytes(self: String) -> ByteArray {
        self.data.clone()
    }
}

// Implement for String Snapshot
// impl StringCompatibleStringSnap of StringCompatible<@String> {
//     fn to_bytes(self: @String) -> ByteArray {
//         self.data.clone()
//     }
// }

// Implement for ByteArray
impl StringCompatibleByteArray of StringCompatible<ByteArray> {
    fn to_bytes(self: ByteArray) -> ByteArray {
        self.clone()
    }
}

// Implement for ByteArray Snapshot
// impl StringCompatibleByteArraySnap of StringCompatible<@ByteArray> {
//     fn to_bytes(self: @ByteArray) -> ByteArray {
//         self.clone()
//     }
// }

impl StringImpl of StringTrait {
    /// Create a new string
    /// Arguments:
    /// - data: The data to create the string with
    /// Returns:
    /// - A new string
    fn new(data: ByteArray) -> String {
        String { data }
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

    /// Convert string to lowercase
    /// Arguments:
    /// - self: The string to convert
    /// Returns:
    /// - A new string with all alphabetic characters converted to lowercase
    fn to_lowercase(self: @String) -> String {
        let mut result: ByteArray = "";
        let mut i: usize = 0;

        loop {
            if i >= self.len() {
                break ();
            }

            // Get current byte
            match self.data.at(i) {
                Option::Some(byte) => {
                    // Check if byte is uppercase letter (ASCII 65-90)
                    if byte >= 65 && byte <= 90 {
                        // Convert to lowercase by adding 32
                        result.append_byte(byte + 32);
                    } else {
                        // Keep non-uppercase bytes unchanged
                        result.append_byte(byte);
                    }
                },
                Option::None => { break (); },
            }

            i += 1;
        };

        Self::new(result)
    }

    /// Convert string to uppercase
    /// Arguments:
    /// - self: The string to convert
    /// Returns:
    /// - A new string with all alphabetic characters converted to uppercase
    fn to_uppercase(self: @String) -> String {
        let mut result: ByteArray = "";
        let mut i: usize = 0;

        loop {
            if i >= self.len() {
                break ();
            }

            // Get current byte
            match self.data.at(i) {
                Option::Some(byte) => {
                    // Check if byte is lowercase letter (ASCII 97-122)
                    if byte >= 97 && byte <= 122 {
                        // Convert to uppercase by subtracting 32
                        result.append_byte(byte - 32);
                    } else {
                        // Keep non-lowercase bytes unchanged
                        result.append_byte(byte);
                    }
                },
                Option::None => { break (); },
            }

            i += 1;
        };

        Self::new(result)
    }

    /// Remove whitespace from start and end of string
    /// Arguments:
    /// - self: The string to trim
    /// Returns:
    /// - A new string with leading and trailing whitespace removed
    fn trim(self: @String) -> String {
        // Handle empty string
        if self.len() == 0 {
            return Self::new("");
        }

        let mut start: usize = 0;
        let mut end: usize = self.len();

        // Find first non-whitespace character
        loop {
            if start >= self.len() {
                break ();
            }

            match self.data.at(start) {
                Option::Some(byte) => {
                    // ASCII 32 is space, 9 is tab, 10 is newline, 13 is carriage return
                    if byte != 32 && byte != 9 && byte != 10 && byte != 13 {
                        break ();
                    }
                },
                Option::None => { break (); },
            }

            start += 1;
        };

        // If we reached the end, string is all whitespace
        if start == self.len() {
            return Self::new("");
        }

        // Find last non-whitespace character
        loop {
            if end == 0 {
                break ();
            }

            end -= 1;

            match self.data.at(end) {
                Option::Some(byte) => {
                    // ASCII 32 is space, 9 is tab, 10 is newline, 13 is carriage return
                    if byte != 32 && byte != 9 && byte != 10 && byte != 13 {
                        end += 1;
                        break ();
                    }
                },
                Option::None => { break (); },
            }
        };

        // Create new string with characters between start and end
        let mut result: ByteArray = "";
        let mut i = start;

        loop {
            if i >= end {
                break ();
            }

            match self.data.at(i) {
                Option::Some(byte) => { result.append_byte(byte); },
                Option::None => { break (); },
            }

            i += 1;
        };

        Self::new(result)
    }

    /// Get a portion of the string between start (inclusive) and end (exclusive) indices
    /// Arguments:
    /// - self: The source string
    /// - start: Starting index (inclusive)
    /// - end: Ending index (exclusive)
    /// Returns:
    /// - A new string containing the specified substring,
    ///   or empty string if indices are invalid
    fn substring(self: @String, start: usize, end: usize) -> String {
        // Validate indices
        if start >= self.len() || end > self.len() || start >= end {
            return Self::new("");
        }

        let mut result: ByteArray = "";
        let mut i = start;

        // Copy characters from start to end
        loop {
            if i >= end {
                break ();
            }

            match self.data.at(i) {
                Option::Some(byte) => { result.append_byte(byte); },
                Option::None => { break (); },
            }

            i += 1;
        };

        Self::new(result)
    }

    /// Replace all occurrences of target with replacement
    /// Generic types T and U must implement StringCompatible
    fn replace<T, +StringCompatible<T>, +Drop<T>, U, +StringCompatible<U>, +Drop<U>>(
        self: @String, target: T, replacement: U,
    ) -> String {
        let target_bytes = StringCompatible::to_bytes(target);
        let replacement_bytes = StringCompatible::to_bytes(replacement);

        // Handle empty cases
        if self.len() == 0 || target_bytes.len() == 0 {
            return Self::new(self.data.clone());
        }

        let mut result: ByteArray = "";
        let mut i: usize = 0;

        loop {
            if i >= self.len() {
                break ();
            }

            // Check for match at current position
            let mut is_match = true;
            let mut j: usize = 0;

            if i + target_bytes.len() > self.len() {
                is_match = false;
            } else {
                loop {
                    if j >= target_bytes.len() {
                        break ();
                    }

                    match (self.data.at(i + j), target_bytes.at(j)) {
                        (
                            Option::Some(a), Option::Some(b),
                        ) => { if a != b {
                            is_match = false;
                            break ();
                        } },
                        (_, _) => {
                            is_match = false;
                            break ();
                        },
                    }

                    j += 1;
                };
            }

            if is_match {
                // Append replacement
                let mut k: usize = 0;
                loop {
                    if k >= replacement_bytes.len() {
                        break ();
                    }

                    match replacement_bytes.at(k) {
                        Option::Some(byte) => { result.append_byte(byte); },
                        Option::None => { break (); },
                    }

                    k += 1;
                };

                i += target_bytes.len();
            } else {
                // Copy current character
                match self.data.at(i) {
                    Option::Some(byte) => { result.append_byte(byte); },
                    Option::None => { break (); },
                }
                i += 1;
            }
        };

        Self::new(result)
    }

    /// Check if string contains a pattern
    /// Generic type T must implement StringCompatible
    fn contains<T, +StringCompatible<T>, +Drop<T>>(self: @String, pattern: T) -> bool {
        let pattern_bytes = StringCompatible::to_bytes(pattern);

        // Handle empty string cases
        if pattern_bytes.len() == 0 {
            return self.len() == 0;
        }

        // Pattern longer than string cannot be contained
        if pattern_bytes.len() > self.len() {
            return false;
        }

        let mut i: usize = 0;

        loop {
            if i > self.len() - pattern_bytes.len() {
                break false;
            }

            let mut is_match = true;
            let mut j: usize = 0;

            loop {
                if j >= pattern_bytes.len() {
                    break ();
                }

                match (self.data.at(i + j), pattern_bytes.at(j)) {
                    (
                        Option::Some(a), Option::Some(b),
                    ) => { if a != b {
                        is_match = false;
                        break ();
                    } },
                    (_, _) => {
                        is_match = false;
                        break ();
                    },
                }

                j += 1;
            };

            if is_match {
                break true;
            }

            i += 1;
        }
    }
}

