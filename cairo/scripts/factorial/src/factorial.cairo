fn factorial(mut n: u128) -> u128 {
    // The factorial of 0 is 1
    if n == 0 {
        return 1;
    }
    
    let mut result: u128 = 1;
    while n > 0 {
        result = result * n;
        n -= 1;
    };
    result
}

fn main() {
    let mut n: u128 = 8;
    let result = factorial(n);
    println!("factorial of {n} is {result}");
}