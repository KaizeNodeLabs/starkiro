fn sum_elements(array: Array<u128>) -> u128 {
    let mut total_sum : u128 = 0;

    for num in array {
        total_sum += num;
    };

    total_sum
}


fn main() {
    let array: Array<u128> = array![1, 2, 3, 4, 5];

    println!("sum array elements example:      {} \n", sum_elements(array));
}
