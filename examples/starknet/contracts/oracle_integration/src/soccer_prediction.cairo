use starknet::ContractAddress;
use core::byte_array::ByteArray;

/// Pragma Optimistic Oracle contract address (sepolia)
const ORACLE_ADDRESS: felt252 = 0x44ac84b04789b0a2afcdd2eb914f0f9b767a77a95a019ebaadc28d6cacbaeeb;
/// Identifier to use for prediction market
const IDENTIFIER: felt252 = 'ASSERT_TRUTH';
const DEFAULT_BOND: u256 = 1000000000000000000;


/// interface based on the Pragma Optimistic Oracle interface
/// [github](https://github.com/astraly-labs/Optimistic-Oracle/blob/main/optimistic_oracle/src/contracts/interfaces.cairo)
#[starknet::interface]
pub trait IOptimisticOracle<TContractState> {
    fn assert_truth(
        ref self: TContractState,
        claim: ByteArray,
        asserter: ContractAddress,
        callback_recipient: ContractAddress,
        escalation_manager: ContractAddress,
        liveness: u64,
        currency: ContractAddress,
        bond: u256,
        identifier: felt252,
        domain_id: u256,
    ) -> felt252;

    fn dispute_assertion(
        ref self: TContractState, assertion_id: felt252, disputer: ContractAddress,
    );
    fn settle_assertion(ref self: TContractState, assertion_id: felt252);
    fn get_assertion_result(self: @TContractState, assertion_id: felt252) -> bool;
    fn get_assertion(self: @TContractState, assertion_id: felt252) -> Assertion;
}

#[derive(Drop, Serde)]
pub struct Assertion {
    pub asserter: ContractAddress,
    pub assertion_time: u64,
    pub settled: bool,
    pub currency: ContractAddress,
    pub expiration_time: u64,
    pub settlement_resolution: bool,
    pub domain_id: u256,
    pub identifier: felt252,
    pub bond: u256,
    pub callback_recipient: ContractAddress,
    pub disputer: ContractAddress,
}

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transferFrom(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
}

#[starknet::interface]
pub trait ISoccerPredictionOracleTrait<TContractState> {
    fn predict_match_result(
        ref self: TContractState,
        home_team: felt252,
        away_team: felt252,
        league: felt252,
        match_date: u64,
        home_score: u8,
        away_score: u8,
        currency: ContractAddress,
        bond: u256,
    ) -> felt252;

    fn dispute_prediction(ref self: TContractState, assertion_id: felt252);
    fn settle_and_store_result(ref self: TContractState, assertion_id: felt252);
    fn get_prediction_result(self: @TContractState, assertion_id: felt252) -> bool;
    fn get_match_data(self: @TContractState, assertion_id: felt252) -> SoccerMatchData;
    fn assertion_resolved_callback(ref self: TContractState, assertion_id: felt252);
    fn assertion_disputed_callback(ref self: TContractState, assertion_id: felt252);
}

#[derive(Drop, Serde, starknet::Store)]
struct SoccerMatchData {
    pub home_team: felt252,
    pub away_team: felt252,
    pub league: felt252,
    pub match_date: u64,
    pub home_score: u8,
    pub away_score: u8,
    pub result: bool,
    pub is_settled: bool,
    pub is_disputed: bool,
}

#[starknet::contract]
mod SoccerPredictionOracle {
    use super::{
        IOptimisticOracleDispatcher, IOptimisticOracleDispatcherTrait, ISoccerPredictionOracleTrait,
        IERC20Dispatcher, IERC20DispatcherTrait, SoccerMatchData, ORACLE_ADDRESS, IDENTIFIER,
        DEFAULT_BOND,
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::{
        Map, StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess,
        StorageMapWriteAccess,
    };
    use core::traits::TryInto;
    use core::array::ArrayTrait;

    #[storage]
    struct Storage {
        oracle: IOptimisticOracleDispatcher,
        match_data: Map<felt252, SoccerMatchData>,
        assertion_ids: Map<felt252, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PredictionRequested: PredictionRequested,
        PredictionSettled: PredictionSettled,
        PredictionDisputed: PredictionDisputed,
    }

    #[derive(Drop, starknet::Event)]
    struct PredictionRequested {
        assertion_id: felt252,
        home_team: felt252,
        away_team: felt252,
        league: felt252,
        match_date: u64,
        home_score: u8,
        away_score: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct PredictionSettled {
        assertion_id: felt252,
        result: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct PredictionDisputed {
        assertion_id: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self
            .oracle
            .write(
                IOptimisticOracleDispatcher {
                    contract_address: ORACLE_ADDRESS.try_into().expect('failed address conversion'),
                },
            );
    }

    #[abi(embed_v0)]
    impl ISoccerPredictionOracleImpl of ISoccerPredictionOracleTrait<ContractState> {
        fn predict_match_result(
            ref self: ContractState,
            home_team: felt252,
            away_team: felt252,
            league: felt252,
            match_date: u64,
            home_score: u8,
            away_score: u8,
            currency: ContractAddress,
            bond: u256,
        ) -> felt252 {
            let caller = get_caller_address();
            let oracle = self.oracle.read();
            // 7200 sec = 2 hours - can be adjusted based on match timing
            let liveness = 7200;
            let bond_amount = if bond == 0 {
                DEFAULT_BOND
            } else {
                bond
            };

            let token = IERC20Dispatcher { contract_address: currency };
            token.approve(oracle.contract_address, bond_amount);

            let claim = format!(
                "{} will score {} and {} will score {} in their match on {} in the {}",
                home_team,
                home_score,
                away_team,
                away_score,
                match_date,
                league,
            );

            let assertion_id = oracle
                .assert_truth(
                    claim,
                    caller,
                    get_contract_address(),
                    0.try_into().unwrap(),
                    liveness,
                    currency,
                    bond_amount,
                    IDENTIFIER,
                    0,
                );

            self
                .match_data
                .write(
                    assertion_id,
                    SoccerMatchData {
                        home_team,
                        away_team,
                        league,
                        match_date,
                        home_score,
                        away_score,
                        result: false,
                        is_settled: false,
                        is_disputed: false,
                    },
                );

            self.assertion_ids.write(assertion_id, true);

            self
                .emit(
                    PredictionRequested {
                        assertion_id,
                        home_team,
                        away_team,
                        league,
                        match_date,
                        home_score,
                        away_score,
                    },
                );

            assertion_id
        }

        fn dispute_prediction(ref self: ContractState, assertion_id: felt252) {
            assert(self.assertion_ids.read(assertion_id), 'Invalid assertion ID');

            let oracle = self.oracle.read();

            let assertion = oracle.get_assertion(assertion_id);

            let token = IERC20Dispatcher { contract_address: assertion.currency };
            token.approve(oracle.contract_address, assertion.bond);

            let caller = get_caller_address();
            oracle.dispute_assertion(assertion_id, caller);

            let mut data = self.match_data.read(assertion_id);
            data.is_disputed = true;
            self.match_data.write(assertion_id, data);

            self.emit(PredictionDisputed { assertion_id });
        }

        fn settle_and_store_result(ref self: ContractState, assertion_id: felt252) {
            assert(self.assertion_ids.read(assertion_id), 'Invalid assertion ID');

            let oracle = self.oracle.read();

            oracle.settle_assertion(assertion_id);

            let result = oracle.get_assertion_result(assertion_id);

            let mut data = self.match_data.read(assertion_id);
            data.result = result;
            data.is_settled = true;
            self.match_data.write(assertion_id, data);

            self.emit(PredictionSettled { assertion_id, result });
        }

        fn get_prediction_result(self: @ContractState, assertion_id: felt252) -> bool {
            assert(self.assertion_ids.read(assertion_id), 'Invalid assertion ID');

            let data = self.match_data.read(assertion_id);

            assert(data.is_settled, 'Prediction not settled yet');

            data.result
        }

        fn get_match_data(self: @ContractState, assertion_id: felt252) -> SoccerMatchData {
            assert(self.assertion_ids.read(assertion_id), 'Invalid assertion ID');

            self.match_data.read(assertion_id)
        }

        fn assertion_resolved_callback(ref self: ContractState, assertion_id: felt252) {
            let oracle = self.oracle.read();
            let result = oracle.get_assertion_result(assertion_id);

            let mut data = self.match_data.read(assertion_id);
            data.result = result;
            data.is_settled = true;
            self.match_data.write(assertion_id, data);

            self.emit(PredictionSettled { assertion_id, result });
        }

        fn assertion_disputed_callback(ref self: ContractState, assertion_id: felt252) {
            let mut data = self.match_data.read(assertion_id);
            data.is_disputed = true;
            self.match_data.write(assertion_id, data);

            self.emit(PredictionDisputed { assertion_id });
        }
    }
}
