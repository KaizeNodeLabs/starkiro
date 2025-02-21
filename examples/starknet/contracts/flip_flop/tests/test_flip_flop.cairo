use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use flipflop::FlipFlop::{IFlipFlopDispatcher, IFlipFlopDispatcherTrait};

fn deploy_flip_flop() -> (IFlipFlopDispatcher, ContractAddress) {
    let contract = declare("FlipFlop").unwrap().contract_class();
    let calldata = array![];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IFlipFlopDispatcher { contract_address };
    (dispatcher, contract_address)
}

#[test]
fn test_initial_state() {
    let (flip_flop, _) = deploy_flip_flop();
    assert_eq!(flip_flop.get_state(), false);
}

#[test]
fn test_toggle_state() {
    let (flip_flop, _) = deploy_flip_flop();
    flip_flop.toggle_state();
    assert_eq!(flip_flop.get_state(), true);
    flip_flop.toggle_state();
    assert_eq!(flip_flop.get_state(), false);
}