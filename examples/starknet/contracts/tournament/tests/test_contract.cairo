use tournament::Tournament::{
    ITournamentDispatcher, ITournamentDispatcherTrait, Tournament, TournamentState,
    
};
use snforge_std::{
    CheatSpan, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait,
    cheat_caller_address, declare, spy_events,
};
use starknet::{ContractAddress, contract_address_const};
use core::array::ArrayTrait;
use core::traits::Into;

fn owner() -> ContractAddress {
    contract_address_const::<'owner'>()
}

fn player1() -> ContractAddress {
    contract_address_const::<'player1'>()
}

fn player2() -> ContractAddress {
    contract_address_const::<'player2'>()
}

fn player3() -> ContractAddress {
    contract_address_const::<'player3'>()
}

fn zero_address() -> ContractAddress {
    contract_address_const::<0>()
}

fn deploy_tournament() -> ContractAddress {
    let owner = owner();
    let contract_class = declare("Tournament").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(owner.into());
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

// Helper function to setup a basic tournament
fn setup_tournament(
    contract_address: ContractAddress,
    name: felt252,
    max_players: u32,
    entry_fee: u256,
    start_time: u64,
    end_time: u64
) {
    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }
        .create_tournament(name, max_players, entry_fee, start_time, end_time);
}

// Helper function to register a player
fn register_player(contract_address: ContractAddress, player: ContractAddress) {
    cheat_caller_address(contract_address, player, CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }.register_player();
}

#[test]
fn test_create_tournament() {
    let contract_address = deploy_tournament();
    let tournament = ITournamentDispatcher { contract_address };

    let name: felt252 = 'Test Tournament';
    let max_players: u32 = 10;
    let entry_fee: u256 = 100;
    let current_time: u64 = 1000;
    let start_time: u64 = current_time + 100;
    let end_time: u64 = start_time + 1000;

    let mut spy = spy_events();

    setup_tournament(contract_address, name, max_players, entry_fee, start_time, end_time);

    let tournament_info = tournament.get_tournament_info();
    assert(tournament_info.name == name, 'Name not set correctly');
    assert(tournament_info.max_players == max_players, 'Max players not set correctly');
    assert(tournament_info.entry_fee == entry_fee, 'Entry fee not set correctly');
    assert(tournament_info.start_time == start_time, 'Start time not set correctly');
    assert(tournament_info.end_time == end_time, 'End time not set correctly');
    assert(tournament_info.state == TournamentState::Registration, 'State not set correctly');
    assert(tournament_info.registered_players_count == 0, 'Player count not set correctly');
    assert(tournament_info.prize_pool == 0, 'Prize pool not set correctly');

    // Check event emission
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Tournament::Event::TournamentCreated(
                        Tournament::TournamentCreated {
                            name, max_players, entry_fee, start_time, end_time
                        }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: 'Only owner can create')]
fn test_only_owner_can_create_tournament() {
    let contract_address = deploy_tournament();

    cheat_caller_address(contract_address, player1(), CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }
        .create_tournament('Test Tournament', 10, 100, 1100, 2100);
}

#[test]
#[should_panic(expected: 'Invalid tournament times')]
fn test_invalid_tournament_times() {
    let contract_address = deploy_tournament();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }
        .create_tournament('Test Tournament', 10, 100, 2000, 1000 // end_time before start_time
        );
}

#[test]
#[should_panic(expected: 'Min 2 players required')]
fn test_minimum_players_check() {
    let contract_address = deploy_tournament();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }
        .create_tournament('Test Tournament', 1, 100, 1000, 2000 // max_players < 2
        );
}

#[test]
#[should_panic(expected: 'Registration not open')]
fn test_registration_before_tournament_created() {
    let contract_address = deploy_tournament();

    cheat_caller_address(contract_address, player1(), CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }.register_player();
}

#[test]
#[should_panic(expected: 'Tournament full')]
fn test_tournament_max_players() {
    let contract_address = deploy_tournament();

    let current_time: u64 = 1000;
    setup_tournament(
        contract_address, 'Test Tournament', 2, 100, current_time + 100, current_time + 1000
    );

    register_player(contract_address, player1());
    register_player(contract_address, player2());
    register_player(contract_address, player3()); // Should panic
}

#[test]
fn test_multiple_registrations() {
    let contract_address = deploy_tournament();
    let tournament = ITournamentDispatcher { contract_address };

    let current_time: u64 = 1000;
    setup_tournament(
        contract_address, 'Test Tournament', 10, 100, current_time + 100, current_time + 1000
    );

    register_player(contract_address, player1());
    register_player(contract_address, player2());
    register_player(contract_address, player3());

    let tournament_info = tournament.get_tournament_info();
    assert(tournament_info.registered_players_count == 3, 'Player count not updated');
    assert(tournament_info.prize_pool == 300, 'Prize pool not updated');

    let registered_players = tournament.get_registered_players();
    assert(registered_players.len() == 3, 'Registered players count wrong');
    assert(*registered_players.at(0) == player1(), 'Player1 not in list');
    assert(*registered_players.at(1) == player2(), 'Player2 not in list');
    assert(*registered_players.at(2) == player3(), 'Player3 not in list');
}


#[test]
#[should_panic(expected: 'Invalid state')]
fn test_cant_start_not_in_registration() {
    let contract_address = deploy_tournament();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }.start_tournament();
}

#[test]
#[should_panic(expected: 'Tournament not in progress')]
fn test_end_requires_in_progress_state() {
    let contract_address = deploy_tournament();

    let current_time: u64 = 1000;
    setup_tournament(
        contract_address, 'Test Tournament', 10, 100, current_time + 100, current_time + 1000
    );

    register_player(contract_address, player1());
    register_player(contract_address, player2());

    // Tournament not started yet

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    ITournamentDispatcher { contract_address }.end_tournament(player1());
}

