use starknet::ContractAddress;


#[starknet::interface]
pub trait IEscrow<TContractState> {
    fn get_order_amount(self: @TContractState, order_id: u256) -> u256;
    fn get_order_recipient_address(
        self: @TContractState, order_id: u256, recipient: felt252
    ) -> ContractAddress;
    fn get_order_state(self: @TContractState, order_id: u256) -> felt252;
    fn create_order(
        ref self: TContractState,
        amount: u256,
        recipients: Array<felt252>,
        addresses: Array<ContractAddress>
    ) -> u256;
    fn cancel_order(ref self: TContractState, order_id: u256);
    fn complete_order(ref self: TContractState, order_id: u256, winner: felt252);
    fn pay_order(ref self: TContractState, order_id: u256);
}

#[starknet::contract]
pub mod Escrow {
    use starknet::storage::{
        StorageMapReadAccess, StoragePointerReadAccess, StoragePointerWriteAccess,
        StorageMapWriteAccess, Map
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[constructor]
    fn constructor(ref self: ContractState, token_address: ContractAddress) {
        self.erc20.write(IERC20Dispatcher { contract_address: token_address });
        self.token_address.write(token_address);
    }

    #[storage]
    struct Storage {
        orders: u256,
        orders_amount: Map<u256, u256>,
        orders_addresses: Map<(u256, felt252), ContractAddress>,
        order_states: Map<u256, felt252>,
        erc20: IERC20Dispatcher,
        token_address: ContractAddress,
    }

    #[abi(embed_v0)]
    impl Escrow of super::IEscrow<ContractState> {
        fn get_order_amount(self: @ContractState, order_id: u256) -> u256 {
            self.orders_amount.read(order_id)
        }

        fn get_order_recipient_address(
            self: @ContractState, order_id: u256, recipient: felt252
        ) -> ContractAddress {
            self.orders_addresses.read((order_id, recipient))
        }

        fn get_order_state(self: @ContractState, order_id: u256) -> felt252 {
            self.order_states.read(order_id)
        }

        fn create_order(
            ref self: ContractState,
            amount: u256,
            recipients: Array<felt252>,
            addresses: Array<ContractAddress>
        ) -> u256 {
            let order_id = self.orders.read() + 1;
            self.orders.write(order_id);
            self.orders_amount.write(order_id, amount);
            assert(recipients.len() == addresses.len(), 'Different lengths');
            let mut idx = 0;
            loop {
                if idx == recipients.len() {
                    break;
                }
                let recipient = *recipients.at(idx);
                let address = *addresses.at(idx);
                self.orders_addresses.write((order_id, recipient), address);
                idx += 1;
            };

            self.order_states.write(order_id, 'NotPaid');
            order_id
        }

        fn cancel_order(ref self: ContractState, order_id: u256) {
            self.order_states.write(order_id, 'Cancelled');
        }

        fn complete_order(ref self: ContractState, order_id: u256, winner: felt252) {
            let state = self.order_states.read(order_id);
            assert(state == 'Paid', 'Order is not paid');

            let amount = self.orders_amount.read(order_id);
            let winner_address = self.orders_addresses.read((order_id, winner));

            let dispatcher = IERC20Dispatcher { contract_address: self.token_address.read() };
            let result = dispatcher.transfer(winner_address, amount);

            assert(result, 'ERC20_TRANSFER_FAILED');
            self.order_states.write(order_id, 'Completed');
        }

        fn pay_order(ref self: ContractState, order_id: u256) {
            let state = self.order_states.read(order_id);
            assert(state == 'NotPaid', 'Order is not payable');

            let amount = self.orders_amount.read(order_id);
            let dispatcher = IERC20Dispatcher { contract_address: self.token_address.read() };

            let caller = get_caller_address();
            self._validate(caller, amount);

            let result = dispatcher.transfer_from(caller, get_contract_address(), amount);
            assert(result, 'ERC20_TRANSFER_FAILED');

            self.order_states.write(order_id, 'Paid');
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _validate(
            ref self: ContractState,
            buyer: ContractAddress,
            amount: u256
        ) {
            let buyer_balance = self.erc20.read().balance_of(buyer);
            assert(buyer_balance >= amount, 'ERC20_NOT_SUFFICIENT_AMOUNT');
        }
    }
}
