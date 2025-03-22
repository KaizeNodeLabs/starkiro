/// Finds two indices in the given array whose values sum up to the target.
///
/// # Arguments
/// * `nums` - An array of unsigned 128-bit integers.
/// * `target` - The target sum to find.
///
/// # Returns
/// * A tuple `(low, high)` where `low` and `high` are the indices of the two numbers.
/// * Returns `(0, 0)` if no valid pair is found.

pub fn two_sum(nums: Array<u128>, target: u128) -> (u32, u32) {
    let length = nums.len();
    let mut low = 0;
    let mut high = 0;

    for i in 0..length {
        for j in (i + 1)..length {
            let sum = *nums[i] + *nums[j];
            if sum == target {
                low = i;
                high = j;
            }
        }
    };
    (low, high)
}

fn main() {
    let nums: Array<u128> = array![2, 7, 11, 15];
    let target: u128 = 9;

    let (low, high) = two_sum(nums, target);

    if (low, high) != (0, 0) {
        println!("two Sum indices: ({}, {})", low, high);
    } else {
        println!("no solution found");
    }
}
