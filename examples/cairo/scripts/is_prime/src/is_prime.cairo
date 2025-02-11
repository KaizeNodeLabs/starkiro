/// Check if the given number is prime by checking divisibility up to n/2
/// # Arguments
/// * `n` - The number to check if it's prime
/// # Returns
/// * `true` if number is prime. Otherwise false
fn is_prime(n: u128) -> bool {
    // Handle edge cases
    if n <= 1 {
        return false;
    }
    if n <= 3 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }

    // Check odd divisors up to n/2
    let mut current_divider = 3;
    let half = n / 2;

    loop {
        if current_divider > half {
            break true;
        }
        if n % current_divider == 0 {
            break false;
        }
        current_divider += 2;
    }
}

fn check_primes(numbers: Array<u128>) {
    for n in numbers {
        println!("{}", n);
        if is_prime(n) {
            println!("is prime");
        } else {
            println!("is not prime");
        }
        println!("");
    }
}

fn main() {
    let numbers: Array<u128> = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 17, 19, 23, 97];
    check_primes(numbers);
}
