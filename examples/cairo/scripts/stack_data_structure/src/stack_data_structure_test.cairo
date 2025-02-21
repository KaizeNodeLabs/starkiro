mod tests {
    use core::dict::Felt252Dict;
    use core::nullable::{Nullable, NullableTrait};
    use crate::stack_data_structure::{MemoryVec, MemoryVecImpl, MemoryVecTrait};


    #[test]
    fn test_memory_vec() {
        // Create a new MemoryVec instance
        let mut vec: MemoryVec<felt252> = MemoryVec { data: Default::default(), len: 0, };

        // Verificar longitud inicial
        assert_eq!(vec.len(), 0, "Vector should be empty initially");

        // Operaciones de push
        vec.push(10.into());
        assert_eq!(vec.len(), 1, "Vector length after first push is incorrect");

        vec.push(20.into());
        assert_eq!(vec.len(), 2, "Vector length after second push is incorrect");

        vec.push(30.into());
        assert_eq!(vec.len(), 3, "Vector length after third push is incorrect");

        assert_eq!(vec.get(0).unwrap(), 10.into(), "First element is incorrect");
        assert_eq!(vec.get(1).unwrap(), 20.into(), "Second element is incorrect");
        assert_eq!(vec.get(2).unwrap(), 30.into(), "Third element is incorrect");

        assert_eq!(vec.len(), 3, "Wrong number of elements");

        vec.set(1, 25.into());
        assert_eq!(vec.get(1).unwrap(), 25.into(), "Updated element is incorrect");

        assert_eq!(vec.peek().unwrap(), 30.into(), "Last element should be 30");

        assert_eq!(vec.pop().unwrap(), 30.into(), "Last element should be 30");
        assert_eq!(vec.len(), 2, "Wrong number of elements after pop");

        assert_eq!(vec.get(0).unwrap(), 10.into(), "First element is incorrect");
        assert_eq!(vec.get(1).unwrap(), 25.into(), "Second element is incorrect");

        vec.pop();
        vec.pop();
        assert!(vec.is_empty(), "Vector should be empty");

        assert!(vec.pop().is_none(), "Pop on empty vector should return None");

    }
}

