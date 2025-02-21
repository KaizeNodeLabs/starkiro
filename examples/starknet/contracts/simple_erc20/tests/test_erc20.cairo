use core::result::ResultTrait;
use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait,  start_cheat_caller_address, stop_cheat_caller_address,};

// Importing the IERC20Dispatcher and IERC20MintingAndBurningDispatcher traits
// Dispatcher allows us to call the contract functions
use openzeppelin::token::erc20::interface::IERC20Dispatcher;
use openzeppelin::token::erc20::interface::IERC20DispatcherTrait;

use erc20::{IERC20MintingAndBurningDispatcher, IERC20MintingAndBurningDispatcherTrait};

fn deploy_erc20(deployer: ContractAddress) -> (ContractAddress, IERC20Dispatcher, IERC20MintingAndBurningDispatcher) {
    // Declaring the contract class
    let contract_class = declare("MyToken").unwrap().contract_class();
    // Creating the data to send to the constructor, first specifying as a default value
    let mut data_to_constructor = Default::default();
    // Packing the data into the constructor
    Serde::serialize(@deployer, ref data_to_constructor);
    // Deploying the contract, and getting the address
    let (address, _) = contract_class.deploy(@data_to_constructor).unwrap();

    // Returning the address of the contract and the dispatchers
    return (address, IERC20Dispatcher { contract_address: address }, IERC20MintingAndBurningDispatcher { contract_address: address });
}

fn mint_tokens(
    contract: ContractAddress, dispatcher: IERC20MintingAndBurningDispatcher, deployer: ContractAddress, user: ContractAddress, amount: u256
) {
    // Implement minting tokens to user
    start_cheat_caller_address(contract, deployer);
    dispatcher.mint(user, amount);
    stop_cheat_caller_address(contract);
}

#[test]
fn test_mint_and_burn() {
    let deployer: ContractAddress = 123.try_into().unwrap();

    // Deploying the contract and getting the dispatchers
    let (erc20Address, erc20GeneralDispatch, erc20MintDispatch) = deploy_erc20(deployer);

    // Creating the addresses of the Marco and Daniel
    let marco: ContractAddress = 1.try_into().unwrap();
    let daniel: ContractAddress = 2.try_into().unwrap();

    // Mint 100 tokens to Marco and 200 to Daniel
    mint_tokens(erc20Address, erc20MintDispatch, deployer, marco, 100);
    mint_tokens(erc20Address, erc20MintDispatch, deployer, daniel, 200);

    // Make sure that both Daniel and Marco have the right balances
    assert(erc20GeneralDispatch.balance_of(marco) == 100, 'Marco should have 100 tokens');
    assert(erc20GeneralDispatch.balance_of(daniel) == 200, 'Daniel should have 200 tokens');

    // Burn 50 tokens from Marco
    start_cheat_caller_address(erc20Address, marco);
    erc20MintDispatch.burn(50);
    stop_cheat_caller_address(erc20Address);

    // Make sure that Marco has the right balances
    assert(erc20GeneralDispatch.balance_of(marco) == 50, 'Marco should have 50 tokens');
}

#[test]
fn test_transfer() {
    let deployer: ContractAddress = 123.try_into().unwrap();
    // Deploying the contract and getting the dispatchers
    let (erc20Address, erc20GeneralDispatch, erc20MintDispatch) = deploy_erc20(deployer);

    // Creating the addresses of the Marco and Daniel
    let marco: ContractAddress = 1.try_into().unwrap();
    let daniel: ContractAddress = 2.try_into().unwrap();

    // Minting tokens to Marco
    mint_tokens(erc20Address, erc20MintDispatch, deployer, marco, 100);

    // Transfer 50 tokens from Marco to Daniel
    start_cheat_caller_address(erc20Address, marco);
    erc20GeneralDispatch.transfer(daniel, 50);
    stop_cheat_caller_address(erc20Address);

    // Add asserts to check that the Marco and Daniel have the correct balance
    assert(erc20GeneralDispatch.balance_of(marco) == 50, 'Marco should have 50 tokens');
    assert(erc20GeneralDispatch.balance_of(daniel) == 50, 'Daniel should have 50 tokens');
}

#[test]
fn test_approve_and_transfer_from() {
    let deployer: ContractAddress = 123.try_into().unwrap();
    // Deploying the contract and getting the dispatchers
    let (erc20Address, erc20GeneralDispatch, erc20MintDispatch) = deploy_erc20(deployer);

    // Creating the addresses of the Marco and Daniel
    let marco: ContractAddress = 1.try_into().unwrap();
    let daniel: ContractAddress = 2.try_into().unwrap();

    // Minting tokens to Marco
    mint_tokens(erc20Address, erc20MintDispatch, deployer, marco, 100);

    // Approve Daniel to transfer 50 tokens from Marco
    start_cheat_caller_address(erc20Address, marco);
    erc20GeneralDispatch.approve(daniel, 50);
    stop_cheat_caller_address(erc20Address);

    // Transfer 50 tokens from Marco to Daniel but do not use transfer() function
    start_cheat_caller_address(erc20Address, daniel);
    erc20GeneralDispatch.transfer_from(marco, daniel, 50);
    stop_cheat_caller_address(erc20Address);

    // Add asserts to check that the Marco and Daniel have the right balance
    assert(erc20GeneralDispatch.balance_of(marco) == 50, 'Marco should have 50 tokens');
    assert(erc20GeneralDispatch.balance_of(daniel) == 50, 'Daniel should have 50 tokens');
}
