use tournament_reward_distribution::TournamentReward::{
    ITournamentRewardDispatcher, ITournamentRewardDispatcherTrait, TournamentReward,
};
use snforge_std::DeclareResultTrait;
use snforge_std::{
    CheatSpan, ContractClassTrait, EventSpyAssertionsTrait, cheat_caller_address, declare,
    spy_events,
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

fn deploy_rewards_contract(prize_pool: u256) -> ContractAddress {
    let contract_class = declare("TournamentReward").unwrap().contract_class();
    let mut calldata = array![];
    calldata.append(owner().into());
    calldata.append(prize_pool.low.into()); // u256.low
    calldata.append(prize_pool.high.into()); // u256.high
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_distribute_rewards() {
    let total_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(total_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };
    let score1 = 56_u32;
    let score2 = 34_u32;
    let score3 = 38_u32;

    let mut spy = spy_events();

    // End tournament first
    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.end_tournament();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.distribute_tournament_rewards(player1(), score1, player2(), score2, player3(), score3);

    let winner_info_1 = rewards.get_winner_info(player1());
    let winner_info_2 = rewards.get_winner_info(player2());
    let winner_info_3 = rewards.get_winner_info(player3());

    // Using proper tuple destructuring
    let (_, reward_1, _, _) = winner_info_1;
    let (_, reward_2, _, _) = winner_info_2;
    let (_, reward_3, _, _) = winner_info_3;

    assert!(reward_1 == 500, "Player 1 reward incorrect");
    assert!(reward_2 == 300, "Player 2 reward incorrect");
    assert!(reward_3 == 200, "Player 3 reward incorrect");

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    TournamentReward::Event::TournamentEnded(
                        TournamentReward::TournamentEnded {
                            timestamp: starknet::get_block_timestamp(),
                        },
                    ),
                ),
                (
                    contract_address,
                    TournamentReward::Event::RewardDistributed(
                        TournamentReward::RewardDistributed {
                            first: player1(), second: player2(), third: player3(),
                        },
                    ),
                ),
            ],
        );
}

#[test]
fn test_claim_reward() {
    let total_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(total_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };
    let score1 = 56_u32;
    let score2 = 34_u32;
    let score3 = 38_u32;

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.end_tournament();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.distribute_tournament_rewards(player1(), score1, player2(), score2, player3(), score3);

    let mut spy = spy_events();
    cheat_caller_address(contract_address, player1(), CheatSpan::TargetCalls(1));
    rewards.claim_reward();

    let winner_info = rewards.get_winner_info(player1());

    let (_, _, claimed, _) = winner_info;
    assert!(claimed == true, "Reward claim status not updated");

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    TournamentReward::Event::RewardClaimed(
                        TournamentReward::RewardClaimed { winner: player1(), amount: 500 },
                    ),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('NotAWinner',))]
fn test_non_winner_cannot_claim() {
    let total_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(total_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };
    let score1 = 56_u32;
    let score2 = 34_u32;
    let score3 = 38_u32;

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.end_tournament();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.distribute_tournament_rewards(player1(), score1, player2(), score2, player3(), score3);

    cheat_caller_address(
        contract_address, contract_address_const::<'player4'>(), CheatSpan::TargetCalls(1),
    );
    rewards.claim_reward();
}

#[test]
#[should_panic(expected: ('AlreadyClaimed',))]
fn test_cannot_claim_twice() {
    let total_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(total_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };
    let score1 = 56_u32;
    let score2 = 34_u32;
    let score3 = 38_u32;

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.end_tournament();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.distribute_tournament_rewards(player1(), score1, player2(), score2, player3(), score3);

    cheat_caller_address(contract_address, player1(), CheatSpan::TargetCalls(2));
    rewards.claim_reward();
    rewards.claim_reward();
}

#[test]
#[should_panic(expected: ('Tournament not ended',))]
fn test_cannot_distribute_rewards_before_end() {
    let total_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(total_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };
    let score1 = 56_u32;
    let score2 = 34_u32;
    let score3 = 38_u32;

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.distribute_tournament_rewards(player1(), score1, player2(), score2, player3(), score3);
}

#[test]
fn test_update_prize_pool() {
    let initial_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(initial_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };

    let mut spy = spy_events();
    let new_prize_pool: u256 = 2000;

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.update_prize_pool(new_prize_pool);

    assert!(rewards.get_prize_pool() == new_prize_pool, "Prize pool not updated");

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    TournamentReward::Event::PrizePoolUpdated(
                        TournamentReward::PrizePoolUpdated {
                            old_amount: initial_prize_pool, new_amount: new_prize_pool,
                        },
                    ),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: ('OnlyOwner',))]
fn test_non_owner_cannot_update_prize_pool() {
    let initial_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(initial_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };

    cheat_caller_address(contract_address, player1(), CheatSpan::TargetCalls(1));
    rewards.update_prize_pool(2000);
}

#[test]
fn test_end_tournament() {
    let total_prize_pool: u256 = 1000;
    let contract_address = deploy_rewards_contract(total_prize_pool);
    let rewards = ITournamentRewardDispatcher { contract_address };

    let mut spy = spy_events();

    cheat_caller_address(contract_address, owner(), CheatSpan::TargetCalls(1));
    rewards.end_tournament();

    assert!(rewards.is_tournament_ended() == true, "Tournament not ended");

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    TournamentReward::Event::TournamentEnded(
                        TournamentReward::TournamentEnded {
                            timestamp: starknet::get_block_timestamp(),
                        },
                    ),
                ),
            ],
        );
}
