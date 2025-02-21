use starknet::ContractAddress;

#[starknet::interface]
pub trait IStaking<TContractState> {
    fn last_time_reward_applicable(self: @TContractState) -> u256;
    fn reward_per_token(self: @TContractState) -> u256;
    fn stake(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
    fn earned(self: @TContractState, account: ContractAddress) -> u256;
    fn get_reward(ref self: TContractState);
    fn set_rewards_duration(ref self: TContractState, duration: u256);
    fn notify_reward_amount(ref self: TContractState, amount: u256);

    fn staking_token(self: @TContractState) -> ContractAddress;
    fn rewards_token(self: @TContractState) -> ContractAddress;
    fn duration(self: @TContractState) -> u256;
    fn finish_at(self: @TContractState) -> u256;
    fn updated_at(self: @TContractState) -> u256;
    fn reward_rate(self: @TContractState) -> u256;
    fn reward_per_token_stored(self: @TContractState) -> u256;
    fn user_reward_per_token_paid(self: @TContractState, user: ContractAddress) -> u256;
    fn rewards(self: @TContractState, user: ContractAddress) -> u256;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, user: ContractAddress) -> u256;
    fn owner(self: @TContractState) -> ContractAddress;

    fn return_block_timestamp(self: @TContractState) -> u256;
}
