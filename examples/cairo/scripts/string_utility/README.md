# String utility

**A Cairo library providing essential string manipulation functions**

## Prerequisites
Install [Scarb](https://docs.swmansion.com/scarb/) (we recommend using [asdf](https://asdf-vm.com/) version manager).

## Installation

In your project directory, run the following command to add the library as a dependency:

```sh
scarb add string_utility@0.1.0
```

Alternatively, you can manually add the dependency. In your Scarb.toml file, include:

```toml
[dependencies]
string_utility = "0.1.0"
```

## Usage

Import and use the library in your Cairo file:

```cairo
use string_utility::{StringTrait};
```

For a detailed example of how to integrate and use this library in a Cairo project, check the [examples](./examples) folder.
