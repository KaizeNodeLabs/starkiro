use core::dict::Felt252Dict;
use core::num::traits::WrappingAdd;
use core::nullable::{NullableTrait};

pub trait MemoryVecTrait<V, T> {
    fn new() -> V;
    fn get(ref self: V, index: usize) -> Option<T>;
    fn at(ref self: V, index: usize) -> T;
    fn push(ref self: V, value: T) -> ();
    fn set(ref self: V, index: usize, value: T);
    fn len(self: @V) -> usize;
    fn peek(ref self: V) -> Option<T>;
    fn pop(ref self: V) -> Option<T>;
    fn is_empty(self: @V) -> bool;
}

pub struct MemoryVec<T> {
     pub data: Felt252Dict<Nullable<T>>,
     pub len: usize,
}

impl DestructMemoryVec<T, +Drop<T>> of Destruct<MemoryVec<T>> {
    fn destruct(self: MemoryVec<T>) nopanic {
        self.data.squash();
    }
}


pub impl MemoryVecImpl<T, +Drop<T>, +Copy<T>> of MemoryVecTrait<MemoryVec<T>, T> {
    fn new() -> MemoryVec<T> {
        MemoryVec { data: Default::default(), len: 0 }
    }


    fn get(ref self: MemoryVec<T>, index: usize) -> Option<T> {
        if index < self.len() {
            Option::Some(self.data.get(index.into()).deref())
        } else {
            Option::None
        }
    }

    fn at(ref self: MemoryVec<T>, index: usize) -> T {
        assert!(index < self.len(), "Index out of bounds");
        self.data.get(index.into()).deref()
    }

    fn push(ref self: MemoryVec<T>, value: T) -> () {
        self.data.insert(self.len.into(), NullableTrait::new(value));
        self.len += 1;
    }

    fn set(ref self: MemoryVec<T>, index: usize, value: T) {
        assert!(index < self.len(), "Index out of bounds");
        self.data.insert(index.into(), NullableTrait::new(value));
    }

    fn len(self: @MemoryVec<T>) -> usize {
        *self.len
    }

    fn peek(ref self: MemoryVec<T>) -> Option<T> {
        if self.is_empty() {
            return Option::None;
        }
        Option::Some(self.data.get((self.len - 1).into()).deref())
    }

    fn pop(ref self: MemoryVec<T>) -> Option<T> {
        if self.is_empty() {
            return Option::None;
        }
        self.len -= 1;
        Option::Some(self.data.get(self.len.into()).deref())
    }

    fn is_empty(self: @MemoryVec<T>) -> bool {
        *self.len == 0
    }
}


