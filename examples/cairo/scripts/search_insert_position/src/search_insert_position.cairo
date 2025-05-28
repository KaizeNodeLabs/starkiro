/// Finds the index of `target` in a sorted array `nums`.
/// If `target` is not present, returns the index where it would be inserted.
///
/// # Arguments
///
/// * `nums` - A sorted array of distinct integers
/// * `target` - The value to search for
///
/// # Returns
///
/// * The index of `target` in `nums` if found, or the index where it would be inserted
pub fn search_insert_pos(nums: @Array<u32>, target: u32) -> u32 {
    if nums.len() == 0 {
        return 0; // Empty array case
    }

    let mut left: u32 = 0;
    let mut right: u32 = nums.len();

    // Binary search with a more efficient condition
    while left != right {
        let mid = left + (right - left) / 2;

        if *nums.at(mid) < target {
            left = mid + 1; // Search in right half
        } else {
            right = mid; // Search in left half or target found
        }
    }
    left
}
