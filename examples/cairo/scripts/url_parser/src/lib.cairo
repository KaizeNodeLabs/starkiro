use core::array::ArrayTrait;
use core::option::OptionTrait;
use core::traits::Into;
use core::clone::Clone;

mod string_utils;

#[derive(Drop, Clone)]
pub struct URL {
    protocol: felt252,
    domain: felt252,
    path: felt252,
    query: felt252,
    fragment: felt252,
}

pub trait URLParserTrait {
    fn parse_url(url: felt252) -> URL;
    fn extract_protocol(url: felt252) -> felt252;
    fn extract_domain(url: felt252) -> felt252;
    fn extract_path(url: felt252) -> felt252;
    fn extract_query(url: felt252) -> felt252;
    fn extract_fragment(url: felt252) -> felt252;
}

impl URLParser of URLParserTrait {
    fn parse_url(url: felt252) -> URL {
        URL {
            protocol: Self::extract_protocol(url),
            domain: Self::extract_domain(url),
            path: Self::extract_path(url),
            query: Self::extract_query(url),
            fragment: Self::extract_fragment(url)
        }
    }

    fn extract_protocol(url: felt252) -> felt252 {
        let (protocol, remaining) = string_utils::split_string(url, '://');
        if remaining == 0 {
            return 'http';
        }
        protocol
    }

    fn extract_domain(url: felt252) -> felt252 {
        let (_, after_protocol) = string_utils::split_string(url, '://');
        if after_protocol == 0 {
            // No protocol found, treat entire URL as domain until first slash
            let (domain, _) = string_utils::split_string(url, '/');
            return domain;
        }
        
        // Extract domain from the remaining URL
        let (domain, _) = string_utils::split_string(after_protocol, '/');
        if domain == 0 {
            return after_protocol;
        }
        
        // Remove query string if present
        let (domain_no_query, _) = string_utils::split_string(domain, '?');
        if domain_no_query == 0 {
            return domain;
        }
        
        // Remove fragment if present
        let (final_domain, _) = string_utils::split_string(domain_no_query, '#');
        if final_domain == 0 {
            return domain_no_query;
        }
        
        final_domain
    }

    fn extract_path(url: felt252) -> felt252 {
        // First split on protocol
        let (_, after_protocol) = string_utils::split_string(url, '://');
        let url_to_check = if after_protocol == 0 { url } else { after_protocol };
        
        // Split by '/' first
        let (_, after_slash) = string_utils::split_string(url_to_check, '/');
        if after_slash == 0 {
            return '/';
        }
        
        // Get just the path part (before ? or #)
        let mut path = after_slash;
        
        // Remove query part if exists
        let (before_query, _) = string_utils::split_string(path, '?');
        if before_query != 0 {
            path = before_query;
        }
        
        // Remove fragment part if exists
        let (before_fragment, _) = string_utils::split_string(path, '#');
        if before_fragment != 0 {
            path = before_fragment;
        }
        
        // Return with leading slash
        if path == 0 {
            return '/';
        }
        
        let path_with_slash = '/';
        path_with_slash + path
    }

    fn extract_query(url: felt252) -> felt252 {
        let (_, after_query) = string_utils::split_string(url, '?');
        if after_query == 0 {
            return 0;
        }
        
        let (query, _) = string_utils::split_string(after_query, '#');
        query
    }

    fn extract_fragment(url: felt252) -> felt252 {
        let (_, fragment) = string_utils::split_string(url, '#');
        fragment
    }
} 