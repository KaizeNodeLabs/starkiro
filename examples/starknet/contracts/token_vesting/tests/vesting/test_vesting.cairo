use snforge_std::EventSpyAssertionsTrait;
use starknet::{get_block_timestamp};

use snforge_std::{
    spy_events, cheat_caller_address, CheatSpan, start_cheat_block_timestamp_global,
    stop_cheat_block_timestamp_global,
};

use token_vesting::vesting::{Vesting, IVestingDispatcher, IVestingDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use crate::utils::*;

const amount: u256 = 10_000_u256 * ONE_E18;

fn add_schedule() -> (IVestingDispatcher, IERC20Dispatcher) {
    let (vesting_contract, erc20_token) = setup();

    let mut spy = spy_events();
    let duration = 20_000;
    let (start_time, cliff_time, end_time) = generate_schedule(duration, true);
    let amount = 10_000_u256 * ONE_E18;

    cheat_caller_address(erc20_token.contract_address, OWNER(), CheatSpan::TargetCalls(1));
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

    (vesting_contract, erc20_token)
}


#[test]
fn test_user_cannot_claim_if_cliff_not_reached() {
    let (vesting_contract, erc20_token) = add_schedule();

    let time_stamp = get_block_timestamp();
    let prev_balance = erc20_token.balance_of(RECIPIENT());

    // duration is 20_000secs i.e cliff is set to 20%
    start_cheat_block_timestamp_global(time_stamp + 1000);

    let claimable = vesting_contract.get_claimable_amount(RECIPIENT());

    cheat_caller_address(vesting_contract.contract_address, RECIPIENT(), CheatSpan::TargetCalls(1));
    vesting_contract.claim(erc20_token.contract_address);

    stop_cheat_block_timestamp_global();

    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    let curr_balance = erc20_token.balance_of(RECIPIENT());

    assert!(curr_balance == prev_balance, "Current balance does not match previous balance");

    assert!(claimable == 0, "Claimable amount is not zero as expected");

    assert!(user_schedule.total_claimed == 0, "Total claimed amount is not zero as expected");
}

#[test]
fn test_user_can_claim_part_if_cliff_exceeded() {
    let mut spy = spy_events();

    let (vesting_contract, erc20_token) = add_schedule();
    let time_stamp = get_block_timestamp();
    let prev_balance = erc20_token.balance_of(RECIPIENT());

    // duration is 20_000secs i.e cliff is set to 20%
    start_cheat_block_timestamp_global(time_stamp + 5000);

    let claimable = vesting_contract.get_claimable_amount(RECIPIENT());

    cheat_caller_address(vesting_contract.contract_address, RECIPIENT(), CheatSpan::TargetCalls(1));
    vesting_contract.claim(erc20_token.contract_address);
    stop_cheat_block_timestamp_global();

    let expected_event = Vesting::Event::SuccessfulClaim(
        Vesting::SuccessfulClaim {
            recipient: RECIPIENT(), token: erc20_token.contract_address, amount: claimable,
        },
    );

    spy.assert_emitted(@array![(vesting_contract.contract_address, expected_event)]);
    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    let curr_balance = erc20_token.balance_of(RECIPIENT());

    assert!(
        curr_balance >= prev_balance + claimable, "Recipient balance did not increase as expected",
    );

    assert!(
        user_schedule.total_claimed >= claimable,
        "Claimed amount is less than the claimable amount",
    );

    assert!(
        user_schedule.total_claimed <= user_schedule.total_amount,
        "Claimed amount exceeds the total allocation",
    );
}

#[test]
fn test_user_can_claim_all_after_vesting_ended() {
    let mut spy = spy_events();

    let (vesting_contract, erc20_token) = add_schedule();
    let time_stamp = get_block_timestamp();
    let prev_balance = erc20_token.balance_of(RECIPIENT());

    // duration is 20_000secs
    start_cheat_block_timestamp_global(time_stamp + 21_000);

    let claimable = vesting_contract.get_claimable_amount(RECIPIENT());

    cheat_caller_address(vesting_contract.contract_address, RECIPIENT(), CheatSpan::TargetCalls(1));
    vesting_contract.claim(erc20_token.contract_address);
    stop_cheat_block_timestamp_global();

    let expected_event = Vesting::Event::SuccessfulClaim(
        Vesting::SuccessfulClaim {
            recipient: RECIPIENT(), token: erc20_token.contract_address, amount: claimable,
        },
    );

    spy.assert_emitted(@array![(vesting_contract.contract_address, expected_event)]);

    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    let curr_balance = erc20_token.balance_of(RECIPIENT());

    assert!(
        curr_balance == prev_balance + claimable, "Recipient balance did not increase as expected",
    );

    assert!(
        user_schedule.total_claimed == claimable,
        "Claimed amount is less than the claimable amount",
    );

    assert!(
        user_schedule.total_claimed == user_schedule.total_amount,
        "Claimed amount exceeds the total allocation",
    );
}

#[test]
fn test_non_registered_user_cannot_claim() {
    let (vesting_contract, erc20_token) = add_schedule();
    let time_stamp = get_block_timestamp();
    let prev_balance = erc20_token.balance_of(OTHER());

    // duration is 20_000secs
    start_cheat_block_timestamp_global(time_stamp + 20_000);

    let claimable = vesting_contract.get_claimable_amount(OTHER());

    cheat_caller_address(vesting_contract.contract_address, OTHER(), CheatSpan::TargetCalls(1));
    vesting_contract.claim(erc20_token.contract_address);
    stop_cheat_block_timestamp_global();

    let user_schedule = vesting_contract.get_user_vesting_schedule(OTHER());

    let curr_balance = erc20_token.balance_of(OTHER());

    assert!(curr_balance == prev_balance, "Current balance does not match previous balance");

    assert!(claimable == 0, "Claimable amount is not zero as expected");

    assert!(user_schedule.total_claimed == 0, "Total claimed amount is not zero as expected");
}

#[test]
fn test_admin_can_remove_vesting() {
    let (vesting_contract, erc20_token) = add_schedule();
    let time_stamp = get_block_timestamp();

    start_cheat_block_timestamp_global(time_stamp + 2_000);

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract.remove_schedule(erc20_token.contract_address, RECIPIENT(), OWNER());

    stop_cheat_block_timestamp_global();

    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    assert!(user_schedule.total_amount == 0, "Expected total amount to be zero");

    assert!(user_schedule.total_claimed == 0, "Expected total claimed amount to be zero");

    assert!(user_schedule.recipient == ZERO_ADDRESS(), "Expected recipient to be the zero address");

    assert!(user_schedule.token == ZERO_ADDRESS(), "Expected token to be the zero address");

    assert!(user_schedule.cliff_time == 0, "Expected cliff time to be zero");

    assert!(user_schedule.start_time == 0, "Expected start time to be zero");

    assert!(user_schedule.end_time == 0, "Expected end time to be zero");
}

#[test]
fn test_admin_gets_full_refund_before_cliff() {
    let (vesting_contract, erc20_token) = add_schedule();
    let prev_balance = erc20_token.balance_of(OWNER());

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract.remove_schedule(erc20_token.contract_address, RECIPIENT(), OWNER());

    let curr_balance = erc20_token.balance_of(OWNER());

    assert!(curr_balance == prev_balance + amount, "Owner balance did not increase as expecte");
}

#[test]
fn test_user_gets_claimable_after_cliff() {
    let (vesting_contract, erc20_token) = add_schedule();
    let prev_balance = erc20_token.balance_of(RECIPIENT());
    let time_stamp = get_block_timestamp();

    // cliff is 4_000
    start_cheat_block_timestamp_global(time_stamp + 6_000);

    let claimable = vesting_contract.get_claimable_amount(RECIPIENT());

    cheat_caller_address(vesting_contract.contract_address, OWNER(), CheatSpan::TargetCalls(1));
    vesting_contract.remove_schedule(erc20_token.contract_address, RECIPIENT(), OWNER());

    stop_cheat_block_timestamp_global();

    let curr_balance = erc20_token.balance_of(RECIPIENT());

    assert!(
        curr_balance >= prev_balance + claimable, "Recipient balance did not increase as expecte",
    );
}

#[test]
#[should_panic]
fn test_non_admin_cannot_remove_schedule() {
    let (vesting_contract, erc20_token) = add_schedule();

    cheat_caller_address(
        vesting_contract.contract_address, OTHER_ADMIN(), CheatSpan::TargetCalls(1),
    );
    vesting_contract.remove_schedule(erc20_token.contract_address, RECIPIENT(), OTHER_ADMIN());
}
