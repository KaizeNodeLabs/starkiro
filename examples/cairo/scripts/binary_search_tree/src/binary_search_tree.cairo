type NodePtr<T> = Option<Box<Node<T>>>;

#[derive(Copy, Drop)]
pub struct Node<T> {
    pub value: T,
    pub left: NodePtr<T>,
    pub right: NodePtr<T>,
}

#[generate_trait]
pub impl BinarySearchTreeImpl<
    T, +PartialOrd<T>, +PartialEq<T>, +Copy<T>, +Drop<T>,
> of BinarySearchTree<T> {
    fn initialize() -> NodePtr<T> {
        Option::None
    }

    fn new(
        self: NodePtr<T>, value: T, left: NodePtr<T>, right: NodePtr<T>
    ) -> NodePtr<T> {
        Option::Some(BoxTrait::new(Node { value, left, right }))
    }

    fn insert(self: NodePtr<T>, value: T) -> NodePtr<T> {
        match self {
            Option::None => { self.new(value, Option::None, Option::None) },
            Option::Some(node) => {
                if value < node.value {
                    self.new(node.value, node.left.insert(value), node.right)
                } else if value > node.value {
                    self.new(node.value, node.left, node.right.insert(value))
                } else {
                    self
                }
            },
        }
    }

    fn search(self: @NodePtr<T>, target: T) -> NodePtr<T> {
        match self {
            Option::None => { Option::None },
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

    fn get_min(self: NodePtr<T>) -> NodePtr<T> {
        match self {
            Option::None => Option::None,
            Option::Some(node) => { if node.left.is_some() {
                node.left.get_min()
            } else {
                self
            } },
        }
    }

    fn get_max(self: NodePtr<T>) -> NodePtr<T> {
        match self {
            Option::None => Option::None,
            Option::Some(node) => {
                if node.right.is_some() {
                    node.right.get_max()
                } else {
                    self
                }
            },
        }
    }

    fn delete(self: NodePtr<T>, target: T) -> NodePtr<T> {
        match self {
            Option::None => { Option::None },
            Option::Some(node) => {
                if target < node.value {
                    self.new(node.value, node.left.delete(target), node.right)
                } else if target > node.value {
                    self.new(node.value, node.left, node.right.delete(target))
                } else {
                    if (node.left.is_none() && node.right.is_none()) {
                        Option::None
                    } else if (node.left.is_none()) {
                        node.right
                    } else if (node.right.is_none()) {
                        node.left
                    } else {
                        let successor = node.right.get_min();
                        let value = successor.unwrap().value;
                        self.new(value, node.left, node.right.delete(value))
                    }
                }
            },
        }
    }

    fn is_empty(self: @NodePtr<T>) -> bool {
        self.is_none()
    }
}