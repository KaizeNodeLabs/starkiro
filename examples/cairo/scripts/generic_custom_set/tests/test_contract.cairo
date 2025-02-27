// // tests/test_custom_set.cairo

// // use generic_custom_set::CustomSet;
// // use generic_custom_set::CustomSetTrait;
// use generic_custom_set::generic_custom_set::CustomSet;
// use generic_custom_set::generic_custom_set::CustomSetTrait;

// #[test]
// fn test_new_and_is_empty() {
//     let set: CustomSet<u32> = CustomSetTrait::new();
//     assert(set.is_empty(), 'New set should be empty');
//     assert(set.len() == 0, 'New set size should be 0');
// }

// #[test]
// fn test_add_and_contains() {
//     let mut set: CustomSet<u32> = CustomSetTrait::new();

//     // Add an element
//     assert(set.add(5), 'Adding should return true');
//     assert(!set.is_empty(), 'Set should not be empty');
//     assert(set.len() == 1, 'Set size should be 1');
//     assert(set.contains(5), 'Set should contain 5');

//     // Try to add a duplicate
//     assert(!set.add(5), 'Adding duplicate returns false');
//     assert(set.len() == 1, 'Size should still be 1');

//     // Add another element
//     assert(set.add(10), 'Adding should return true');
//     assert(set.len() == 2, 'Set size should be 2');
//     assert(set.contains(10), 'Set should contain 10');
//     assert(!set.contains(7), 'Set should not contain 7');
// }

// #[test]
// fn test_from_array() {
//     let mut arr = ArrayTrait::new();
//     arr.append(1);
//     arr.append(2);
//     arr.append(3);
//     arr.append(2); // Duplicate

//     let set = CustomSetTrait::from_array(@arr);
//     assert(set.len() == 3, 'Set should have 3 elements');
//     assert(set.contains(1), 'Set should contain 1');
//     assert(set.contains(2), 'Set should contain 2');
//     assert(set.contains(3), 'Set should contain 3');
// }

// #[test]
// fn test_is_subset() {
//     let mut set1 = CustomSetTrait::new();
//     set1.add(1);
//     set1.add(2);

//     let mut set2 = CustomSetTrait::new();
//     set2.add(1);
//     set2.add(2);
//     set2.add(3);

//     assert(set1.is_subset(@set2), 'set1 should be subset of set2');
//     assert(!set2.is_subset(@set1), 'set2 cant be subset of set1');

//     let empty_set: CustomSet<u32> = CustomSetTrait::new();
//     assert(empty_set.is_subset(@set1), 'Empty set is subset of any set');
// }

// #[test]
// fn test_is_disjoint() {
//     let mut set1 = CustomSetTrait::new();
//     set1.add(1);
//     set1.add(2);

//     let mut set2 = CustomSetTrait::new();
//     set2.add(3);
//     set2.add(4);

//     assert(set1.is_disjoint(@set2), 'Sets should be disjoint');

//     set2.add(2);
//     assert(!set1.is_disjoint(@set2), 'Sets should not be disjoint');

//     let empty_set: CustomSet<u32> = CustomSetTrait::new();
//     assert(empty_set.is_disjoint(@set1), 'Empty set disjoint with any set');
// }

// #[test]
// fn test_intersection() {
//     let mut set1 = CustomSetTrait::new();
//     set1.add(1);
//     set1.add(2);
//     set1.add(3);

//     let mut set2 = CustomSetTrait::new();
//     set2.add(2);
//     set2.add(3);
//     set2.add(4);

//     let intersection = set1.intersection(@set2);
//     assert(intersection.len() == 2, 'Intersection should have 2 elements');
//     assert(intersection.contains(2), 'Intersection should contain 2');
//     assert(intersection.contains(3), 'Intersection should contain 3');
//     assert(!intersection.contains(1), 'Intersection should not contain 1');
//     assert(!intersection.contains(4), 'Intersection should not contain 4');
// }

// #[test]
// fn test_difference() {
//     let mut set1 = CustomSetTrait::new();
//     set1.add(1);
//     set1.add(2);
//     set1.add(3);

//     let mut set2 = CustomSetTrait::new();
//     set2.add(2);
//     set2.add(4);

//     let difference = set1.difference(@set2);
//     assert(difference.len() == 2, 'Difference should have 2 elements');
//     assert(difference.contains(1), 'Difference should contain 1');
//     assert(difference.contains(3), 'Difference should contain 3');
//     assert(!difference.contains(2), 'Difference should not contain 2');
// }

// #[test]
// fn test_union() {
//     let mut set1 = CustomSetTrait::new();
//     set1.add(1);
//     set1.add(2);

//     let mut set2 = CustomSetTrait::new();
//     set2.add(2);
//     set2.add(3);

//     let union = set1.union(@set2);
//     assert(union.len() == 3, 'Union should have 3 elements');
//     assert(union.contains(1), 'Union should contain 1');
//     assert(union.contains(2), 'Union should contain 2');
//     assert(union.contains(3), 'Union should contain 3');
// }
