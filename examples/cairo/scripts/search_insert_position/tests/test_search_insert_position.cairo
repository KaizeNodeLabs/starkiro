use search_insert_position::search_insert_position::search_insert_pos;

#[test]
fn test_target_found() {
    let nums = array![1, 3, 5, 6];
    let target = 5;
    assert(search_insert_pos(@nums, target) == 2, 'Target 5 should be at index 2');
}

#[test]
fn test_target_not_found_middle() {
    let nums = array![1, 3, 5, 6];
    let target = 2;
    assert(search_insert_pos(@nums, target) == 1, 'Target 2 should insert at 1');
}

#[test]
fn test_target_smaller_than_all() {
    let nums = array![1, 3, 5, 6];
    let target = 0;
    assert(search_insert_pos(@nums, target) == 0, 'Target 0 should insert at 0');
}

#[test]
fn test_target_larger_than_all() {
    let nums = array![1, 3, 5, 6];
    let target = 7;
    assert(search_insert_pos(@nums, target) == 4, 'Target 7 should insert at 4');
}

#[test]
fn test_empty_array() {
    let nums = array![];
    let target = 5;
    assert(search_insert_pos(@nums, target) == 0, 'Empty array should return 0');
}

#[test]
fn test_single_element() {
    let nums = array![1];
    let target = 2;
    assert(search_insert_pos(@nums, target) == 1, 'Target 2 after single elem 1');
}

#[test]
fn test_single_element_found() {
    let nums = array![5];
    let target = 5;
    assert(search_insert_pos(@nums, target) == 0, 'Target 5 equals single elem');
}

#[test]
fn test_single_element_smaller() {
    let nums = array![5];
    let target = 3;
    assert(search_insert_pos(@nums, target) == 0, 'Target 3 before single elem 5');
}

#[test]
fn test_large_array() {
    let nums = array![1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21];
    let target = 10;
    assert(search_insert_pos(@nums, target) == 5, 'Target 10 in large array');
}

#[test]
fn test_edge_case_MAX() {
    // Testing with u32::max value
    let nums = array![1, 3, 5, 7];
    let target = 4294967295_u32; // u32::MAX
    assert(search_insert_pos(@nums, target) == 4, 'u32::MAX should insert at end');
}

#[test]
fn test_edge_case_MIN() {
    // Testing with u32::min value
    let nums = array![1, 3, 5, 7];
    let target = 0_u32; // u32::MIN
    assert(search_insert_pos(@nums, target) == 0, 'u32::MIN should insert at start');
}
