use core::array::ArrayTrait;

/// Removes duplicates from a sorted array and returns the number of unique elements.
///
/// # Arguments
/// * `ref nums` - A reference to the sorted array of integers to be modified
///
/// # Returns
/// * The number of unique elements in the array
///
/// # Cairo-specific considerations
/// Since Cairo arrays are immutable by design, this implementation simulates
/// in-place modification by creating a new array of unique elements and then
/// replacing the original array's content with these unique elements.
pub fn remove_duplicate(ref nums: Array<u32>) -> u32 {
    if nums.len() == 0 {
        return 0;
    }

    let mut unique_elements: Array<u32> = ArrayTrait::new();

    unique_elements.append(*nums.at(0));

    let mut i: u32 = 1;
    while i < nums.len() {
        if *nums.at(i) != *unique_elements.at(unique_elements.len() - 1) {
            unique_elements.append(*nums.at(i));
        }
        i += 1;
    }

    let unique_count = unique_elements.len();

    // Create a new empty array and replace nums with the unique elements
    // This is a workaround since we can't directly modify the original array in Cairo
    let mut result: Array<u32> = ArrayTrait::new();

    let mut j: u32 = 0;
    while j < unique_elements.len() {
        result.append(*unique_elements.at(j));
        j += 1;
    }

    loop {
        match nums.pop_front() {
            Option::Some(_) => {},
            Option::None => { break; },
        };
    }

    let mut k: u32 = 0;
    while k < result.len() {
        nums.append(*result.at(k));
        k += 1;
    }

    unique_count
}

/// An alternative implementation that might be more gas-efficient
/// but doesn't simulate true in-place modification as in traditional languages.
pub fn remove_duplicates_optimized(ref nums: Array<u32>) -> u32 {
    if nums.len() == 0 {
        return 0;
    }

    let mut result: Array<u32> = ArrayTrait::new();
    result.append(*nums.at(0));

    let mut i: u32 = 1;
    while i < nums.len() {
        if *nums.at(i) != *result.at(result.len() - 1) {
            result.append(*nums.at(i));
        }
        i += 1;
    }

    let unique_count = result.len();

    loop {
        match nums.pop_front() {
            Option::Some(_) => {},
            Option::None => { break; },
        };
    }

    let mut j: u32 = 0;
    while j < result.len() {
        nums.append(*result.at(j));
        j += 1;
    }

    unique_count
}
