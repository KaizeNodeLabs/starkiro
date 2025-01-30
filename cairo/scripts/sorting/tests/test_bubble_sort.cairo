use core::array::ArrayTrait;
use sorting::bubble_sort::BubbleSort;

#[test]
fn test_empty_array() {
    let empty: Array<u32> = array![];
    let result = BubbleSort::sort(empty.span());
    assert!(result.len() == 0, "Empty array test failed");
}

#[test]
fn test_single_element() {
    let single = array![1_u32];
    let result = BubbleSort::sort(single.span());
    assert!(result.len() == 1 && *result[0] == 1_u32, "Single element test failed");
}

#[test]
fn test_unsorted_array() {
    let unsorted = array![3_u32, 1_u32, 4_u32, 1_u32, 5_u32];
    let result = BubbleSort::sort(unsorted.span());
    assert!(
        *result[0] == 1_u32
            && *result[1] == 1_u32
            && *result[2] == 3_u32
            && *result[3] == 4_u32
            && *result[4] == 5_u32,
        "Sorting test failed",
    );
}
