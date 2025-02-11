fn factorial(mut n: i128) -> i128 {
    // The factorial of 0 is 1
    if n == 0 {
        return 1;
    }
    
    let mut result: i128 = 1;
    while n > 0 {
        result = result * n;
        n -= 1;
    };
    result
}

fn main() {
    let mut n: i128 = -8;
    if n < 0 {
        println!("Error: Factorial is not defined for negative numbers ({n})");
        return;
    }
    let result = factorial(n);
    println!("factorial of {n} is {result}");
}
