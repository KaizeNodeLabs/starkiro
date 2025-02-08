#[starknet::interface]
pub trait IFlipFlop<TContractState> {
    fn get_state(self: @TContractState) -> bool;
    fn toggle_state(ref self: TContractState);
}

#[starknet::contract]
pub mod FlipFlop {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    
    #[storage]
    struct Storage {
        state: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.state.write(false); 
    }

    #[abi(embed_v0)]
    impl FlipFlop of super::IFlipFlop<ContractState> {
        // Get the current state
        fn get_state(self: @ContractState) -> bool {
            self.state.read()
        }

        // Toggle the state between true and false
        fn toggle_state(ref self: ContractState) {
            let current_state: bool = self.state.read();
            self.state.write(!current_state);
        }
    }
}