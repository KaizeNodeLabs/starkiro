fn max(arr: @Array<u128>) -> u128 {
    // get the length of the array
    let array_length: usize = arr.len();

    if (array_length == 0) {
        // if the array is empty, return 0
        println!("The array is empty.");
        return 0;
    }

    // set the max to the first element of the array
    let mut max: u128 = *arr[0];

    // iterate through the array and compare each element with the max
    for i in 1..array_length {
        // if the current element is greater than the max, update the max
        if *arr[i] > max {
            max = *arr[i];
        }
    };
    
    // return the max
    max
}

fn main() {
    let array1: Array<u128> = array![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let array2: Array<u128> = array![10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    let array3: Array<u128> = array![];
    let array4: Array<u128> = array![10, 2, 3, 8, 0, 154, 2, 3, 4, 5];

    println!("\nMaximum Number of an Array example 1:          {}\n", max(@array1));
    println!("Maximum Number of an Array example 2:            {}\n", max(@array2));
    println!("Maximum Number of an Array example 3 (empty):    {}\n", max(@array3));
    println!("Maximum Number of an Array example 4:            {}\n", max(@array4));
}
