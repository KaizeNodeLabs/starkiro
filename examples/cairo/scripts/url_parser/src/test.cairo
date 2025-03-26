use core::debug::PrintTrait;
use url_parser::URLParserTrait;

#[test]
fn test_url_parser() {
    let test_url = 'https://example.com/path?param=value#section1';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    assert(parsed_url.protocol == 'https', 'Invalid protocol');
    assert(parsed_url.domain == 'example.com', 'Invalid domain');
    assert(parsed_url.path == '/path', 'Invalid path');
    assert(parsed_url.query == 'param=value', 'Invalid query');
    assert(parsed_url.fragment == 'section1', 'Invalid fragment');
}

#[test]
fn test_protocol_extraction() {
    let test_url = 'https://example.com';
    let protocol = URLParserTrait::extract_protocol(test_url);
    assert(protocol == 'https', 'Protocol extraction failed');
}

#[test]
fn test_domain_extraction() {
    let test_url = 'https://example.com';
    let domain = URLParserTrait::extract_domain(test_url);
    assert(domain == 'example.com', 'Domain extraction failed');
} 