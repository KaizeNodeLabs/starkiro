# Regex

**A Cairo library providing a simplified regex engine supporting essential pattern matching features**

## Prerequisites
Install [Scarb](https://docs.swmansion.com/scarb/) (we recommend using [asdf](https://asdf-vm.com/) version manager).

## Installation

In your project directory, run the following command to add the library as a dependency:

```sh
scarb add regex@0.1.0
```

Alternatively, you can manually add the dependency. In your Scarb.toml file, include:

```toml
[dependencies]
regex = "0.1.0"
```

## Usage

Import and use the library in your Cairo file:

```cairo
use regex::RegexTrait;

fn main() {
    // Create a new Regex instance
    let mut pattern = RegexTrait::new("H.llo");

    // Sample text
    let text = "Hello, World!";

    // Check if the text matches the pattern
    let is_match = pattern.matches(text.into());

    println!("Match Found: {}", is_match);
}
```

For a detailed example of how to integrate and use this library in a Cairo project, check the [examples](./examples) folder.
