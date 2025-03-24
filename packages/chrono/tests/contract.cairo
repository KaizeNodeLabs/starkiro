use chrono::prelude::*;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_block_timestamp_global,
};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IChronoContract<TContractState> {
    fn now(self: @TContractState) -> DateTime;
    fn is_leap(self: @TContractState, year: u32) -> bool;
    fn set_date(ref self: TContractState, date: DateTime);
    fn get_date(self: @TContractState) -> DateTime;
}

#[starknet::contract]
mod ChronoContract {
    use chrono::prelude::*;
    use starknet::get_block_timestamp;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    pub struct Storage {
        date: DateTime,
    }

    #[abi(embed_v0)]
    impl ChronoContractImpl of super::IChronoContract<ContractState> {
        fn now(self: @ContractState) -> DateTime {
            DateTimeTrait::from_block_timestamp(get_block_timestamp()).unwrap()
        }

        fn is_leap(self: @ContractState, year: u32) -> bool {
            DateTrait::from_ymd_opt(year, 1, 1).unwrap().leap_year()
        }

        fn set_date(ref self: ContractState, date: DateTime) {
            self.date.write(date);
        }

        fn get_date(self: @ContractState) -> DateTime {
            self.date.read()
        }
    }
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_contract() {
    let contract_address = deploy_contract("ChronoContract");
    let dispatcher = IChronoContractDispatcher { contract_address };

    assert_eq!(format!("{}", dispatcher.now()), "1970-01-01 00:00:00");
    start_cheat_block_timestamp_global(1707868800);
    assert_eq!(format!("{}", dispatcher.now()), "2024-02-14 00:00:00");

    assert_eq!(dispatcher.is_leap(1600), true);
    assert_eq!(dispatcher.is_leap(1700), false);
    assert_eq!(dispatcher.is_leap(1800), false);
    assert_eq!(dispatcher.is_leap(1900), false);
    assert_eq!(dispatcher.is_leap(2000), true);
    assert_eq!(dispatcher.is_leap(2024), true);

    dispatcher.set_date(dispatcher.now());
    assert_eq!(format!("{}", dispatcher.get_date()), "2024-02-14 00:00:00");
}
