#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use sorting::merge_sort::MergeSort;
    use sorting::interface::Sortable;

    #[test]
    fn test_empty_array() {
        let empty: Array<u32> = array![];
        let result = MergeSort::sort(empty.span());
        assert!(result.len() == 0, "Empty array test failed");
    }

    #[test]
    fn test_single_element() {
        let single = array![42_u32];
        let result = MergeSort::sort(single.span());
        assert!(result.len() == 1 && *result[0] == 42_u32, "Single element test failed");
    }

    #[test]
    fn test_even_length_array() {
        let arr = array![4_u32, 2_u32, 3_u32, 1_u32];
        let result = MergeSort::sort(arr.span());
        assert!(
            result.len() == 4
                && *result[0] == 1_u32
                && *result[1] == 2_u32
                && *result[2] == 3_u32
                && *result[3] == 4_u32,
            "Even length array test failed",
        );
    }

    #[test]
    fn test_odd_length_array() {
        let arr = array![5_u32, 3_u32, 1_u32, 4_u32, 2_u32];
        let result = MergeSort::sort(arr.span());
        assert!(
            result.len() == 5
                && *result[0] == 1_u32
                && *result[1] == 2_u32
                && *result[2] == 3_u32
                && *result[3] == 4_u32
                && *result[4] == 5_u32,
            "Odd length array test failed",
        );
    }

    #[test]
    fn test_array_with_duplicates() {
        let arr = array![3_u32, 1_u32, 4_u32, 1_u32, 5_u32];
        let result = MergeSort::sort(arr.span());
        assert!(
            result.len() == 5
                && *result[0] == 1_u32
                && *result[1] == 1_u32
                && *result[2] == 3_u32
                && *result[3] == 4_u32
                && *result[4] == 5_u32,
            "Array with duplicates test failed",
        );
    }
}
