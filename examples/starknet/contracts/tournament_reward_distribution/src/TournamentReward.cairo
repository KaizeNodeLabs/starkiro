use starknet::ContractAddress;

#[starknet::interface]
pub trait ITournamentReward<TContractState> {
    fn distribute_tournament_rewards(
        ref self: TContractState,
        first: ContractAddress,
        score1: u32,
        second: ContractAddress,
        score2: u32,
        third: ContractAddress,
        score3: u32,
    );
    fn claim_reward(ref self: TContractState);
    fn get_winner_info(ref self: TContractState, winner: ContractAddress) -> (u32, u256, bool, u64);

    fn update_prize_pool(ref self: TContractState, amount: u256);
    fn end_tournament(ref self: TContractState);
    fn get_prize_pool(self: @TContractState) -> u256;
    fn is_tournament_ended(self: @TContractState) -> bool;
}

#[starknet::contract]
pub mod TournamentReward {
    use starknet::storage::StoragePathEntry;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_block_timestamp};
    use core::starknet::storage::{Map};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    //use super::;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        prize_pool: u256,
        rewards_distributed: bool,
        tournament_ended: bool,
        winners: Map<u32, RewardInfo>,
        winner_to_rank: Map<ContractAddress, u32>,
        total_claimed_amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, initial_prize_pool: u256) {
        self.owner.write(owner);
        self.prize_pool.write(initial_prize_pool);
        self.tournament_ended.write(false);
        self.rewards_distributed.write(false);
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    pub struct RewardInfo {
        winner: ContractAddress,
        score: u32,
        reward_amount: u256,
        claimed: bool,
        claim_timestamp: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        RewardDistributed: RewardDistributed,
        RewardClaimed: RewardClaimed,
        PrizePoolUpdated: PrizePoolUpdated,
        TournamentEnded: TournamentEnded,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RewardDistributed {
        pub first: ContractAddress,
        pub second: ContractAddress,
        pub third: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PrizePoolUpdated {
        pub old_amount: u256,
        pub new_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TournamentEnded {
        pub timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RewardClaimed {
        pub winner: ContractAddress,
        pub amount: u256,
    }


    mod RewardError {
        pub const OnlyOwner: felt252 = 'OnlyOwner';
        pub const TournamentNotEnded: felt252 = 'Tournament not ended';
        pub const RewardsNotDistributed: felt252 = 'RewardsNotDistributed';
        pub const RewardsAlreadyDistributed: felt252 = 'Rewards Distributed';
        pub const DuplicateWinners: felt252 = 'Duplicate Winners';
        pub const InvalidScores: felt252 = 'InvalidScores';
        pub const PrizePoolEmpty: felt252 = 'PrizePool Empty';
        pub const TotalRewardsExceedPrizePool: felt252 = 'TotalRewardsExceedPrizePool';
        pub const NotAWinner: felt252 = 'NotAWinner';
        pub const AlreadyClaimed: felt252 = 'AlreadyClaimed';
    }

    #[abi(embed_v0)]
    impl ITournamentReward of super::ITournamentReward<ContractState> {
        fn end_tournament(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), RewardError::OnlyOwner);
            assert(!self.tournament_ended.read(), 'Tournament already ended');
            self.tournament_ended.write(true);
            self.emit(Event::TournamentEnded(TournamentEnded { timestamp: get_block_timestamp() }));
        }

        fn update_prize_pool(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), RewardError::OnlyOwner);
            assert(!self.rewards_distributed.read(), 'Rewards already distributed');
            let old_amount = self.prize_pool.read();
            self.prize_pool.write(amount);
            self.emit(Event::PrizePoolUpdated(PrizePoolUpdated { old_amount, new_amount: amount }));
        }

        fn distribute_tournament_rewards(
            ref self: ContractState,
            first: ContractAddress,
            score1: u32,
            second: ContractAddress,
            score2: u32,
            third: ContractAddress,
            score3: u32,
        ) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), RewardError::OnlyOwner);
            assert(!self.rewards_distributed.read(), RewardError::RewardsAlreadyDistributed);
            assert(self.tournament_ended.read(), RewardError::TournamentNotEnded);
            assert(
                first != second && second != third && first != third, RewardError::DuplicateWinners,
            );
            assert(score1 > 0 && score2 > 0 && score3 > 0, RewardError::InvalidScores);

            let prize_pool = self.prize_pool.read();
            assert(prize_pool > 0, RewardError::PrizePoolEmpty);

            let reward_first = (prize_pool * 50) / 100;
            let reward_second = (prize_pool * 30) / 100;
            let reward_third = (prize_pool * 20) / 100;
            let total_rewards = reward_first + reward_second + reward_third;

            assert(total_rewards <= prize_pool, RewardError::TotalRewardsExceedPrizePool);

            self
                .winners
                .entry(1)
                .write(
                    RewardInfo {
                        winner: first,
                        score: score1,
                        reward_amount: reward_first,
                        claimed: false,
                        claim_timestamp: 0,
                    },
                );
            self
                .winners
                .entry(2)
                .write(
                    RewardInfo {
                        winner: second,
                        score: score2,
                        reward_amount: reward_second,
                        claimed: false,
                        claim_timestamp: 0,
                    },
                );
            self
                .winners
                .entry(3)
                .write(
                    RewardInfo {
                        winner: third,
                        score: score3,
                        reward_amount: reward_third,
                        claimed: false,
                        claim_timestamp: 0,
                    },
                );

            self.winner_to_rank.entry(first).write(1);
            self.winner_to_rank.entry(second).write(2);
            self.winner_to_rank.entry(third).write(3);

            self.rewards_distributed.write(true);

            self.emit(Event::RewardDistributed(RewardDistributed { first, second, third }));
        }

        fn claim_reward(ref self: ContractState) {
            let winner = get_caller_address();
            assert(self.rewards_distributed.read(), RewardError::RewardsNotDistributed);

            let rank = self.winner_to_rank.entry(winner).read();
            assert(rank > 0, RewardError::NotAWinner);

            let mut reward_info = self.winners.entry(rank).read();
            assert(!reward_info.claimed, RewardError::AlreadyClaimed);

            reward_info.claimed = true;
            reward_info.claim_timestamp = get_block_timestamp();
            self.winners.entry(rank).write(reward_info);

            let current_claimed = self.total_claimed_amount.read();
            let amount = reward_info.reward_amount;
            self.total_claimed_amount.write(current_claimed + amount);

            self.emit(Event::RewardClaimed(RewardClaimed { winner, amount }));
        }

        fn get_winner_info(
            ref self: ContractState, winner: ContractAddress,
        ) -> (u32, u256, bool, u64) {
            let rank = self.winner_to_rank.entry(winner).read();
            assert(rank > 0, RewardError::NotAWinner);

            let reward_info = self.winners.entry(rank).read();
            (rank, reward_info.reward_amount, reward_info.claimed, reward_info.claim_timestamp)
        }

        fn get_prize_pool(self: @ContractState) -> u256 {
            self.prize_pool.read()
        }

        fn is_tournament_ended(self: @ContractState) -> bool {
            self.tournament_ended.read()
        }
    }
}
