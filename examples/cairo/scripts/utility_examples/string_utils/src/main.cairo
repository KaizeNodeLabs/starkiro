use core::byte_array::ByteArray;
use string_utility::string_utility::{String, StringTrait};

fn main() {
    // Example 1: Create a new string and display its length.
    println!("== Example 1: new & len ==");
    let message: ByteArray = "Hello, Cairo!";
    let s: String = StringTrait::new(message);

    println!("String:");
    println!("{}", s.data);
    println!("Length:");
    println!("{}", s.len());

    // Example 2: Concatenation
    println!("== Example 2: Concatenation ==");
    let hello: ByteArray = "Hello";
    let world: ByteArray = ", World!";
    let mut greet: String = StringTrait::new(hello);
    let name: String = StringTrait::new(world);
    greet.concatenate(@name);
    println!("Concatenated string:");
    println!("{}", greet.data);

    // Example 3: Check prefix and suffix
    println!("== Example 3: starts_with & ends_with ==");
    let text: ByteArray = "Cairo is awesome";
    let prefix: ByteArray = "Cairo";
    let suffix: ByteArray = "awesome";
    let text: String = StringTrait::new(text);
    let prefix: String = StringTrait::new(prefix);
    let suffix: String = StringTrait::new(suffix);
    println!("Starts with 'Cairo':");
    println!("{}", text.starts_with(@prefix));
    println!("Ends with 'awesome':");
    println!("{}", text.ends_with(@suffix));

    // Example 4: Case conversion
    println!("== Example 4: to_lowercase & to_uppercase ==");
    let mixedCase: ByteArray = "MiXeD CaSe";
    let mix: String = StringTrait::new(mixedCase);
    let lower: String = mix.to_lowercase();
    let upper: String = mix.to_uppercase();
    println!("Original:");
    println!("{}", mix.data);
    println!("Lowercase:");
    println!("{}", lower.data);
    println!("Uppercase:");
    println!("{}", upper.data);

    // Example 5: Trim whitespace
    println!("== Example 5: trim ==");
    let trim_me: ByteArray = "   Trim me!   ";
    let with_spaces: String = StringTrait::new(trim_me);
    let trimmed: String = with_spaces.trim();
    println!("Before trim:");
    println!("{}", with_spaces.data);
    println!("After trim:");
    println!("{}", trimmed.data);

    // Example 6: Substring extraction
    println!("== Example 6: substring ==");
    let phrase: ByteArray = "Extract this part";
    let phrase: String = StringTrait::new(phrase);
    let sub: String = phrase.substring(8, 12);
    println!("Extracted substring:");
    println!("{}", sub.data);

    // Example 7: Replace substring
    println!("== Example 7: replace ==");
    let old_tree: ByteArray = "The old tree is old.";
    let old: ByteArray = "old";
    let majestic: ByteArray = "majestic";
    let sentence: String = StringTrait::new(old_tree);
    let replaced: String = sentence.replace(old, majestic);
    println!("After replace:");
    println!("{}", replaced.data);

    // Example 8: Check if string contains a pattern
    println!("== Example 8: contains ==");
    let content: ByteArray = "This string contains a secret";
    let pattern: ByteArray = "secret";
    let content: String = StringTrait::new(content);
    let pattern: String = StringTrait::new(pattern);
    println!("Contains 'secret':");
    println!("{}", content.contains(pattern));

    // Example 9: Email format validation using EmailValidator
    // println!("== Example 9: Email Validation ==");
    // let email = StringTrait::new(("user@example.com": ByteArray).into());
    // let bad_email = StringTrait::new(("user@domain": ByteArray).into());
    // let validator = EmailValidatorImpl::new();
    // println!("Email:");
    // println!("{}", email.data);
    // println!("Valid (basic):");
    // println!("{}", validator.validate_email(@email));
    // println!("Email (bad):");
    // println!("{}", bad_email.data);
    // println!("Valid (basic):");
    // println!("{}", validator.validate_email(@bad_email));

    println!("== End of Examples ==");
}
