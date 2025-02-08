fn sum(number1: u128, number2: u128) -> u128 {
    number1 + number2
}

fn subtract(number1: u128, number2: u128) -> u128 {
    number1 - number2
}

fn multiply(number1: u128, number2: u128) -> u128 {
    number1 * number2
}

fn divide(number1: u128, number2: u128) -> u128 {
    assert(number2 != 0, 'Division by zero is not allowed');
    number1 / number2
}

fn modulus(number1: u128, number2: u128) -> u128 {
    assert(number2 != 0, 'Modulus by zero is not allowed');
    number1 % number2
}

fn pow(number: u128, pow: u128) -> u128 {
    let mut pow_number: u128 = 1;
    let mut index:u128 = 1;

    while index <= pow {
        pow_number *= number;
        index += 1;
    };

    pow_number
}

fn main() {
    let number1: u128 = 22;
    let number2: u128 = 7;

    println!("\nSum example:          {} + {} = {}\n", number1, number2, sum(number1, number2));
    println!("Subtract example:     {} - {} = {}\n", number1, number2, subtract(number1, number2));
    println!("Multiply example:     {} * {} = {}\n", number1, number2, multiply(number1, number2));
    println!(
        "Divide example:       {} / {} = {} (in Cairo, division returns only the integer part, without decimals)\n",
        number1,
        number2,
        divide(number1, number2)
    );
    println!("Modulus example:      {} % {} = {}\n", number1, number2, modulus(number1, number2));

    println!("Power example:        {} ^ {} = {}\n", number1, number2, pow(number1, number2));

}
