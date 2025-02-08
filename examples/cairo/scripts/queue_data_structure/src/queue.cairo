use core::dict::Felt252Dict;
use core::nullable::{NullableTrait};

pub trait QueueTrait<V, T> {
    /// Creates and returns a new empty queue
    fn new() -> V;

    /// Adds a value to the back of the queue
    /// # Arguments
    /// * `value` - The element to be added to the queue
    fn enqueue(ref self: V, value: T);

    /// Removes and returns the element at the front of the queue
    /// # Returns
    /// * `Option<T>` - Some(value) if queue is not empty, None if queue is empty
    fn dequeue(ref self: V) -> Option<T>;

    /// Returns the element at the front of the queue without removing it
    /// # Returns
    /// * `Option<T>` - Some(value) if queue is not empty, None if queue is empty
    fn front(ref self: V) -> Option<T>;

    /// Returns the current number of elements in the queue
    /// # Returns
    /// * `usize` - The number of elements currently in the queue
    fn size(self: @V) -> usize;

    /// Checks if the queue is empty
    /// # Returns
    /// * `bool` - true if the queue is empty, false otherwise
    fn is_empty(self: @V) -> bool;
}

/// Queue implementation using a Felt252Dict as the underlying storage.
/// This implementation uses a dictionary with numeric keys to store elements,
/// maintaining front and back pointers for queue operations.
///
/// # Generic Parameters
/// * `T` - The type of elements stored in the queue
pub struct Queue<T> {
    /// Dictionary storing the queue elements
    pub data: Felt252Dict<Nullable<T>>,
    /// Index of the front element
    pub front: usize,
    /// Index where the next element will be inserted
    pub back: usize,
}

pub impl DestructQueue<T, +Drop<T>> of Destruct<Queue<T>> {
    fn destruct(self: Queue<T>) nopanic {
        self.data.squash();
    }
}

pub impl QueueImpl<T, +Drop<T>, +Copy<T>> of QueueTrait<Queue<T>, T> {
    /// Creates a new empty queue with default dictionary storage
    fn new() -> Queue<T> {
        Queue { data: Default::default(), front: 0, back: 0 }
    }

    /// Adds an element to the back of the queue
    /// Advances the back pointer when an element is enqueued
    fn enqueue(ref self: Queue<T>, value: T) {
        self.data.insert(self.back.into(), NullableTrait::new(value));
        self.back += 1;
    }

    /// Removes and returns the front element
    /// Advances the front pointer when an element is dequeued
    fn dequeue(ref self: Queue<T>) -> Option<T> {
        if self.is_empty() {
            return Option::None;
        }
        let value = self.data.get(self.front.into()).deref();
        self.front += 1;
        Option::Some(value)
    }

    /// Returns the front element without removing it
    fn front(ref self: Queue<T>) -> Option<T> {
        if self.is_empty() {
            return Option::None;
        }
        Option::Some(self.data.get(self.front.into()).deref())
    }

    /// Calculates the current size of the queue
    fn size(self: @Queue<T>) -> usize {
        *self.back - *self.front
    }

    /// Checks if the queue is empty
    fn is_empty(self: @Queue<T>) -> bool {
        self.size() == 0
    }
}
