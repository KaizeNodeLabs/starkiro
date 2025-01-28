use snforge_std::EventSpyAssertionsTrait;

use snforge_std::{spy_events, cheat_caller_address, CheatSpan};

use token_vesting::vesting::{Vesting, IVestingDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20DispatcherTrait};

use crate::utils::*;

#[test]
fn test_add_schedule_without_cliff() {
    let (vesting_contract, erc20_token) = setup();

    let mut spy = spy_events();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, false);
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

    let user_schedule = vesting_contract.get_user_vesting_schedule(RECIPIENT());

    assert!(RECIPIENT() == user_schedule.recipient, "wrong recipient in record");
    assert!(amount == user_schedule.total_amount, "wrong recipient in record");
    assert!(
        erc20_token.balance_of(vesting_contract.contract_address) == amount,
        "vesting_contract not incremented",
    )
}

#[test]
#[should_panic]
fn test_admin_cannot_add_schedule_for_same_user() {
    let (vesting_contract, erc20_token) = setup();

    let (start_time, cliff_time, end_time) = generate_schedule(2000, true);
    let amount = 10000_u256 * ONE_E18;

    cheat_caller_address(erc20_token.contract_address, OWNER(), CheatSpan::TargetCalls(1));
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
#[should_panic]
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
#[should_panic]
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
#[should_panic]
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
