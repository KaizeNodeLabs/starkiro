// examples/cairo/scripts/remove_duplicate/tests/test_remove_duplicates.cairo

use core::array::ArrayTrait;
use remove_duplicates::remove_duplicates::{remove_duplicate, remove_duplicates_optimized};


#[test]
fn test_remove_duplicates_empty_array() {
    let mut nums: Array<u32> = ArrayTrait::new();
    let result = remove_duplicate(ref nums);
    assert(result == 0, 'Should return 0 for empty array');
}

#[test]
fn test_remove_duplicates_no_duplicates() {
    let mut nums: Array<u32> = ArrayTrait::new();
    nums.append(1);
    nums.append(2);
    nums.append(3);

    let result = remove_duplicate(ref nums);

    assert(result == 3, 'Should return 3 unique elements');
    assert(*nums.at(0) == 1, 'First element should be 1');
    assert(*nums.at(1) == 2, 'Second element should be 2');
    assert(*nums.at(2) == 3, 'Third element should be 3');
}

#[test]
fn test_remove_duplicates_example1() {
    // Example 1: nums = [1,1,2]
    let mut nums: Array<u32> = ArrayTrait::new();
    nums.append(1);
    nums.append(1);
    nums.append(2);

    let result = remove_duplicate(ref nums);

    assert(result == 2, 'Should return 2 unique elements');
    assert(*nums.at(0) == 1, 'First element should be 1');
    assert(*nums.at(1) == 2, 'Second element should be 2');
}

#[test]
fn test_remove_duplicates_example2() {
    // Example 2: nums = [0,0,1,1,1,2,2,3,3,4]
    let mut nums: Array<u32> = ArrayTrait::new();
    nums.append(0);
    nums.append(0);
    nums.append(1);
    nums.append(1);
    nums.append(1);
    nums.append(2);
    nums.append(2);
    nums.append(3);
    nums.append(3);
    nums.append(4);

    let result = remove_duplicate(ref nums);

    assert(result == 5, 'Should return 5 unique elements');
    assert(*nums.at(0) == 0, 'First element should be 0');
    assert(*nums.at(1) == 1, 'Second element should be 1');
    assert(*nums.at(2) == 2, 'Third element should be 2');
    assert(*nums.at(3) == 3, 'Fourth element should be 3');
    assert(*nums.at(4) == 4, 'Fifth element should be 4');
}

#[test]
fn test_remove_duplicates_all_duplicates() {
    let mut nums: Array<u32> = ArrayTrait::new();
    nums.append(1);
    nums.append(1);
    nums.append(1);
    nums.append(1);

    let result = remove_duplicate(ref nums);

    assert(result == 1, 'Should return 1 unique element');
    assert(*nums.at(0) == 1, 'First element should be 1');
}

// Tests for the optimized version
#[test]
fn test_remove_duplicates_optimized_example1() {
    // Example 1: nums = [1,1,2]
    let mut nums: Array<u32> = ArrayTrait::new();
    nums.append(1);
    nums.append(1);
    nums.append(2);

    let result = remove_duplicates_optimized(ref nums);

    assert(result == 2, 'Should return 2 unique elements');
    assert(*nums.at(0) == 1, 'First element should be 1');
    assert(*nums.at(1) == 2, 'Second element should be 2');
}

#[test]
fn test_remove_duplicates_optimized_example2() {
    // Example 2: nums = [0,0,1,1,1,2,2,3,3,4]
    let mut nums: Array<u32> = ArrayTrait::new();
    nums.append(0);
    nums.append(0);
    nums.append(1);
    nums.append(1);
    nums.append(1);
    nums.append(2);
    nums.append(2);
    nums.append(3);
    nums.append(3);
    nums.append(4);

    let result = remove_duplicates_optimized(ref nums);

    assert(result == 5, 'Should return 5 unique elements');
    assert(*nums.at(0) == 0, 'First element should be 0');
    assert(*nums.at(1) == 1, 'Second element should be 1');
    assert(*nums.at(2) == 2, 'Third element should be 2');
    assert(*nums.at(3) == 3, 'Fourth element should be 3');
    assert(*nums.at(4) == 4, 'Fifth element should be 4');
}
