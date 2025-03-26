# URL Parser in Cairo

This module provides URL parsing functionality implemented in Cairo. It can parse URLs into their components including protocol, domain, path, query parameters, and fragment identifiers.

## Features

- Extract protocol (http, https, etc.)
- Extract domain and subdomains
- Extract path components
- Extract query parameters
- Extract fragment identifiers

## Usage

```cairo
use url_parser::URLParserTrait;

fn main() {
    let url = 'https://example.com/path?param=value#section1';
    let parsed_url = URLParserTrait::parse_url(url);

    // Access URL components
    let protocol = parsed_url.protocol; // 'https'
    let domain = parsed_url.domain;     // 'example.com'
    let path = parsed_url.path;         // '/path'
    let query = parsed_url.query;       // 'param=value'
    let fragment = parsed_url.fragment; // 'section1'
}
```

## Building and Testing

1. Navigate to the url_parser directory:

```bash
cd examples/cairo/scripts/url_parser
```

2. Build the project:

```bash
scarb build
```

3. Run the tests:

```bash
scarb test
```

## Implementation Details

The URL parser implements the following traits:

- `URLParserTrait`: Main trait containing all parsing functions
- `URL`: Struct containing parsed URL components

Each component is extracted using dedicated functions that handle different URL formats and edge cases.
