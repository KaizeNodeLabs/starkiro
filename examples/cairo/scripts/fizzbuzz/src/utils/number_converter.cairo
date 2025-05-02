/// Converts a u32 integer to its string representation as felt252.
/// This function works for any u32 value, not just small numbers.
pub fn u32_to_felt252(mut num: u32) -> felt252 {
    // Handle 0 separately
    if num == 0 {
        return '0';
    }

    // For single-digit numbers (1-9), return the ASCII directly
    if num < 10 {
        return num.into() + '0';
    }

    // For multi-digit numbers, build the string from right to left
    let mut reversed_digits: Array<felt252> = ArrayTrait::new();

    loop {
        let digit = (num % 10).into() + '0';
        reversed_digits.append(digit);
        num /= 10;

        if num == 0 {
            break;
        }
    }

    // Convert the array of digits to a single felt252 string
    let mut result: felt252 = 0;

    // Start from the end (least significant digit) and build the number
    let len = reversed_digits.len();
    let mut i: usize = 0;
    while i != len {
        let index = len - i - 1;
        let digit = *reversed_digits.at(index);
        result = result * 256 + digit; // Shift left by 8 bits (1 byte) and add the next digit
        i += 1;
    }

    result
}
