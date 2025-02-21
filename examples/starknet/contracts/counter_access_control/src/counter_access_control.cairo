use core::starknet::ContractAddress;

#[starknet::interface]
pub trait ICounterAccessControl<TContractState> {
    fn increase_counter(ref self: TContractState);
    fn decrease_counter(ref self: TContractState);
    fn get_counter(self: @TContractState) -> u32;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn add_new_owner(ref self: TContractState, new_owner: ContractAddress);
}

#[starknet::contract]
pub mod CounterAccessControl {
    use core::num::traits::Zero;
    use core::starknet::{ContractAddress, get_caller_address};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        counter: u32,
        owner: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState, _owner: ContractAddress) {
        assert(self.is_zero_address(_owner) == false, '0 address vulnerability');
        self.owner.write(_owner);
    }

    #[abi(embed_v0)]
    impl CounterAccessControlImpl of super::ICounterAccessControl<ContractState> {
        fn increase_counter(ref self: ContractState) {
            self.only_owner();
            self.counter.write(self.counter.read() + 1);
        }

        fn decrease_counter(ref self: ContractState) {
            self.only_owner();
            self.counter.write(self.counter.read() - 1);
        }

        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn add_new_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.only_owner();
            assert(self.is_zero_address(new_owner) == false, '0 address vulnerability');
            assert(self.get_owner() != new_owner, 'same owner');
            self.owner.write(new_owner);
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn only_owner(self: @ContractState) {
            let caller: ContractAddress = get_caller_address();
            let current_owner: ContractAddress = self.owner.read();

            assert(caller == current_owner, 'caller not owner');
        }

        fn is_zero_address(self: @ContractState, account: ContractAddress) -> bool {
            if account.is_zero() {
                return true;
            }
            return false;
        }
    }
}
