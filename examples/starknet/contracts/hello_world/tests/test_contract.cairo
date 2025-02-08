use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use hello_world::hello_world::{ISimpleHelloWorldDispatcher, ISimpleHelloWorldDispatcherTrait};

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    contract_address
}

#[test]
fn test_get_hello_world() {
    let contract_address = deploy_contract("SimpleHelloWorld");

    let dispatcher = ISimpleHelloWorldDispatcher { contract_address };
    dispatcher.set_hello_world();
    let result = dispatcher.get_hello_world();
    assert!(result == 'Hello world!', "Something went wrong :(");
}
