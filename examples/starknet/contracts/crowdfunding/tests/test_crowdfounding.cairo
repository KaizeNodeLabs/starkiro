use starknet::{ContractAddress, contract_address_const};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, cheat_caller_address, CheatSpan,
    cheat_block_timestamp,
};

use crowdfunding::crowdfunding::{
    Crowdfunding::CampaignState, ICrowdfundingDispatcher, ICrowdfundingDispatcherTrait,
};

fn deploy_contract() -> (ContractAddress, ICrowdfundingDispatcher) {
    let contract = declare("Crowdfunding").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    (contract_address, ICrowdfundingDispatcher { contract_address })
}

fn create_address() -> ContractAddress {
    contract_address_const::<0x123>()
}

#[test]
fn test_create_campaign() {
    // Set up the test environment
    let (contract, dispatcher) = deploy_contract();
    let creator = create_address();

    // Defining the campaign parameters
    let campaign_id = 1;
    let funding_goal = 1000_u64;
    let current_time = 1000_u64;
    let deadline = current_time + 86400_u64;

    // Establishing the current time
    cheat_block_timestamp(contract, current_time, CheatSpan::TargetCalls(1));

    // Creating the campaign
    // assign the caller as the creator
    cheat_caller_address(contract, creator, CheatSpan::TargetCalls(2));
    dispatcher.create_campaign(campaign_id, funding_goal, deadline);

    // Verify that the campaign was created successfully
    let campaign = dispatcher.get_campaign(campaign_id);
    assert_eq!(campaign.funding_goal, funding_goal, "Incorrect funding goal");
    assert_eq!(campaign.deadline, deadline, "Incorrect deadline");
    assert_eq!(campaign.state, CampaignState::Active, "Incorrect state");
    assert_eq!(campaign.creator, creator, "Incorrect creator");
}

#[test]
fn test_contribute_to_campaign() {
    // Set up the test environment
    let (contract, dispatcher) = deploy_contract();
    let creator = create_address();
    let contributor = contract_address_const::<0x456>();

    // Create a campaign
    cheat_caller_address(contract, creator, CheatSpan::TargetCalls(1));
    let campaign_id = 1;
    let funding_goal = 1000_u64;
    let current_time = 1000_u64;
    let deadline = current_time + 86400_u64;

    cheat_block_timestamp(contract, current_time, CheatSpan::TargetCalls(1));
    dispatcher.create_campaign(campaign_id, funding_goal, deadline);

    // Simulate a contribution
    cheat_caller_address(contract, contributor, CheatSpan::TargetCalls(2));
    dispatcher.contribute(campaign_id);

    // Verify that the contribution was successful
    let contribution = dispatcher.get_contribution(campaign_id, contributor);
    assert_eq!(
        contribution, 100_u64, "Incorrect contribution amount",
    ); //100 is the default contribution amount
}

#[test]
fn test_finalize_successful_campaign() {
    // Set up the test environment
    let (contract, dispatcher) = deploy_contract();
    let creator = create_address();
    let contributor1 = contract_address_const::<0x456>();
    let contributor2 = contract_address_const::<0x789>();

    // Create a campaign
    cheat_caller_address(contract, creator, CheatSpan::TargetCalls(1));
    let campaign_id = 1;
    let funding_goal = 1000_u64;
    let current_time = 1000_u64;
    let deadline = current_time + 86400_u64;

    cheat_block_timestamp(contract, current_time, CheatSpan::TargetCalls(3));
    dispatcher.create_campaign(campaign_id, funding_goal, deadline);

    // Simulate contributions that reach the goal
    cheat_caller_address(contract, contributor1, CheatSpan::TargetCalls(1));
    dispatcher.contribute(campaign_id);

    cheat_caller_address(contract, contributor2, CheatSpan::TargetCalls(3));
    dispatcher.contribute(campaign_id);

    // Advance the time beyond the deadline
    cheat_block_timestamp(contract, deadline + 1, CheatSpan::TargetCalls(2));

    // Finalize the campaign
    dispatcher.finalize_campaign(campaign_id);

    // Verify that the campaign was successful
    let campaign = dispatcher.get_campaign(campaign_id);
    assert_eq!(campaign.state, CampaignState::Successful, "Campaign should be successful");
}

#[test]
fn test_refund_failed_campaign() {
    // Set up the test environment
    let (contract, dispatcher) = deploy_contract();
    let creator = create_address();
    let contributor = contract_address_const::<0x456>();

    // Create a campaign
    cheat_caller_address(contract, creator, CheatSpan::TargetCalls(1));
    let campaign_id = 1;
    let funding_goal = 1000_u64;
    let current_time = 1000_u64;
    let deadline = current_time + 86400_u64;

    cheat_block_timestamp(contract, current_time, CheatSpan::TargetCalls(2));
    dispatcher.create_campaign(campaign_id, funding_goal, deadline);

    // Simulate a contribution that does not reach the goal
    cheat_caller_address(contract, contributor, CheatSpan::TargetCalls(5));
    dispatcher.contribute(campaign_id);

    // Advance the time beyond the deadline
    cheat_block_timestamp(contract, deadline + 1, CheatSpan::TargetCalls(1));

    // Finialize the campaign
    dispatcher.finalize_campaign(campaign_id);

    // Verify that the campaign failed
    let campaign = dispatcher.get_campaign(campaign_id);
    assert_eq!(campaign.state, CampaignState::Failed, "Campaign should have failed");

    // Request a refund
    dispatcher.refund_contribution(campaign_id);

    // Verifiy that the refund was successful
    let contribution = dispatcher.get_contribution(campaign_id, contributor);
    assert_eq!(contribution, 0_u64, "Contribution should be 0 after refund");
}

#[test]
#[should_panic(expected: "Campaign already exists")]
fn test_create_duplicate_campaign() {
    let (contract, dispatcher) = deploy_contract();
    let creator = create_address();
    cheat_caller_address(contract, creator, CheatSpan::TargetCalls(3));

    let campaign_id = 1;
    let funding_goal = 1000_u64;
    let current_time = 1000_u64;
    let deadline = current_time + 86400_u64;

    cheat_block_timestamp(contract, current_time, CheatSpan::TargetCalls(2));
    // Create a campaign
    dispatcher.create_campaign(campaign_id, funding_goal, deadline);

    // try to create the same campaign again
    dispatcher.create_campaign(campaign_id, funding_goal, deadline);
}
