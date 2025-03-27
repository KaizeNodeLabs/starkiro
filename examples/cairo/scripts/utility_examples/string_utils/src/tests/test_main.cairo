#[cfg(test)]
mod test_main {
    use string_utility::string_utility::{String, StringTrait};


    #[test]
    fn test_new_and_len() {
        let message: ByteArray = "Hello, Cairo!";
        let s: String = StringTrait::new(message);
        assert!(s.len() == 13, "Expected length 13, got {}", s.len());
    }

    #[test]
    fn test_concatenation() {
        let hello: ByteArray = "Hello";
        let world: ByteArray = ", World!";
        let mut greet: String = StringTrait::new(hello);
        let name: String = StringTrait::new(world);
        greet.concatenate(@name);
        assert!(greet.data == "Hello, World!", "Concatenation failed, got: {}", greet.data);
    }

    #[test]
    fn test_prefix_suffix() {
        let text: ByteArray = "Cairo is awesome";
        let prefix: ByteArray = "Cairo";
        let suffix: ByteArray = "awesome";
        let text: String = StringTrait::new(text);
        let prefix: String = StringTrait::new(prefix);
        let suffix: String = StringTrait::new(suffix);
        assert!(text.starts_with(@prefix), "starts_with failed");
        assert!(text.ends_with(@suffix), "ends_with failed");
    }

    #[test]
    fn test_case_conversion() {
        let mixedCase: ByteArray = "MiXeD CaSe";
        let mix: String = StringTrait::new(mixedCase);
        let lower: String = mix.to_lowercase();
        let upper: String = mix.to_uppercase();
        assert!(lower.data == "mixed case", "to_lowercase failed, got: {}", lower.data);
        assert!(upper.data == "MIXED CASE", "to_uppercase failed, got: {}", upper.data);
    }

    #[test]
    fn test_trim() {
        let trim_me: ByteArray = "   Trim me!   ";
        let with_spaces: String = StringTrait::new(trim_me);
        let trimmed: String = with_spaces.trim();
        assert!(trimmed.data == "Trim me!", "trim failed, got: {}", trimmed.data);
    }

    #[test]
    fn test_substring() {
        let phrase: ByteArray = "Extract this part";
        let phrase: String = StringTrait::new(phrase);
        let sub: String = phrase.substring(8, 12);
        // "Extract this part" indices 8 to 11 yield "this"
        assert!(sub.data == "this", "substring failed, got: {}", sub.data);
    }

    #[test]
    fn test_replace() {
        let old_tree: ByteArray = "The old tree is old.";
        let old: ByteArray = "old";
        let majestic: ByteArray = "majestic";
        let sentence: String = StringTrait::new(old_tree);
        let replaced: String = sentence.replace(old, majestic);
        // Expected: "The majestic tree is majestic."
        assert!(
            replaced.data == "The majestic tree is majestic.",
            "replace failed, got: {}",
            replaced.data,
        );
    }

    #[test]
    fn test_contains() {
        let content: ByteArray = "This string contains a secret";
        let pattern: ByteArray = "secret";
        let content: String = StringTrait::new(content);
        let pattern: String = StringTrait::new(pattern);
        assert!(content.contains(pattern), "contains failed");
    }
}
