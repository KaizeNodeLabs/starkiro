use core::array::ArrayTrait;
use crate::utils::number_converter::u32_to_felt252;

/// Implementation of the classic FizzBuzz problem.
/// Takes a number n and returns an array of strings from 1 to n, where:
/// - Numbers divisible by 3 are replaced with "Fizz"
/// - Numbers divisible by 5 are replaced with "Buzz"
/// - Numbers divisible by both 3 and 5 are replaced with "FizzBuzz"
/// - Otherwise, the number itself is included as a string
pub fn fizzbuzz(n: u32) -> Array<felt252> {
    let mut result: Array<felt252> = ArrayTrait::new();
    let mut i: u32 = 1;

    loop {
        if i % 3 == 0 && i % 5 == 0 {
            result.append('FizzBuzz');
        } else if i % 3 == 0 {
            result.append('Fizz');
        } else if i % 5 == 0 {
            result.append('Buzz');
        } else {
            // Convert integer to string representation using our utility function
            result.append(u32_to_felt252(i));
        }

        i += 1;
        if i > n {
            break;
        }
    }
    result
}
