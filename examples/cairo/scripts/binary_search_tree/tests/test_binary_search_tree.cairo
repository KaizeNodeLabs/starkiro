use binary_search_tree::binary_search_tree::BinarySearchTree;

// Verifies that insertion builds the tree correctly
#[test]
fn test_insertion() {
    let mut bst = BinarySearchTree::<u32>::initialize();

    for value in array![10, 5, 20] {
        bst = bst.insert(value);
    };

    let root_node = bst.unwrap();
    assert!(root_node.value == 10, "Root node has an unexpected value");

    let left_node = root_node.left.unwrap();
    assert!(left_node.value == 5, "Left node has an unexpected value");

    let right_node = root_node.right.unwrap();
    assert!(right_node.value == 20, "Right node has an unexpected value");
}

// Ensures that searching returns the correct node or `None` for missing values
#[test]
fn test_search() {
    let mut bst = BinarySearchTree::<u32>::initialize();

    for value in array![50, 1, 40, 3, 10, 55, 20] {
        bst = bst.insert(value);
    };

    let node = bst.search(55).unwrap();
    assert!(node.value == 55, "Unexpected node value after search");

    let node = bst.search(100);
    assert!(node.is_empty(), "Tree should not contain a node for a non-existent value");
}

// Tests that `get_min` returns the smallest element and `get_max` returns the largest element
#[test]
fn test_get_min_max() {
    let mut bst = BinarySearchTree::<u32>::initialize();

    for value in array![50, 100, 10, 3, 1] {
        bst = bst.insert(value);
    };

    let node = bst.get_min().unwrap();
    assert!(node.value == 1, "Unexpected min value");

    let node = bst.get_max().unwrap();
    assert!(node.value == 100, "Unexpected max value");
}

// Validates that deleting a value properly restructures the tree
#[test]
fn test_delete() {
    let mut bst = BinarySearchTree::<u32>::initialize();

    for value in array![100, 4, 3] {
        bst = bst.insert(value);
    };

    bst = bst.delete(100);
    let node = bst.search(100);
    assert!(node.is_none(), "The value should have been deleted");

    let node = bst.unwrap();
    assert!(node.value == 4, "The tree wasn't properly restructured after deletion");
}

// Ensures that duplicate values are not inserted
#[test]
fn test_duplicate_values() {
    let mut bst = BinarySearchTree::<u32>::initialize();

    for value in array![10, 10] {
        bst = bst.insert(value);
    };

    bst = bst.delete(10);
    assert!(bst.is_empty(), "The BST should be empty after removing the only inserted value");
}