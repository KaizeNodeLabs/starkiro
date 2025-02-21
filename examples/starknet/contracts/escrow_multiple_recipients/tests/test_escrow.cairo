use starknet::{contract_address_const, ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address
};
use escrow_multiple_recipients::escrow::{IEscrowDispatcher, IEscrowDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


fn CALLER_1() -> ContractAddress {
    contract_address_const::<0x0416575467BBE3E3D1ABC92d175c71e06C7EA1FaB37120983A08b6a2B2D12794>()
}


fn deploy() -> IEscrowDispatcher {
    let mut constructor_args: Array<felt252> = array![];
    let strk_token_address = contract_address_const::<
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
    >();
    constructor_args.append(strk_token_address.into());
    let contract = declare("Escrow").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    let dispatcher = IEscrowDispatcher { contract_address };
    dispatcher
}


#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 465261)]
fn test_create_order_and_deploy() {
    let dispatcher = deploy();
    // create order 
    let mut recipients: Array<felt252> = array![];
    recipients.append('party A');
    recipients.append('party B');

    let mut addresses: Array<ContractAddress> = array![];
    addresses.append(contract_address_const::<0x123>());
    addresses.append(contract_address_const::<0x456>());
    let amount = 1000;
    let order_id = dispatcher.create_order(amount, recipients, addresses);

    let strk = IERC20Dispatcher {
        contract_address: contract_address_const::<
            0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d
        >()
    };

    // fund contract for gas and approve amount 
    start_cheat_caller_address(strk.contract_address, CALLER_1());
    strk.transfer(dispatcher.contract_address, 10000000000000000000);
    strk.approve(dispatcher.contract_address, amount);
    stop_cheat_caller_address(strk.contract_address);

    // pay order 
    start_cheat_caller_address(dispatcher.contract_address, CALLER_1());
    dispatcher.pay_order(order_id);
    assert(dispatcher.get_order_state(order_id) == 'Paid', 'State should be Paid');
    dispatcher.complete_order(order_id, 'party A');
    assert(dispatcher.get_order_state(order_id) == 'Completed', 'State should be Completed');
    stop_cheat_caller_address(dispatcher.contract_address);
}


#[test]
fn test_create_order() {
    let escrow_dispatcher = deploy();
    // create order 
    let mut recipients: Array<felt252> = array![];
    recipients.append('party A');
    recipients.append('party B');

    let mut addresses: Array<ContractAddress> = array![];
    addresses.append(contract_address_const::<0x123>());
    addresses.append(contract_address_const::<0x456>());
    let amount = 1000;
    let order_id = escrow_dispatcher.create_order(amount, recipients, addresses);

    assert(order_id == 1, 'Order ID should be 1');
    assert(escrow_dispatcher.get_order_amount(order_id) == amount, 'Amount should be 1000');
    assert(escrow_dispatcher.get_order_recipient_address(order_id, 'party A') == contract_address_const::<0x123>(), 'Address should be 0x123');
    assert(escrow_dispatcher.get_order_recipient_address(order_id, 'party B') == contract_address_const::<0x456>(), 'Address should be 0x456');
    assert(escrow_dispatcher.get_order_state(order_id) == 'NotPaid', 'State should be NotPaid');
}


#[test]
fn test_cancel_order() {
    let escrow_dispatcher = deploy();
    let mut recipients: Array<felt252> = array![];
    recipients.append('party A');
    recipients.append('party B');

    let mut addresses: Array<ContractAddress> = array![];
    addresses.append(contract_address_const::<0x123>());
    addresses.append(contract_address_const::<0x456>());
    let amount = 1000;
    let order_id = escrow_dispatcher.create_order(amount, recipients, addresses);
    escrow_dispatcher.cancel_order(order_id);
    assert(escrow_dispatcher.get_order_state(order_id) == 'Cancelled', 'State should be Cancelled');
}
