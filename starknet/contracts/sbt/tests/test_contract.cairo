use starknet::{ContractAddress, contract_address_const};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use simple_erc721::{ISBTDispatcher, ISBTDispatcherTrait};

fn deploy_contract() -> ContractAddress {
    let contract_class = declare("SBT").unwrap().contract_class();
    let name: ByteArray = "Soulbound Token";
    let symbol: ByteArray = "DSBT";
    let mut calldata = array![];
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_mint_SBT() {
    let contract_address = deploy_contract();
    let alice: ContractAddress = contract_address_const::<'ALICE'>();

    let dispatcher = ISBTDispatcher { contract_address };

    let token_id = dispatcher.mint(alice);

    assert(dispatcher.balanceOf(alice) == 1, 'Wrong balance');
    assert(dispatcher.ownerOf(token_id) == alice.into(), 'Wrong owner');
}
