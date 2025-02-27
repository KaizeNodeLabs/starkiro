// Custom Set implementation in Cairo
// A generic data structure that maintains unique elements

#[derive(Copy, Drop)]
pub struct Node<T> {
    pub value: T,
    pub left: NodePtr<T>,
    pub right: NodePtr<T>,
}

type NodePtr<T> = Option<Box<Node<T>>>;

#[derive(Copy, Drop)]
pub struct CustomSet<T> {
    root: NodePtr<T>,
    size: u32,
}

#[generate_trait]
pub impl CustomSetImpl<T, +PartialOrd<T>, +PartialEq<T>, +Copy<T>, +Drop<T>> of CustomSetTrait<T> {
    // Create a new empty set
    fn new() -> CustomSet<T> {
        CustomSet { root: Option::None, size: 0 }
    }

    // Create a new set from an array of elements
    fn from_array(elements: @Array<T>) -> CustomSet<T> {
        let mut set = CustomSetTrait::new();
        let mut i = 0;
        let len = elements.len();

        while i < len {
            set.add(*elements.at(i));
            i += 1;
        };

        set
    }

    // Add an element to the set if it doesn't already exist
    fn add(ref self: CustomSet<T>, value: T) -> bool {
        if self.contains(value) {
            return false; // Element already exists
        }

        self.root = self.root.insert(value);
        self.size += 1;
        true
    }

    // Check if the set contains a specific element
    fn contains(self: @CustomSet<T>, value: T) -> bool {
        !(*self.root).search(value).is_none()
    }

    // Check if the set is empty
    fn is_empty(self: @CustomSet<T>) -> bool {
        (*self.root).is_none()
    }

    // Get the size of the set
    fn len(self: @CustomSet<T>) -> u32 {
        *self.size
    }

    // Check if this set is a subset of another set
    fn is_subset(self: @CustomSet<T>, other: @CustomSet<T>) -> bool {
        // If self is empty, it's always a subset
        if (*self.root).is_none() {
            return true;
        }

        // If self has more elements than other, it can't be a subset
        if *self.size > *other.size {
            return false;
        }

        // Convert self to an array and check if each element exists in other
        let elements = self.to_array();
        let mut i = 0;
        let len = elements.len();

        while i < len {
            if !other.contains(*elements.at(i)) {
                false;
            }
            i += 1;
        };

        true
    }

    // Check if this set is disjoint with another set (no common elements)
    fn is_disjoint(self: @CustomSet<T>, other: @CustomSet<T>) -> bool {
        // If either set is empty, they are disjoint
        if (*self.root).is_none() || (*other.root).is_none() {
            return true;
        }

        // Check if any element in self exists in other
        let elements = self.to_array();
        let mut i = 0;
        let len = elements.len();

        let mut has_common = false;

        while i < len {
            if other.contains(*elements.at(i)) {
                has_common = true;
                break;
            }
            i += 1;
        };

        !has_common
    }

    // Create a new set with elements common to both sets
    fn intersection(self: @CustomSet<T>, other: @CustomSet<T>) -> CustomSet<T> {
        let mut result = CustomSetTrait::new();

        // If either set is empty, the intersection is empty
        if (*self.root).is_none() || (*other.root).is_none() {
            return result;
        }

        // Add elements from self that also exist in other
        let elements = self.to_array();
        let mut i = 0;
        let len = elements.len();

        while i < len {
            let current_element = *elements.at(i);
            if other.contains(current_element) {
                result.add(current_element);
            }
            i += 1;
        };

        result
    }

    // Create a new set with elements in self but not in other
    fn difference(self: @CustomSet<T>, other: @CustomSet<T>) -> CustomSet<T> {
        let mut result = CustomSetTrait::new();

        // If self is empty, the difference is empty
        if (*self.root).is_none() {
            return result;
        }

        // If other is empty, the difference is self
        if (*other.root).is_none() {
            return self.copy();
        }

        // Add elements from self that don't exist in other
        let elements = self.to_array();
        let mut i = 0;
        let len = elements.len();

        while i < len {
            let current_element = *elements.at(i);
            if !other.contains(current_element) {
                result.add(current_element);
            }
            i += 1;
        };

        result
    }

    // Create a new set with elements from both sets
    fn union(self: @CustomSet<T>, other: @CustomSet<T>) -> CustomSet<T> {
        let mut result = self.copy();

        // If other is empty, return a copy of self
        if (*other.root).is_none() {
            return result;
        }

        // Add all elements from other to result
        let elements = other.to_array();
        let mut i = 0;
        let len = elements.len();

        while i < len {
            let current_element = *elements.at(i);
            result.add(current_element);
            i += 1;
        };

        result
    }

    // Create a copy of the current set
    fn copy(self: @CustomSet<T>) -> CustomSet<T> {
        let mut result = CustomSetTrait::new();

        // If self is empty, return an empty set
        if (*self.root).is_none() {
            return result;
        }

        // Add all elements from self to result
        let elements = self.to_array();
        let mut i = 0;
        let len = elements.len();

        while i < len {
            let current_element = *elements.at(i);
            result.add(current_element);
            i += 1;
        };

        result
    }

    // Convert the set to an array
    fn to_array(self: @CustomSet<T>) -> @Array<T> {
        let mut result = ArrayTrait::new();
        self.in_order_traversal(*self.root, ref result);
        @result
    }

    // Helper function for in-order traversal
    fn in_order_traversal(self: @CustomSet<T>, node: NodePtr<T>, ref result: Array<T>) {
        match node {
            Option::None => {},
            Option::Some(n) => {
                self.in_order_traversal(n.left, ref result);
                result.append(n.value);
                self.in_order_traversal(n.right, ref result);
            },
        }
    }
}

// Tree operations for set implementation
#[generate_trait]
impl BinarySearchTreeImpl<
    T, +PartialOrd<T>, +PartialEq<T>, +Copy<T>, +Drop<T>,
> of BinarySearchTree<T> {
    fn insert(self: NodePtr<T>, value: T) -> NodePtr<T> {
        match self {
            Option::None => {
                Option::Some(BoxTrait::new(Node { value, left: Option::None, right: Option::None }))
            },
            Option::Some(node) => {
                if value < node.value {
                    Option::Some(
                        BoxTrait::new(
                            Node {
                                value: node.value, left: node.left.insert(value), right: node.right,
                            },
                        ),
                    )
                } else if value > node.value {
                    Option::Some(
                        BoxTrait::new(
                            Node {
                                value: node.value, left: node.left, right: node.right.insert(value),
                            },
                        ),
                    )
                } else {
                    // Value already exists, return unchanged
                    self
                }
            },
        }
    }

    fn search(self: @NodePtr<T>, target: T) -> NodePtr<T> {
        match self {
            Option::None => Option::None,
            Option::Some(node) => {
                if target < node.value {
                    node.left.search(target)
                } else if target > node.value {
                    node.right.search(target)
                } else {
                    *self
                }
            },
        }
    }
}
