use core::debug::PrintTrait;
use url_parser::URLParserTrait;
use url_parser::URL;

#[test]
fn test_url_parser() {
    let test_url = 'http://test.com/p?x=1#s';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    assert(parsed_url.protocol == 'http', 'Invalid protocol');
    assert(parsed_url.domain == 'test.com', 'Invalid domain');
    assert(parsed_url.path == 0x9f, 'Invalid path');
    assert(parsed_url.query == 'x=1', 'Invalid query');
    assert(parsed_url.fragment == 's', 'Invalid fragment');
}

#[test]
fn test_protocol_extraction() {
    let test_url = 'http://test.com';
    let protocol = URLParserTrait::extract_protocol(test_url);
    assert(protocol == 'http', 'Protocol extraction failed');
}

#[test]
fn test_domain_extraction() {
    let test_url = 'http://test.com';
    let domain = URLParserTrait::extract_domain(test_url);
    assert(domain == 'test.com', 'Domain extraction failed');
}

#[test]
fn test_full_url_parsing() {
    let test_url = 'http://a.com/b?c=1#d';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    assert(parsed_url.protocol == 'http', 'Protocol mismatch');
    assert(parsed_url.domain == 'a.com', 'Domain mismatch');
    assert(parsed_url.path == 0x91, 'Path mismatch');
    assert(parsed_url.query == 'c=1', 'Query mismatch');
    assert(parsed_url.fragment == 'd', 'Fragment mismatch');
}

#[test]
fn test_url_without_protocol() {
    let test_url = 'test.com/path#end';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    assert(parsed_url.protocol == 'http', 'Default protocol not set');
    assert(parsed_url.domain == 'test.com', 'Domain mismatch');
    assert(parsed_url.path == 0x70617497, 'Path mismatch');
    assert(parsed_url.fragment == 'end', 'Fragment mismatch');
}

#[test]
fn test_url_with_query_only() {
    let test_url = 'http://api.com?x=1';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    assert(parsed_url.protocol == 'http', 'Protocol mismatch');
    assert(parsed_url.query == 'x=1', 'Query mismatch');
    assert(parsed_url.path == '/', 'Default path not set');
}

#[test]
fn test_minimal_url() {
    let test_url = 'test.com';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    assert(parsed_url.protocol == 'http', 'Protocol mismatch');
    assert(parsed_url.domain == 'test.com', 'Domain mismatch');
    assert(parsed_url.path == '/', 'Path mismatch');
    assert(parsed_url.query == 0, 'Unexpected query');
    assert(parsed_url.fragment == 0, 'Unexpected fragment');
}

#[test]
fn test_url_parser_debug() {
    let test_url = 'http://test.com/p?x=1#s';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    // Print each component
    parsed_url.protocol.print();
    parsed_url.domain.print();
    parsed_url.path.print();
    parsed_url.query.print();
    parsed_url.fragment.print();
}

#[test]
fn test_url_without_protocol_debug() {
    let test_url = 'test.com/path#end';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    // Print each component
    parsed_url.protocol.print();
    parsed_url.domain.print();
    parsed_url.path.print();
    parsed_url.fragment.print();
}

#[test]
fn test_full_url_parsing_debug() {
    let test_url = 'http://a.com/b?c=1#d';
    let parsed_url = URLParserTrait::parse_url(test_url);
    
    // Print each component
    parsed_url.protocol.print();
    parsed_url.domain.print();
    parsed_url.path.print();
    parsed_url.query.print();
    parsed_url.fragment.print();
}


