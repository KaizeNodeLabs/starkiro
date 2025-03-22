use core::array::ArrayTrait;
use super::*;
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

#[test]
fn test_two_sum_found() {
    let nums: Array<u128> = array![2, 7, 11, 15];
    let target: u128 = 9;
    assert_eq!(two_sum(nums, target), (0, 1));
}

#[test]
fn test_two_sum_not_found() {
    let nums: Array<u128> = array![1, 2, 3, 4];
    let target: u128 = 10;
    assert_eq!(two_sum(nums, target), (0, 0));
}


#[test]
fn test_two_sum_large_numbers() {
    let nums: Array<u128> = array![1000000000000000000, 2000000000000000000, 3000000000000000000];
    let target: u128 = 3000000000000000000;
    assert_eq!(two_sum(nums, target), (0, 1));
}

#[test]
fn test_two_sum_single_element() {
    let nums: Array<u128> = array![5];
    let target: u128 = 10;
    assert_eq!(two_sum(nums, target), (0, 0));
}

#[test]
fn test_two_sum_empty_array() {
    let nums: Array<u128> = array![];
    let target: u128 = 10;
    assert_eq!(two_sum(nums, target), (0, 0));
}

