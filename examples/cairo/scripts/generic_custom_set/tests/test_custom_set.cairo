use generic_custom_set::generic_custom_set::CustomSet;
use generic_custom_set::generic_custom_set::CustomSetTrait;

#[test]
fn test_difference() {
    let mut set1: CustomSet<u32> = CustomSetTrait::new();
    set1.add(1_u32);
    set1.add(2_u32);
    set1.add(3_u32);

    let mut set2: CustomSet<u32> = CustomSetTrait::new();
    set2.add(2_u32);
    set2.add(4_u32);

    let difference = set1.difference(@set2);
    assert(difference.len() == 2, 'should have 2 elements');
    assert(difference.contains(1_u32), 'Difference should contain 1');
    assert(difference.contains(3_u32), 'Difference should contain 3');
    assert(!difference.contains(2_u32), 'Difference should not contain 2');
}

#[test]
fn test_union() {
    let mut set1: CustomSet<u32> = CustomSetTrait::new();
    set1.add(1_u32);
    set1.add(2_u32);

    let mut set2: CustomSet<u32> = CustomSetTrait::new();
    set2.add(2_u32);
    set2.add(3_u32);

    let union = set1.union(@set2);
    assert(union.len() == 3, 'Union should have 3 elements');
    assert(union.contains(1_u32), 'Union should contain 1');
    assert(union.contains(2_u32), 'Union should contain 2');
    assert(union.contains(3_u32), 'Union should contain 3');
}

#[test]
fn test_empty_sets() {
    let empty_set1: CustomSet<u32> = CustomSetTrait::new();
    let empty_set2: CustomSet<u32> = CustomSetTrait::new();

    assert(empty_set1.is_empty(), 'Set should be empty');
    assert(empty_set2.is_empty(), 'Set should be empty');
    assert(empty_set1.is_subset(@empty_set2), 'Empty subset of empty');
    assert(empty_set2.is_subset(@empty_set1), 'Empty subset of empty');
    assert(empty_set1.is_disjoint(@empty_set2), 'Empty disjoint with empty');

    let union = empty_set1.union(@empty_set2);
    assert(union.is_empty(), 'Union of empty sets is empty');

    let intersection = empty_set1.intersection(@empty_set2);
    assert(intersection.is_empty(), 'Intersect of emptysets is empty');

    let difference = empty_set1.difference(@empty_set2);
    assert(difference.is_empty(), 'empty sets is empty');
}

#[test]
fn test_large_set() {
    let mut large_set: CustomSet<u32> = CustomSetTrait::new();

    let mut i: u32 = 0;
    while i < 10 {
        assert(large_set.add(i), 'Should add element');
        i += 1;
    };

    assert(large_set.len() == 10, 'Should have 10 elements');

    let mut j: u32 = 0;
    while j < 10 {
        assert(large_set.contains(j), 'Should contain element');
        j += 1;
    };

    assert(!large_set.contains(10_u32), 'Should not contain 10');
    assert(!large_set.contains(100_u32), 'Should not contain 100');
}

#[test]
fn test_edge_elements() {
    let mut set: CustomSet<u32> = CustomSetTrait::new();

    set.add(0_u32);
    set.add(4294967295_u32);

    assert(set.len() == 2, 'Should have 2 elements');
    assert(set.contains(0_u32), 'Should contain min value');
    assert(set.contains(4294967295_u32), 'Should contain max value');
    assert(!set.contains(1_u32), 'Should not contain 1');
}

#[test]
fn test_copy_and_equality() {
    let mut original: CustomSet<u32> = CustomSetTrait::new();
    original.add(1_u32);
    original.add(2_u32);
    original.add(3_u32);

    let copy = original.copy();

    assert(copy.len() == 3, 'Copy should have 3 elements');
    assert(copy.contains(1_u32), 'Copy should contain 1');
    assert(copy.contains(2_u32), 'Copy should contain 2');
    assert(copy.contains(3_u32), 'Copy should contain 3');

    original.add(4_u32);
    assert(original.len() == 4, 'Original should have 4 elements');
    assert(copy.len() == 3, 'should still have 3 elements');
    assert(!copy.contains(4_u32), 'Copy should not contain 4');
}

#[test]
fn test_from_array_with_many_duplicates() {
    let mut arr = ArrayTrait::<u32>::new();
    arr.append(1_u32);
    arr.append(1_u32);
    arr.append(1_u32);
    arr.append(2_u32);
    arr.append(2_u32);
    arr.append(3_u32);

    let set = CustomSetTrait::from_array(@arr);

    assert(set.len() == 3, 'Set should have 3 elements');
    assert(set.contains(1_u32), 'Set should contain 1');
    assert(set.contains(2_u32), 'Set should contain 2');
    assert(set.contains(3_u32), 'Set should contain 3');
}
