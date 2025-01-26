use starknet::ContractAddress;

#[derive(Drop, Serde, Copy, starknet::Store)]
pub struct Schedule {
    pub recipient: ContractAddress,
    pub token: ContractAddress,
    pub start_time: u64,
    pub cliff_time: u64,
    pub end_time: u64,
    pub total_claimed: u256,
    pub total_amount: u256,
}


#[starknet::interface]
pub trait IOwnable<ContractState> {
    fn owner(self: @ContractState) -> ContractAddress;
}

#[starknet::interface]
pub trait IVesting<ContractState> {
    fn add_schedule(
        ref self: ContractState,
        token: ContractAddress,
        recipient: ContractAddress,
        start_time: u64,
        cliff_time: u64,
        end_time: u64,
        total_amount: u256,
    );

    fn add_schedule_with_percentage(
        ref self: ContractState,
        token: ContractAddress,
        recipient: ContractAddress,
        start_time: u64,
        cliff_time: u64,
        end_time: u64,
        total_amount: u256,
        percentage: u256,
    );

    fn remove_schedule(
        ref self: ContractState,
        token: ContractAddress,
        address_to_end: ContractAddress,
        refund_address: ContractAddress,
    );

    fn claim(ref self: ContractState, token: ContractAddress);

    fn get_vested_amount(self: @ContractState, user: ContractAddress) -> u256;

    fn get_claimable_amount(self: @ContractState, user: ContractAddress) -> u256;

    fn get_user_vesting_schedule(self: @ContractState, user: ContractAddress) -> Schedule;
}

#[starknet::contract]
pub mod Vesting {
    use core::num::traits::Zero;
    use starknet::event::EventEmitter;
    use super::{IVesting, Schedule};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use core::starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, get_contract_address,
        contract_address_const,
    };
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry,
    };

    // Ownable Component
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        schedules: Map<ContractAddress, Schedule>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        NewScheduleAdded: NewScheduleAdded,
        SuccessfulClaim: SuccessfulClaim,
        VestingEndedByOwner: VestingEndedByOwner,
    }

    #[derive(Drop, starknet::Event)]
    pub struct NewScheduleAdded {
        pub recipient: ContractAddress,
        pub token: ContractAddress,
        pub start_time: u64,
        pub cliff_time: u64,
        pub end_time: u64,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct SuccessfulClaim {
        pub recipient: ContractAddress,
        pub token: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct VestingEndedByOwner {
        pub address_ended: ContractAddress,
        pub token: ContractAddress,
        pub amount_withdrawn: u256,
        pub amount_refunded: u256,
    }

    pub mod Errors {
        pub const ZERO_ADDRESS: felt252 = 'Zero address detected';
        pub const ZERO_AMOUNT: felt252 = 'Amount cannot be zero';
        pub const INVALID_CLIFF_TIME: felt252 = 'Cliff time is invalid';
        pub const INVALID_END_TIME: felt252 = 'End time is invalid';
        pub const INVALID_PERCENTAGE: felt252 = 'Percentage greater than 100';
        pub const TOKEN_TRANSFER_FAILED: felt252 = 'Token transfer failed';
        pub const ALREADY_HAS_LOCK: felt252 = 'User already has lock';
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        assert(!owner.is_zero(), Errors::ZERO_ADDRESS);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl VestingImpl of IVesting<ContractState> {
        fn add_schedule(
            ref self: ContractState,
            token: ContractAddress,
            recipient: ContractAddress,
            start_time: u64,
            cliff_time: u64,
            end_time: u64,
            total_amount: u256,
        ) {
            self.ownable.assert_only_owner();
            assert(total_amount > 0, Errors::ZERO_AMOUNT);
            assert(cliff_time >= start_time, Errors::INVALID_CLIFF_TIME);
            assert(end_time >= cliff_time, Errors::INVALID_END_TIME);

            let schedule = self.get_user_vesting_schedule(recipient);

            assert(schedule.total_amount == 0, Errors::ALREADY_HAS_LOCK);

            let this_contract = get_contract_address();
            let token_dispatcher = IERC20Dispatcher { contract_address: token };
            assert(
                token_dispatcher.transfer(this_contract, total_amount),
                Errors::TOKEN_TRANSFER_FAILED,
            );

            let new_schedule = Schedule {
                recipient: recipient,
                token: token,
                start_time: start_time,
                cliff_time: cliff_time,
                end_time: end_time,
                total_claimed: 0,
                total_amount: total_amount,
            };

            self.schedules.entry(recipient).write(new_schedule);
            self
                .emit(
                    NewScheduleAdded {
                        recipient: recipient,
                        token: token,
                        start_time: start_time,
                        cliff_time: cliff_time,
                        end_time: end_time,
                        amount: total_amount,
                    },
                );
        }

        fn add_schedule_with_percentage(
            ref self: ContractState,
            token: ContractAddress,
            recipient: ContractAddress,
            start_time: u64,
            cliff_time: u64,
            end_time: u64,
            total_amount: u256,
            percentage: u256,
        ) {
            self.ownable.assert_only_owner();
            assert(percentage <= 100, Errors::INVALID_PERCENTAGE);

            let lock_amount = (total_amount * percentage) / 100;
            self.add_schedule(token, recipient, start_time, cliff_time, end_time, lock_amount);
        }

        fn remove_schedule(
            ref self: ContractState,
            token: ContractAddress,
            address_to_end: ContractAddress,
            refund_address: ContractAddress,
        ) {
            self.ownable.assert_only_owner();
            let mut amount_refundable = 0;
            let mut amount_withdrawable = 0;

            let schedule = self.get_user_vesting_schedule(address_to_end);

            if get_block_timestamp() < schedule.cliff_time {
                amount_refundable = schedule.total_amount;
            } else {
                let amount_vested = self.get_vested_amount(address_to_end);
                amount_withdrawable = amount_vested - schedule.total_claimed;
                amount_refundable = schedule.total_amount - amount_vested;
            }

            if amount_refundable > 0 {
                let token_dispatcher = IERC20Dispatcher { contract_address: token };

                assert(
                    token_dispatcher.transfer(refund_address, amount_refundable),
                    Errors::TOKEN_TRANSFER_FAILED,
                );
            }

            if amount_withdrawable > 0 {
                let token_dispatcher = IERC20Dispatcher { contract_address: token };

                assert(
                    token_dispatcher.transfer(address_to_end, amount_withdrawable),
                    Errors::TOKEN_TRANSFER_FAILED,
                );
            }

            let empty_schedule = Schedule {
                recipient: self.zero_address(),
                token: token,
                start_time: 0,
                cliff_time: 0,
                end_time: 0,
                total_claimed: 0,
                total_amount: 0,
            };

            self.schedules.entry(address_to_end).write(empty_schedule);

            self
                .emit(
                    VestingEndedByOwner {
                        address_ended: address_to_end,
                        token: token,
                        amount_withdrawn: amount_withdrawable,
                        amount_refunded: amount_refundable,
                    },
                )
        }

        fn claim(ref self: ContractState, token: ContractAddress) {
            let caller = get_caller_address();
            let schedule = self.get_user_vesting_schedule(caller);
            let claimable = self.get_claimable_amount(caller);

            if claimable > 0 {
                let mut updated_schedule = schedule;
                updated_schedule.total_claimed = updated_schedule.total_claimed + claimable;
                self.schedules.entry(caller).write(updated_schedule);

                let token_dispatcher = IERC20Dispatcher { contract_address: token };

                assert(token_dispatcher.transfer(caller, claimable), Errors::TOKEN_TRANSFER_FAILED);

                self.emit(SuccessfulClaim { recipient: caller, token: token, amount: claimable });
            }
        }

        fn get_vested_amount(self: @ContractState, user: ContractAddress) -> u256 {
            let schedule = self.get_user_vesting_schedule(user);

            let now = get_block_timestamp();

            if now < schedule.cliff_time {
                0
            } else if now >= schedule.end_time {
                schedule.total_amount
            } else {
                let elapsed_time = now - schedule.start_time;
                let total_duration = schedule.end_time - schedule.start_time;
                (schedule.total_amount * elapsed_time.into()) / total_duration.into()
            }
        }

        fn get_claimable_amount(self: @ContractState, user: ContractAddress) -> u256 {
            let schedule = self.get_user_vesting_schedule(user);
            let vested_amount = self.get_vested_amount(user);

            if vested_amount > schedule.total_claimed {
                vested_amount - schedule.total_claimed
            } else {
                0
            }
        }

        fn get_user_vesting_schedule(self: @ContractState, user: ContractAddress) -> Schedule {
            self.schedules.entry(user).read()
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn zero_address(self: @ContractState) -> ContractAddress {
            contract_address_const::<0>()
        }
    }
}
