#[starknet::interface]
pub trait ISimpleHelloWorld<TContractState> {
    fn get_hello_world(self: @TContractState) -> felt252;
    fn set_hello_world(ref self: TContractState);
}

#[starknet::contract]
pub mod SimpleHelloWorld {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    #[storage]
    struct Storage {
        stored_data: felt252
    }

    #[abi(embed_v0)]
    impl SimpleHelloWorld of super::ISimpleHelloWorld<ContractState> {
        fn set_hello_world(ref self: ContractState) {
            self.stored_data.write('Hello world!')
        }

        fn get_hello_world(self: @ContractState) -> felt252 {
            self.stored_data.read()
        }
    }
}
