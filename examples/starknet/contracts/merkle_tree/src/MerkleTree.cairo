#[starknet::interface]
pub trait IMerkleTree<TContractState> {
    fn hash(ref self: TContractState, data: ByteArray) -> felt252;
    fn build_tree(ref self: TContractState, data: Array<ByteArray>) -> Array<felt252>;
    // fn get_root(self: @TContractState) -> felt252;
// fn verify(
//     self: @TContractState, proof: Array<felt252>, root: felt252, leaf: felt252, index: usize,
// ) -> bool;
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

            for value in data {
                _hashes.append(self.hash(value));
            };

            let mut current_nodes_lvl_len = data_len;
            let mut hashes_offset = 0;

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
    }
}
