use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};

use counter_access_control::counter_access_control::{
    ICounterAccessControlDispatcher, ICounterAccessControlDispatcherTrait
};

pub mod Accounts {
    use starknet::ContractAddress;
    use core::traits::TryInto;

    pub fn zero() -> ContractAddress {
        0x0000000000000000000000000000000000000000.try_into().unwrap()
    }

    pub fn owner() -> ContractAddress {
        'owner'.try_into().unwrap()
    }

    pub fn account1() -> ContractAddress {
        'account1'.try_into().unwrap()
    }
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let mut constructor_calldata = array![Accounts::owner().into()];

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
fn test_get_counter_equals_to_zero() {
    let contract_address = deploy_contract("CounterAccessControl");

    let dispatcher = ICounterAccessControlDispatcher { contract_address };
    let current_counter = dispatcher.get_counter();
    assert!(current_counter == 0, "Counter must be zero!");
}

#[test]
fn test_increase_counter() {
    let contract_address = deploy_contract("CounterAccessControl");
    let owner = Accounts::owner();

    let dispatcher = ICounterAccessControlDispatcher { contract_address };
    start_cheat_caller_address(contract_address, owner);

    dispatcher.increase_counter();
    let current_counter = dispatcher.get_counter();

    assert!(current_counter == 1, "Counter must be one!");
}

#[test]
fn test_decrease_counter() {
    let contract_address = deploy_contract("CounterAccessControl");
    let owner = Accounts::owner();

    let dispatcher = ICounterAccessControlDispatcher { contract_address };
    start_cheat_caller_address(contract_address, owner);

    dispatcher.increase_counter();
    dispatcher.decrease_counter();

    let current_counter = dispatcher.get_counter();
    assert!(current_counter == 0, "Counter must be zero!");
}

#[test]
fn test_owner_was_set_correctly() {
    let contract_address = deploy_contract("CounterAccessControl");

    let dispatcher = ICounterAccessControlDispatcher { contract_address };
    let owner = dispatcher.get_owner();
    assert_eq!(owner, Accounts::owner());
}

#[test]
#[should_panic(expected: 'caller not owner')]
fn test_caller_is_not_the_owner() {
    let contract_address = deploy_contract("CounterAccessControl");
    let account1 = Accounts::account1();

    let dispatcher = ICounterAccessControlDispatcher { contract_address };
    start_cheat_caller_address(contract_address, account1);

    dispatcher.increase_counter();
}

#[test]
#[should_panic(expected: '0 address vulnerability')]
fn test_add_new_owner_should_panic_when_new_owner_is_zero_address() {
    let contract_address = deploy_contract("CounterAccessControl");
    let owner = Accounts::owner();
    let zero_address = Accounts::zero();

    let dispatcher = ICounterAccessControlDispatcher { contract_address };
    start_cheat_caller_address(contract_address, owner);

    dispatcher.add_new_owner(zero_address);
}

#[test]
#[should_panic(expected: 'same owner')]
fn test_add_new_owner_should_panic_when_new_owner_is_current_owner() {
    let contract_address = deploy_contract("CounterAccessControl");
    let owner = Accounts::owner();

    let dispatcher = ICounterAccessControlDispatcher { contract_address };
    start_cheat_caller_address(contract_address, owner);

    dispatcher.add_new_owner(owner);
}
