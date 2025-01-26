use snforge_std::DeclareResultTrait;
use snforge_std::EventSpyAssertionsTrait;
use starknet::{ContractAddress, get_block_timestamp, contract_address_const};

use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{spy_events, cheat_caller_address, CheatSpan, declare, ContractClassTrait};

use token_vesting::vesting::{Vesting, IVestingDispatcher, IVestingDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use token_vesting::mocks::free_erc20::{IFreeMintDispatcher, IFreeMintDispatcherTrait};

const ONE_E18: u256 = 1000000000000000000_u256;

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn RECIPIENT() -> ContractAddress {
    contract_address_const::<'RECIPIENT'>()
}

fn OTHER_ADMIN() -> ContractAddress {
    contract_address_const::<'OTHER_ADMIN'>()
}

pub fn declare_and_deploy(contract_name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(contract_name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

fn deploy_erc20() -> ContractAddress {
    let mut calldata = array![];
    let initial_supply: u256 = 10_000_000_000_u256;
    let name: ByteArray = "DummyERC20";
    let symbol: ByteArray = "DUMMY";

    calldata.append_serde(initial_supply);
    calldata.append_serde(name);
    calldata.append_serde(symbol);
    let erc20_address = declare_and_deploy("FreeMintERC20", calldata);

    erc20_address
}

fn deploy_vesting_contract() -> IVestingDispatcher {
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    let vesting_contract = declare_and_deploy("Vesting", calldata);
    IVestingDispatcher { contract_address: vesting_contract }
}

fn setup() -> (IVestingDispatcher, IERC20Dispatcher) {
    let erc20_address = deploy_erc20();
    let initial_amount: u256 = 1000_000_u256 * ONE_E18;
    IFreeMintDispatcher { contract_address: erc20_address }.mint(OWNER(), initial_amount);
    let erc20_contract = IERC20Dispatcher { contract_address: erc20_address };
    let vesting_contract = deploy_vesting_contract();
    (vesting_contract, erc20_contract)
}


fn generate_schedule(duration_in_secs: u64, cliff: bool) -> (u64, u64, u64) {
    let start_time = get_block_timestamp() + 1000_u64;

    let cliff_time = if cliff {
        start_time + (duration_in_secs / 5_u64) // 20% = 1/5
    } else {
        start_time
    };

    let end_time = start_time + duration_in_secs;

    (start_time, cliff_time, end_time)
}


#[test]
fn test_add_schedule_without_cliff() {
    let (vesting_contract, erc20_token) = setup();

    let mut spy = spy_events();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, false);
    let amount = 10000_u256 * ONE_E18;

    cheat_caller_address(OWNER(), erc20_token.contract_address, CheatSpan::TargetCalls(1));
    erc20_token.approve(vesting_contract.contract_address, amount);

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule(
            erc20_token.contract_address, RECIPIENT(), start_time, cliff_time, end_time, amount,
        );

    let expected_event = Vesting::Event::NewScheduleAdded(
        Vesting::NewScheduleAdded {
            recipient: RECIPIENT(),
            token: erc20_token.contract_address,
            start_time: start_time,
            cliff_time: cliff_time,
            end_time: end_time,
            amount: amount,
        },
    );

    spy.assert_emitted(@array![(vesting_contract.contract_address, expected_event)]);

    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    assert!(RECIPIENT() == user_schedule.recipient, "wrong recipient in record");
    assert!(
        erc20_token.balance_of(vesting_contract.contract_address) == amount,
        "vesting_contract not incremented",
    )
}


#[test]
fn test_add_schedule_with_cliff() {
    let (vesting_contract, erc20_token) = setup();

    let mut spy = spy_events();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;

    cheat_caller_address(OWNER(), erc20_token.contract_address, CheatSpan::TargetCalls(1));
    erc20_token.approve(vesting_contract.contract_address, amount);

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule(
            erc20_token.contract_address, RECIPIENT(), start_time, cliff_time, end_time, amount,
        );

    let expected_event = Vesting::Event::NewScheduleAdded(
        Vesting::NewScheduleAdded {
            recipient: RECIPIENT(),
            token: erc20_token.contract_address,
            start_time: start_time,
            cliff_time: cliff_time,
            end_time: end_time,
            amount: amount,
        },
    );

    spy.assert_emitted(@array![(vesting_contract.contract_address, expected_event)]);

    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    assert!(RECIPIENT() == user_schedule.recipient, "wrong recipient in record");
    assert!(amount == user_schedule.total_amount, "wrong recipient in record");
    assert!(
        erc20_token.balance_of(vesting_contract.contract_address) == amount,
        "vesting_contract not incremented",
    )
}


#[test]
#[should_panic(expected: "User already has lock")]
fn test_admin_cannot_add_schedule_for_same_user() {
    let (vesting_contract, erc20_token) = setup();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;

    cheat_caller_address(OWNER(), erc20_token.contract_address, CheatSpan::TargetCalls(1));
    erc20_token.approve(vesting_contract.contract_address, amount);

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule(
            erc20_token.contract_address, RECIPIENT(), start_time, cliff_time, end_time, amount,
        );

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule(
            erc20_token.contract_address, RECIPIENT(), start_time, cliff_time, end_time, amount,
        );
}


#[test]
#[should_panic(expected: "Caller is not the owner")]
fn test_not_admin_cannot_add_schedule() {
    let (vesting_contract, erc20_token) = setup();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;

    cheat_caller_address(
        vesting_contract.contract_address, OTHER_ADMIN(), CheatSpan::TargetCalls(1),
    );
    vesting_contract
        .add_schedule(
            erc20_token.contract_address, RECIPIENT(), start_time, cliff_time, end_time, amount,
        );
}

#[test]
#[should_panic(expected: "Cliff time is invalid")]
fn test_not_admin_cannot_add_schedule_with_invalid_cliff_time() {
    let (vesting_contract, erc20_token) = setup();

    let (start_time, _, end_time) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule(
            erc20_token.contract_address,
            RECIPIENT(),
            start_time,
            start_time - 1000_u64,
            end_time,
            amount,
        );
}


#[test]
#[should_panic(expected: "End time provided is invalid")]
fn test_not_admin_cannot_add_schedule_with_invalid_end_time() {
    let (vesting_contract, erc20_token) = setup();

    let (start_time, cliff_time, _) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule(
            erc20_token.contract_address,
            RECIPIENT(),
            start_time,
            cliff_time,
            cliff_time - 1000_u64,
            amount,
        );
}


#[test]
fn test_add_schedule_with_percentage() {
    let (vesting_contract, erc20_token) = setup();

    let mut spy = spy_events();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;
    let percentage = 40;

    cheat_caller_address(OWNER(), erc20_token.contract_address, CheatSpan::TargetCalls(1));
    erc20_token.approve(vesting_contract.contract_address, amount);

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule_with_percentage(
            erc20_token.contract_address,
            RECIPIENT(),
            start_time,
            cliff_time,
            end_time,
            amount,
            percentage,
        );

    let expected_amount = amount * percentage / 100;

    let expected_event = Vesting::Event::NewScheduleAdded(
        Vesting::NewScheduleAdded {
            recipient: RECIPIENT(),
            token: erc20_token.contract_address,
            start_time: start_time,
            cliff_time: cliff_time,
            end_time: end_time,
            amount: expected_amount,
        },
    );

    spy.assert_emitted(@array![(vesting_contract.contract_address, expected_event)]);

    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    assert!(RECIPIENT() == user_schedule.recipient, "wrong recipient in record");
    assert!(amount == user_schedule.total_amount, "wrong recipient in record");
    assert!(
        erc20_token.balance_of(vesting_contract.contract_address) == amount,
        "vesting_contract not incremented",
    )
}

#[test]
#[should_panic(expected: "Percentage greater than 100")]
fn test_admin_cannot_add_schedule_with_percentage_greater_100() {
    let (vesting_contract, erc20_token) = setup();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;
    let percentage = 150;

    cheat_caller_address(OWNER(), erc20_token.contract_address, CheatSpan::TargetCalls(1));
    erc20_token.approve(vesting_contract.contract_address, amount);

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract
        .add_schedule_with_percentage(
            erc20_token.contract_address,
            RECIPIENT(),
            start_time,
            cliff_time,
            end_time,
            amount,
            percentage,
        );
}
