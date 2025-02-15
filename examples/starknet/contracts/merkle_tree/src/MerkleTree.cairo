#[starknet::interface]
pub trait IMerkleTree<TContractState> {
    fn hash(ref self: TContractState, data: ByteArray) -> felt252;
    fn build_tree(ref self: TContractState, data: Array<ByteArray>) -> Array<felt252>;
    fn get_root(self: @TContractState) -> felt252;
    // fn verify(
//     self: @TContractState, proof: Array<felt252>, root: felt252, leaf: felt252, index: usize,
// ) -> bool;
}

mod errors {
    pub const NOT_PRESENT: felt252 = 'No element in merkle tree';
}

#[starknet::contract]
mod MerkleTree {
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use starknet::storage::{
        StoragePointerWriteAccess, StoragePointerReadAccess, Vec, MutableVecTrait, VecTrait,
    };

    #[storage]
    struct Storage {
        pub hashes: Vec<felt252>,
    }

    #[abi(embed_v0)]
    impl IMerkleTreeImpl of super::IMerkleTree<ContractState> {
        fn hash(ref self: ContractState, data: ByteArray) -> felt252 {
            let mut serialized_byte_arr: Array<felt252> = ArrayTrait::new();
            data.serialize(ref serialized_byte_arr);

            core::poseidon::poseidon_hash_span(serialized_byte_arr.span())
        }

        fn build_tree(ref self: ContractState, mut data: Array<ByteArray>) -> Array<felt252> {
            let data_len = data.len();
            let mut _hashes: Array<felt252> = ArrayTrait::new();
            let mut last_element = Option::None;

            if data_len > 0 && (data_len & (data_len - 1)) != 0 {
                last_element = Option::Some(data.at(data_len - 1).clone());
            };

            for value in data {
                _hashes.append(self.hash(value));
            };

            let mut current_nodes_lvl_len = data_len;
            let mut hashes_offset = 0;

            // if data_len is not a power of 2, add the last element to the hashes array
            match last_element {
                Option::Some(value) => {
                    _hashes.append(self.hash(value));
                    current_nodes_lvl_len += 1;
                },
                Option::None => {},
            };

            while current_nodes_lvl_len > 0 {
                let mut i = 0;
                while i < current_nodes_lvl_len - 1 {
                    let left_elem = *_hashes.at(hashes_offset + i);
                    let right_elem = *_hashes.at(hashes_offset + i + 1);

                    let hash = PoseidonTrait::new().update_with((left_elem, right_elem)).finalize();
                    _hashes.append(hash);

                    i += 2;
                };

                hashes_offset += current_nodes_lvl_len;
                current_nodes_lvl_len /= 2;
            };

            for hash in _hashes.span() {
                self.hashes.append().write(*hash);
            };

            _hashes
        }


        fn get_root(self: @ContractState) -> felt252 {
            let merkle_tree_length = self.hashes.len();
            assert(merkle_tree_length > 0, super::errors::NOT_PRESENT);

            self.hashes.at(merkle_tree_length - 1).read()
        }
    }
}
