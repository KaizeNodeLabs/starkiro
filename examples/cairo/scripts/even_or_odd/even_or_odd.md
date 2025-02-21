## Program to check if a number is even or odd number
The main purpose of the code base above is to demonstrate how to check if a number is even or odd using simple boolean logic in cairo programming language.

```
fn is_even(number: u32) -> bool {
    number % 2 == 0
}

fn is_odd(number: u32) -> bool {
    number % 2 != 0
}

fn main() {
    let number_1: u32 = 4;
    let number_2: u32 = 5;

    if is_even(number_1) {
    println!("is even!");
    }
    else {
     println!("is odd!");
    }

    if is_odd(number_2) {
    println!("is odd!");
    }
    else {
     println!("is even!");
    }
}

```
### Check for even number
```
fn is_even(number: u32) -> bool {
    number % 2 == 0
}

```
This defines a function named is_even that takes an integer parameter number of type u32 and returns a boolean value. The function checks if the input number is even by verifying if it's divisible by 2 without a remainder. 

`fn` is the keyword used to declare a function in Cairo 2. This is similar to many other programming languages. For more on functions: https://book.cairo-lang.org/ch02-03-functions.html#functions

`is_even` is the name of the function. Cairo uses snake_case for function names, which is the conventional style where all letters are lowercase and words are separated by underscores.

(number: u32) is the function parameter. It takes one parameter named number of type u32, which is an unsigned 32-bit integer. As variables are unsigned, they can't contain a negative number. For more on unsigned and signed integer: https://book.cairo-lang.org/ch02-02-data-types.html?highlight=unsigned%20integers#integer-types


-> bool: indicates that this function returns a boolean value (true or false). bool indicates a value to be true or false. For more on Bool: https://book.cairo-lang.org/ch02-02-data-types.html?highlight=bool#the-boolean-type   

In Cairo, function returns are handled in a unique way that doesn't rely on a specific 'return' keyword. For more on `return` keyword: https://book.cairo-lang.org/ch02-03-functions.html?highlight=return%20keyword#functions-with-return-values

The function body is contained within the curly braces {}

number % 2 == 0 is the actual logic of the function:

% is the modulo operator, which gives the remainder after division. For more on operator and assignment https://book.cairo-lang.org/appendix-02-operators-and-symbols.html?highlight=modulo%20operator#operators

number % 2 calculates the remainder when number is divided by 2.
`== 0` checks if this remainder is equal to zero. The `==` operator is used to check if two values are equal. For more on operator and assignment: https://book.cairo-lang.org/appendix-02-operators-and-symbols.html?highlight=modulo 
If the remainder is 0, the number is even, and the expression evaluates to `true`. Otherwise, it's `false`.

In Cairo, the last expression in a function is implicitly returned if there's no return keyword. So this function will return the result of number % 2 == 0

NOTE: There is no terminal semi-colon in `number % 2 == 0`. This is because this is an expression and not a statement. For more on expresss and statements: https://book.cairo-lang.org/ch02-03-functions.html?highlight=statements#statements-and-expressions

This function can be called from other parts of your Cairo program to determine if a given number is even or odd.


### check for odd number
```
fn is_odd(number: u32) -> bool {
    number % 2 != 0
}

```
This defines another function named is_odd that takes an integer parameter number of type u32 and returns a boolean value. It checks if the input number is odd by verifying if it's not divisible by 2 without a remainder.

`fn` is the keyword used to declare a function in Cairo. This is similar to many other programming languages. For more on functions: https://book.cairo-lang.org/ch02-03-functions.html#functions

`is_odd` is the name of the function. Cairo uses snake_case for function names, which is the conventional style where all letters are lowercase and words are separated by underscores.

(number: u32) is the function parameter. It takes one parameter named number of type u32, which is an unsigned 32-bit integer. As variables are unsigned, they can't contain a negative number. For more on unsigned and signed integer: https://book.cairo-lang.org/ch02-02-data-types.html?highlight=unsigned%20integers#integer-types

-> bool indicates that this function returns a boolean value (true or false). bool indicates a value to be true or false. For more on Bool: https://book.cairo-lang.org/ch02-02-data-types.html?highlight=bool#the-boolean-type   
In Cairo, function returns are handled in a unique way that doesn't rely on a specific 'return' keyword.
For more on `return` keyword: https://book.cairo-lang.org/ch02-03-functions.html?highlight=return%20keyword#functions-with-return-values

The function body is contained within the curly braces {}

number % 2 != 0 is the actual logic of the function:

`number % 2 != 0` is the return value, a bool. NOTE: There is no terminal semi-colon. This is because this is an expression and not a statement. For more on expresss and statements: https://book.cairo-lang.org/ch02-03-functions.html?highlight=statements#statements-and-expressions

% is the modulo operator, which gives the remainder after division. For more on operator and assignment https://book.cairo-lang.org/appendix-02-operators-and-symbols.html?highlight=modulo%20operator#operators

number % 2 calculates the remainder when number is divided by 2.
`!= 0` checks if this remainder is NOT equal to zero. The `!=` operator is used to check if two values are NOT equal. For more on operator and assignment https://book.cairo-lang.org/appendix-02-operators-and-symbols.html?highlight=modulo operator#operators
If the remainder is NOT 0, the number is odd number, and the expression evaluates to `true`. Otherwise, it's `false`.

In Cairo, the last expression in a function is implicitly returned if there's no return keyword. So this function will return the result of number % 2 != 0
NOTE: There is no terminal semi-colon in `number % 2 != 0`. This is because this is an expression and not a statement. For more on expresss and statements: https://book.cairo-lang.org/ch02-03-functions.html?highlight=statements#statements-and-expressions

This function can be called from other parts of your Cairo program to determine if a given number is even or odd.


### main 
```
fn main() {}

```
This line starts the main function, which is the entry point of the program. The main function is a special inbuilt function, it is always the first code that runs in every executable Cairo program. https://book.cairo-lang.org/ch01-02-hello-world.html 

## Declare two integer variables
```
let number_1: u32 = 4;
let number_2: u32 = 5;

```
These lines declare two integer variables, number_1 and number_2, both of type u32. They are initialized with values 4 and 5, respectively. The `let` is a Cairo keyword that binds the variable. For more on keywords: https://book.cairo-lang.org/appendix-01-keywords.html?highlight=let%20keyword#appendix-a---keywords.

NOTE: Integer variables are by default felt252 but is highly recommended to use the integer types instead of the felt252 type whenever possible, as the integer types come with added security features that provide extra protection against potential vulnerabilities in the code, such as overflow and underflow checks. Below are different types of Integer variants:

| Lenght   | Unsigned |
| -------- | -------- |
| 8 bit    | u8       |
| 16 bit   | u16      |
| 32 bit   | u32      |
| 64 bit   | u64      |
| 128 bit  | u128     |
| 256 bit  | u256     |
| 32 bit   | unsize   |

For more on Integer data types: https://book.cairo-lang.org/ch02-02-data-types.html


``` 
if is_even(number_1) {
    println!("is even!");
}
else {
     println!("is odd!");
}

```

This block uses the is_even function to check if number_1 is even. If true, it prints that number_1 is even; otherwise, it prints that number_1 is odd.
The code demonstrates the use of boolean expressions and conditional statements in cairo to determine whether numbers are even or odd. For more on conditional statements: https://book.cairo-lang.org/ch02-05-control-flow.html?highlight=conditional%20statements#using-if-in-a-let-statement

`println!("is even!");` The `println!` is an inbuilt function that prints out to the console. For more on printing: https://book.cairo-lang.org/ch11-08-printing.html

When this program is run the output in the console shows: is even!


