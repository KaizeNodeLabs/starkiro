use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store, PartialEq)]
#[allow(starknet::store_no_default_variant)]
enum TournamentState {
    NotStarted,
    Registration,
    InProgress,
    Completed,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct TournamentInfo {
    name: felt252,
    max_players: u32,
    entry_fee: u256,
    prize_pool: u256,
    start_time: u64,
    end_time: u64,
    state: TournamentState,
    registered_players_count: u32,
    winner: ContractAddress,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct PlayerInfo {
    address: ContractAddress,
    registration_time: u64,
    score: u32,
    rank: u32,
    has_claimed_prize: bool,
}

#[starknet::interface]
trait ITournament<TContractState> {
    // Tournament management
    fn create_tournament(
        ref self: TContractState,
        name: felt252,
        max_players: u32,
        entry_fee: u256,
        start_time: u64,
        end_time: u64,
    );
    fn register_player(ref self: TContractState);
    fn start_tournament(ref self: TContractState);
    fn end_tournament(ref self: TContractState, winner: ContractAddress);

    // View functions
    fn get_tournament_status(self: @TContractState) -> TournamentState;
    fn get_tournament_info(self: @TContractState) -> TournamentInfo;
    fn get_player_info(self: @TContractState, player: ContractAddress) -> PlayerInfo;
    fn get_registered_players(self: @TContractState) -> Array<ContractAddress>;
}

#[starknet::contract]
mod Tournament {
    use starknet::storage::StorageMapReadAccess;
    use starknet::storage::StorageMapWriteAccess;
    use super::{TournamentState, TournamentInfo, PlayerInfo};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::array::ArrayTrait;
    use core::traits::Into;
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        tournament_info: TournamentInfo,
        players: Map<ContractAddress, PlayerInfo>,
        registered_players: Map<u32, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TournamentCreated: TournamentCreated,
        PlayerRegistered: PlayerRegistered,
        TournamentStarted: TournamentStarted,
        TournamentEnded: TournamentEnded,
    }

    #[derive(Drop, starknet::Event)]
    struct TournamentCreated {
        name: felt252,
        max_players: u32,
        entry_fee: u256,
        start_time: u64,
        end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct PlayerRegistered {
        player: ContractAddress,
        registration_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TournamentStarted {
        start_time: u64,
        registered_players: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct TournamentEnded {
        end_time: u64,
        winner: ContractAddress,
        prize_pool: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self
            .tournament_info
            .write(
                TournamentInfo {
                    name: 0,
                    max_players: 0,
                    entry_fee: 0,
                    prize_pool: 0,
                    start_time: 0,
                    end_time: 0,
                    state: TournamentState::NotStarted,
                    registered_players_count: 0,
                    winner: starknet::contract_address_const::<0>(),
                },
            );
    }

    #[abi(embed_v0)]
    impl TournamentImpl of super::ITournament<ContractState> {
        fn create_tournament(
            ref self: ContractState,
            name: felt252,
            max_players: u32,
            entry_fee: u256,
            start_time: u64,
            end_time: u64,
        ) {
            // Validations
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Only owner can create');
            assert(start_time < end_time, 'Invalid tournament times');
            assert(max_players > 1, 'Min 2 players required');

            let tournament_info = TournamentInfo {
                name,
                max_players,
                entry_fee,
                prize_pool: 0,
                start_time,
                end_time,
                state: TournamentState::Registration,
                registered_players_count: 0,
                winner: starknet::contract_address_const::<0>(),
            };

            self.tournament_info.write(tournament_info);

            self
                .emit(
                    Event::TournamentCreated(
                        TournamentCreated { name, max_players, entry_fee, start_time, end_time },
                    ),
                );
        }

        fn register_player(ref self: ContractState) {
            let caller = get_caller_address();
            let tournament = self.tournament_info.read();

            // Validations
            assert(tournament.state == TournamentState::Registration, 'Registration not open');
            assert(tournament.registered_players_count < tournament.max_players, 'Tournament full');
            assert(!self.is_player_registered(caller), 'Already registered');

            // Handle entry fee transfer
            // Note: Actual implementation would need to handle the token transfer
            let current_time = get_block_timestamp();

            let player_info = PlayerInfo {
                address: caller,
                registration_time: current_time,
                score: 0,
                rank: 0,
                has_claimed_prize: false,
            };

            // Update state
            self.players.write(caller, player_info);
            let new_count = tournament.registered_players_count + 1;
            self.registered_players.write(new_count, caller);

            self
                .tournament_info
                .write(
                    TournamentInfo {
                        registered_players_count: new_count,
                        prize_pool: tournament.prize_pool + tournament.entry_fee,
                        ..tournament,
                    },
                );

            self
                .emit(
                    Event::PlayerRegistered(
                        PlayerRegistered { player: caller, registration_time: current_time },
                    ),
                );
        }

        fn start_tournament(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Only owner can start');

            let tournament = self.tournament_info.read();
            assert(tournament.state == TournamentState::Registration, 'Invalid state');
            assert(tournament.registered_players_count >= 2, 'Not enough players');

            let current_time = get_block_timestamp();
            assert(current_time >= tournament.start_time, 'Too early to start');

            self
                .tournament_info
                .write(TournamentInfo { state: TournamentState::InProgress, ..tournament });

            self
                .emit(
                    Event::TournamentStarted(
                        TournamentStarted {
                            start_time: current_time,
                            registered_players: tournament.registered_players_count,
                        },
                    ),
                );
        }

        fn end_tournament(ref self: ContractState, winner: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Only owner can end');

            let tournament = self.tournament_info.read();
            assert(tournament.state == TournamentState::InProgress, 'Tournament not in progress');
            assert(self.is_player_registered(winner), 'Winner not registered');

            let current_time = get_block_timestamp();

            self
                .tournament_info
                .write(TournamentInfo { state: TournamentState::Completed, winner, ..tournament });

            self
                .emit(
                    Event::TournamentEnded(
                        TournamentEnded {
                            end_time: current_time, winner, prize_pool: tournament.prize_pool,
                        },
                    ),
                );
        }

        // View functions
        fn get_tournament_status(self: @ContractState) -> TournamentState {
            self.tournament_info.read().state
        }

        fn get_tournament_info(self: @ContractState) -> TournamentInfo {
            self.tournament_info.read()
        }

        fn get_player_info(self: @ContractState, player: ContractAddress) -> PlayerInfo {
            self.players.read(player)
        }

        fn get_registered_players(self: @ContractState) -> Array<ContractAddress> {
            let tournament = self.tournament_info.read();
            let mut players = ArrayTrait::new();

            let mut i: u32 = 1;
            loop {
                if i > tournament.registered_players_count {
                    break;
                }
                players.append(self.registered_players.read(i));
                i += 1;
            };

            players
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn is_player_registered(self: @ContractState, player: ContractAddress) -> bool {
            let player_info = self.players.read(player);
            player_info.registration_time != 0
        }
    }
}
