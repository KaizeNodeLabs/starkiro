use starknet::{ContractAddress, contract_address_const};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};
use soulbound_token::{ISBTDispatcher, ISBTDispatcherTrait};

fn deploy_contract() -> ContractAddress {
    let contract_class = declare("SBT").unwrap().contract_class();
    let name: ByteArray = "Soulbound Token";
    let symbol: ByteArray = "DSBT";
    let token_uri: ByteArray = "https://example.com/token-metadata/1";

    let mut calldata = array![];
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);
    token_uri.serialize(ref calldata);

    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

fn get_jon_address() -> ContractAddress {
    contract_address_const::<'JON'>()
}

#[test]
fn test_mint_SBT() {
    let contract_address = deploy_contract();
    let jon: ContractAddress = get_jon_address();

    let dispatcher = ISBTDispatcher { contract_address };

    let token_id = dispatcher.mint(jon);

    assert(dispatcher.balanceOf(jon) == 1, 'Wrong balance');
    assert(dispatcher.ownerOf(token_id) == jon.into(), 'Wrong owner');
}

#[test]
fn test_burn_SBT() {
    let contract_address = deploy_contract();
    let jon: ContractAddress = get_jon_address();

    let dispatcher = ISBTDispatcher { contract_address };

    let token_id = dispatcher.mint(jon);

    assert(dispatcher.balanceOf(jon) == 1, 'Wrong balance');
    assert(dispatcher.ownerOf(token_id) == jon.into(), 'Wrong owner');

    // only owner of token can burn his/her token
    start_cheat_caller_address(contract_address, jon);
    let jon_token_burned = dispatcher.burn(token_id);
    stop_cheat_caller_address(contract_address);

    assert(jon_token_burned == true, 'failed to burn jon token');
    assert(dispatcher.balanceOf(jon) == 0, 'Wrong balance');
}

#[test]
#[should_panic(expected: "SBT: Tokens are non-transferable" )]
fn test_transferFrom_reverts() {
    let contract_address = deploy_contract();
    let jon: ContractAddress = get_jon_address();

    let dispatcher = ISBTDispatcher { contract_address };

    let token_id = dispatcher.mint(jon);

    // Attempt to transfer the token
    let token_recipient: ContractAddress = starknet::contract_address_const::<0x123456711>();
        
    dispatcher.transferFrom(jon, token_recipient, token_id);
}

#[test]
#[should_panic(expected: "SBT: Tokens are non-transferable")]
fn test_safeTransferFrom_reverts() {
    let contract_address = deploy_contract();
    let jon: ContractAddress = get_jon_address();

    let dispatcher = ISBTDispatcher { contract_address };

    let token_id = dispatcher.mint(jon);

    // Attempt to transfer the token
    let token_recipient: ContractAddress = starknet::contract_address_const::<0x123456711>();
        
    // Attempt to safely transfer the token (should panic)
    let data: Span<felt252> = array![].span();
    dispatcher.safeTransferFrom(jon, token_recipient, token_id, data);
}

#[test]
fn test_hash_any_sbt_fn() {
    let contract_address = deploy_contract();
    let jon: ContractAddress = get_jon_address();

    let dispatcher = ISBTDispatcher { contract_address };

    let jon_has_sbt = dispatcher.has_any_sbt(jon);

    // jon hasn't minted so has no sbt yet expected to be false
    assert!(jon_has_sbt == false);

    // mint nft to jon and check again
    dispatcher.mint(jon);
    let jon_has_sbt = dispatcher.has_any_sbt(jon);

    assert!(jon_has_sbt);
}
