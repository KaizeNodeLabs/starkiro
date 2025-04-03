use core::array::ArrayTrait;
use core::option::OptionTrait;
use core::traits::{Into, TryInto};
use core::integer::{u256_from_felt252, U256TryIntoFelt252};

fn string_to_array(str: felt252) -> Array<felt252> {
    let mut result = ArrayTrait::new();
    
    if str == 0 {
        return result;
    }
    
    // Convert the string to bytes in reverse order
    let mut chars = ArrayTrait::new();
    let mut remaining = str;
    
    loop {
        // Convert to u256 for division
        let remaining_u256 = u256_from_felt252(remaining);
        let div_u256 = u256_from_felt252(256);
        
        // Perform division and get remainder
        let quotient = remaining_u256 / div_u256;
        let remainder = remaining_u256 - (quotient * div_u256);
        
        // Convert back to felt252
        let char: felt252 = remainder.try_into().unwrap();
        chars.append(char);
        remaining = quotient.try_into().unwrap();
        
        if remaining == 0 {
            break;
        }
    };
    
    // Reverse the array to get correct order
    let mut i = chars.len();
    loop {
        if i == 0 {
            break;
        }
        i -= 1;
        result.append(*chars.at(i));
    };
    
    result
}

fn find_substring(str: felt252, substr: felt252) -> u32 {
    if str == 0 || substr == 0 {
        return 0;
    }
    
    let str_arr = string_to_array(str);
    let substr_arr = string_to_array(substr);
    
    if substr_arr.len() == 0 || str_arr.len() < substr_arr.len() {
        return 0;
    }
    
    let mut i: u32 = 0;
    let max_i = str_arr.len() - substr_arr.len();
    
    loop {
        if i >= max_i.try_into().unwrap() {
            break;
        }
        
        let mut found = true;
        let mut j: u32 = 0;
        let max_j = substr_arr.len().try_into().unwrap();
        
        loop {
            if j >= max_j {
                break;
            }
            
            let str_char = *str_arr.at(i.try_into().unwrap() + j.try_into().unwrap());
            let substr_char = *substr_arr.at(j.try_into().unwrap());
            
            if str_char != substr_char {
                found = false;
                break;
            }
            j += 1;
        };
        
        if found {
            return i;
        }
        i += 1;
    };
    
    0
}

fn split_string(str: felt252, delimiter: felt252) -> (felt252, felt252) {
    if str == 0 || delimiter == 0 {
        return (str, 0);
    }
    
    let str_arr = string_to_array(str);
    let delimiter_arr = string_to_array(delimiter);
    
    let pos = find_substring(str, delimiter);
    if pos == 0 {
        return (str, 0);
    }
    
    let mut first = ArrayTrait::new();
    let mut second = ArrayTrait::new();
    
    let mut i: u32 = 0;
    let max_i = str_arr.len().try_into().unwrap();
    let delimiter_len: u32 = delimiter_arr.len().try_into().unwrap();
    
    loop {
        if i >= max_i {
            break;
        }
        
        if i < pos {
            first.append(*str_arr.at(i.try_into().unwrap()));
        } else if i >= pos + delimiter_len {
            second.append(*str_arr.at(i.try_into().unwrap()));
        }
        
        i += 1;
    };
    
    (array_to_string(first), array_to_string(second))
}

fn array_to_string(arr: Array<felt252>) -> felt252 {
    if arr.len() == 0 {
        return 0;
    }
    
    let mut result: felt252 = 0;
    let mut i = 0_usize;
    
    loop {
        if i >= arr.len() {
            break;
        }
        result = result * 256 + *arr.at(i);
        i += 1;
    };
    
    result
} 
