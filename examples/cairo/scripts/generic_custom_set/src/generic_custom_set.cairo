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
    fn new() -> CustomSet<T> {
        CustomSet { root: Option::None, size: 0 }
    }

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

    fn add(ref self: CustomSet<T>, value: T) -> bool {
        if self.contains(value) {
            return false;
        }

        self.root = self.root.insert(value);
        self.size += 1;
        true
    }

    fn contains(self: @CustomSet<T>, value: T) -> bool {
        !(*self.root).search(value).is_none()
    }

    fn is_empty(self: @CustomSet<T>) -> bool {
        (*self.root).is_none()
    }

    fn len(self: @CustomSet<T>) -> u32 {
        *self.size
    }

    fn is_subset(self: @CustomSet<T>, other: @CustomSet<T>) -> bool {
        if (*self.root).is_none() {
            return true;
        }

        if *self.size > *other.size {
            return false;
        }

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

    fn is_disjoint(self: @CustomSet<T>, other: @CustomSet<T>) -> bool {
        if (*self.root).is_none() || (*other.root).is_none() {
            return true;
        }

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

    fn intersection(self: @CustomSet<T>, other: @CustomSet<T>) -> CustomSet<T> {
        let mut result = CustomSetTrait::new();

        if (*self.root).is_none() || (*other.root).is_none() {
            return result;
        }

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

    fn difference(self: @CustomSet<T>, other: @CustomSet<T>) -> CustomSet<T> {
        let mut result = CustomSetTrait::new();

        if (*self.root).is_none() {
            return result;
        }

        if (*other.root).is_none() {
            return self.copy();
        }

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

    fn union(self: @CustomSet<T>, other: @CustomSet<T>) -> CustomSet<T> {
        let mut result = self.copy();

        if (*other.root).is_none() {
            return result;
        }

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

    fn copy(self: @CustomSet<T>) -> CustomSet<T> {
        let mut result = CustomSetTrait::new();

        if (*self.root).is_none() {
            return result;
        }

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

    fn to_array(self: @CustomSet<T>) -> @Array<T> {
        let mut result = ArrayTrait::new();
        self.in_order_traversal(*self.root, ref result);
        @result
    }

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

impl PartialOrdFelt252 of PartialOrd<felt252> {
    fn lt(lhs: felt252, rhs: felt252) -> bool {
        lhs < rhs
    }

    fn le(lhs: felt252, rhs: felt252) -> bool {
        lhs <= rhs
    }

    fn gt(lhs: felt252, rhs: felt252) -> bool {
        lhs > rhs
    }

    fn ge(lhs: felt252, rhs: felt252) -> bool {
        lhs >= rhs
    }
}
