
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, stop_cheat_caller_address,
    start_cheat_caller_address, start_mock_call, stop_mock_call,
};
use soccer_prediction::soccer_prediction::ISoccerPredictionOracleTraitDispatcher;
use soccer_prediction::soccer_prediction::ISoccerPredictionOracleTraitDispatcherTrait;
use soccer_prediction::soccer_prediction::Assertion;
use starknet::{ContractAddress, contract_address_const};

const ORACLE_ADDRESS: felt252 = 0x44ac84b04789b0a2afcdd2eb914f0f9b767a77a95a019ebaadc28d6cacbaeeb;
const TEST_TOKEN_ADDRESS: felt252 =
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;
const TEST_USER_ADDRESS: felt252 =
    0x0416575467BBE3E3D1ABC92d175c71e06C7EA1FaB37120983A08b6a2B2D12794;
const TEST_BOND_AMOUNT: u256 = 1000000000000000000; // token with 18 decimals

fn deploy_contract() -> ContractAddress {
    let contract = declare("SoccerPredictionOracle").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn setup_mocks(contract_address: ContractAddress, assertion_id: felt252) {
    start_mock_call(
        contract_address_const::<ORACLE_ADDRESS>(), selector!("assert_truth"), assertion_id,
    );

    start_mock_call(
        contract_address_const::<ORACLE_ADDRESS>(), selector!("get_assertion_result"), true,
    );

    // Mock ERC20 approve function
    start_mock_call(contract_address_const::<TEST_TOKEN_ADDRESS>(), selector!("approve"), true);
}

#[test]
fn test_predict_match_result() {
    let contract_address = deploy_contract();
    let dispatcher = ISoccerPredictionOracleTraitDispatcher { contract_address };

    let assertion_id: felt252 = 123456;
    setup_mocks(contract_address, assertion_id);

    start_cheat_caller_address(contract_address, contract_address_const::<TEST_USER_ADDRESS>());
    
    // predict that MU will score 2 goals and Liverpool 1 goal in their match
    let result = dispatcher
        .predict_match_result(
            'Manchester United',
            'Liverpool',
            'Premier League',
            1709136000,
            2,
            1,
            contract_address_const::<TEST_TOKEN_ADDRESS>(),
            TEST_BOND_AMOUNT,
        );

    assert(result == assertion_id, 'Incorrect assertion ID');

    let match_data = dispatcher.get_match_data(assertion_id);
    assert(match_data.home_team == 'Manchester United', 'Wrong home team');
    assert(match_data.away_team == 'Liverpool', 'Wrong away team');

    stop_cheat_caller_address(contract_address);
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("assert_truth"));
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("get_assertion_result"));
    stop_mock_call(contract_address_const::<TEST_TOKEN_ADDRESS>(), selector!("approve"));
}

#[test]
fn test_settle_and_dispute() {
    let contract_address = deploy_contract();
    let dispatcher = ISoccerPredictionOracleTraitDispatcher { contract_address };

    let assertion_id: felt252 = 123456;
    setup_mocks(contract_address, assertion_id);

    start_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("settle_assertion"), ());

    let mock_assertion = Assertion {
        asserter: contract_address_const::<TEST_USER_ADDRESS>(),
        assertion_time: 1709136000,
        settled: false,
        currency: contract_address_const::<TEST_TOKEN_ADDRESS>(),
        expiration_time: 1709136000 + 7200,
        settlement_resolution: false,
        domain_id: 0,
        identifier: 'ASSERT_TRUTH',
        bond: TEST_BOND_AMOUNT,
        callback_recipient: contract_address,
        disputer: contract_address_const::<0>(),
    };

    start_mock_call(
        contract_address_const::<ORACLE_ADDRESS>(), selector!("get_assertion"), mock_assertion,
    );

    start_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("dispute_assertion"), ());

    start_cheat_caller_address(contract_address, contract_address_const::<TEST_USER_ADDRESS>());

    dispatcher
        .predict_match_result(
            'Manchester United',
            'Liverpool',
            'Premier League',
            1709136000,
            2,
            1,
            contract_address_const::<TEST_TOKEN_ADDRESS>(),
            TEST_BOND_AMOUNT,
        );

    dispatcher.settle_and_store_result(assertion_id);
    let match_data = dispatcher.get_match_data(assertion_id);
    assert(match_data.is_settled == true, 'Should be settled');

    dispatcher.dispute_prediction(assertion_id);
    let match_data = dispatcher.get_match_data(assertion_id);
    assert(match_data.is_disputed == true, 'Should be disputed');

    stop_cheat_caller_address(contract_address);
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("settle_assertion"));
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("get_assertion"));
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("dispute_assertion"));
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("assert_truth"));
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("get_assertion_result"));
    stop_mock_call(contract_address_const::<TEST_TOKEN_ADDRESS>(), selector!("approve"));
}

#[test]
fn test_callbacks() {
    let contract_address = deploy_contract();
    let dispatcher = ISoccerPredictionOracleTraitDispatcher { contract_address };

    let assertion_id: felt252 = 123456;
    setup_mocks(contract_address, assertion_id);

    start_cheat_caller_address(contract_address, contract_address_const::<TEST_USER_ADDRESS>());

    dispatcher
        .predict_match_result(
            'Manchester United',
            'Liverpool',
            'Premier League',
            1709136000,
            2,
            1,
            contract_address_const::<TEST_TOKEN_ADDRESS>(),
            TEST_BOND_AMOUNT,
        );

    dispatcher.assertion_resolved_callback(assertion_id);
    let match_data = dispatcher.get_match_data(assertion_id);
    assert(match_data.is_settled == true, 'Should be settled');

    dispatcher.assertion_disputed_callback(assertion_id);
    let match_data = dispatcher.get_match_data(assertion_id);
    assert(match_data.is_disputed == true, 'Should be disputed');

    stop_cheat_caller_address(contract_address);
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("assert_truth"));
    stop_mock_call(contract_address_const::<ORACLE_ADDRESS>(), selector!("get_assertion_result"));
    stop_mock_call(contract_address_const::<TEST_TOKEN_ADDRESS>(), selector!("approve"));
}
