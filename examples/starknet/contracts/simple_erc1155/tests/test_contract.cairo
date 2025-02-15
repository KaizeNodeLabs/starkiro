use snforge_std::EventSpyAssertionsTrait;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, cheat_caller_address, spy_events, CheatSpan,
};
use simple_erc1155::erc1155::{
    IERC1155Dispatcher, IERC1155DispatcherTrait, ERC1155::{Event, TransferBatch, TransferSingle},
};

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

const BALANCE: u256 = 1000000;

fn deploy_contract() -> ContractAddress {
    let mut calldata = array![];
    let token_uri: ByteArray = "some_uri";
    let token_ids: Span<u256> = array![1, 2, 3, 4, 5].span();
    let recipient = OWNER();
    let values: Span<u256> = array![BALANCE, BALANCE, BALANCE, BALANCE, BALANCE].span();

    token_uri.serialize(ref calldata);
    recipient.serialize(ref calldata);
    token_ids.serialize(ref calldata);
    values.serialize(ref calldata);

    let contract = declare("ERC1155").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_transactions_and_balances() {
    let contract_address = deploy_contract();
    let dispatcher = IERC1155Dispatcher { contract_address };
    assert_eq!(dispatcher.uri(1), "some_uri");

    let user_1 = contract_address_const::<'USER 1'>();
    let balance = dispatcher.balance_of(OWNER(), 1);
    assert(balance == BALANCE, 'MINT ERROR');

    let mut spy = spy_events();
    // transfer to user_1
    let transfer_amount_1 = 3500;
    let transfer_amount_2 = 6000;

    let token_ids = array![1, 2].span();
    let values = array![transfer_amount_1, transfer_amount_2].span();

    // before transferring to user 1, let's confirm user 1's balance is zero
    let init_balance = dispatcher.balance_of(user_1, 1);
    assert_eq!(init_balance, 0);

    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(1));
    dispatcher.safe_batch_transfer_from(OWNER(), user_1, token_ids, values, array![].span());

    let transfer_batch_event = Event::TransferBatch(
        TransferBatch { operator: OWNER(), from: OWNER(), to: user_1, ids: token_ids, values },
    );

    spy.assert_emitted(@array![(contract_address, transfer_batch_event)]);

    let expected_user_1_balance = transfer_amount_1 + transfer_amount_2;

    // check the owner balance of recently transferred tokens of id 1 and 2
    let expected_owner_balance = (BALANCE * 2) - expected_user_1_balance;
    let owner_balances = dispatcher.balance_of_batch(array![OWNER(), OWNER()].span(), token_ids);
    let total_balances = *owner_balances.at(0) + *owner_balances.at(1);
    assert(expected_owner_balance == total_balances, 'TRANSFER FAILED');

    // check the owner balance of tokens of id 3 and 4. This should remain unchanged
    let owner_balances = dispatcher
        .balance_of_batch(array![OWNER(), OWNER()].span(), array![3, 4].span());
    assert_eq!(*owner_balances.at(0), BALANCE);
    assert_eq!(*owner_balances.at(1), BALANCE);

    // check the balance of user_1, it shouldn't be zero now
    let user_1_balances = dispatcher.balance_of_batch(array![user_1, user_1].span(), token_ids);
    let total_balance = *user_1_balances.at(0) + *user_1_balances.at(1);
    assert(total_balance == expected_user_1_balance, 'TRANSFER FAILED.');
}

#[test]
#[should_panic(expected: 'ERC1155: unauthorized operator')]
fn should_panic_when_spender_is_unauthorized() {
    let contract_address = deploy_contract();
    let dispatcher = IERC1155Dispatcher { contract_address };
    let spender = contract_address_const::<'SPENDER'>();
    cheat_caller_address(contract_address, spender, CheatSpan::TargetCalls(1));
    dispatcher
        .safe_batch_transfer_from(
            OWNER(), spender, array![1].span(), array![2500].span(), array![].span(),
        );
}

#[test]
fn test_transfer_on_behalf_of_owner() {
    let contract_address = deploy_contract();
    let dispatcher = IERC1155Dispatcher { contract_address };
    let spender = contract_address_const::<'SPENDER'>();
    cheat_caller_address(contract_address, OWNER(), CheatSpan::TargetCalls(1));
    dispatcher.set_approval_for_all(spender, true);

    // now spender can spend on owner's behalf
    cheat_caller_address(contract_address, spender, CheatSpan::TargetCalls(1));
    let amount = 3500;
    let mut spy = spy_events();
    dispatcher.safe_transfer_from(OWNER(), spender, 1, amount, array![].span());

    let transfer_event = Event::TransferSingle(
        TransferSingle { operator: spender, from: OWNER(), to: spender, id: 1, value: amount },
    );

    assert(dispatcher.balance_of(spender, 1) == amount, 'TRANSFER FAILED');
    spy.assert_emitted(@array![(contract_address, transfer_event)]);
}
