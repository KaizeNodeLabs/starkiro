use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use simple_counter::simple_counter::{ISimpleCounterDispatcher, ISimpleCounterDispatcherTrait};

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    contract_address
}

#[test]
fn test_get_count() {
    let contract_address = deploy_contract("SimpleCounter");
    let dispatcher = ISimpleCounterDispatcher { contract_address };
    dispatcher.increase_count();
    assert!(dispatcher.get_count() == 1, "Wrong count");
}

#[test]
fn test_increase_count() {
    let contract_address = deploy_contract("SimpleCounter");
    let dispatcher = ISimpleCounterDispatcher { contract_address };
    dispatcher.increase_count();
    assert!(dispatcher.get_count() == 1, "Wrong count");
}

#[test]
fn test_decrease_count() {
    let contract_address = deploy_contract("SimpleCounter");
    let dispatcher = ISimpleCounterDispatcher { contract_address };
    dispatcher.increase_count();
    dispatcher.decrease_count();
    assert!(dispatcher.get_count() == 0, "Wrong count");
}