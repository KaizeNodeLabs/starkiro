use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC1155<TContractState> {
    fn balance_of(self: @TContractState, account: ContractAddress, token_id: u256) -> u256;
    fn balance_of_batch(
        self: @TContractState, accounts: Span<ContractAddress>, token_ids: Span<u256>,
    ) -> Span<u256>;
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        value: u256,
        data: Span<felt252>,
    );
    fn safe_batch_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_ids: Span<u256>,
        values: Span<u256>,
        data: Span<felt252>,
    );
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress,
    ) -> bool;
    fn uri(self: @TContractState, token_id: u256) -> ByteArray;
}

#[starknet::contract]
pub mod ERC1155 {
    use super::IERC1155;
    use core::num::traits::Zero;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};

    pub mod Errors {
        pub const UNAUTHORIZED: felt252 = 'ERC1155: unauthorized operator';
        pub const SELF_APPROVAL: felt252 = 'ERC1155: self approval';
        pub const INVALID_RECEIVER: felt252 = 'ERC1155: invalid receiver';
        pub const INVALID_SENDER: felt252 = 'ERC1155: invalid sender';
        pub const INVALID_ARRAY_LENGTH: felt252 = 'ERC1155: no equal array length';
        pub const INSUFFICIENT_BALANCE: felt252 = 'ERC1155: insufficient balance';
        pub const SAFE_TRANSFER_FAILED: felt252 = 'ERC1155: safe transfer failed';
    }

    #[storage]
    pub struct Storage {
        pub ERC1155_balances: Map<(u256, ContractAddress), u256>,
        pub ERC1155_operator_approvals: Map<(ContractAddress, ContractAddress), bool>,
        pub ERC1155_uri: ByteArray,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    pub enum Event {
        TransferSingle: TransferSingle,
        TransferBatch: TransferBatch,
        ApprovalForAll: ApprovalForAll,
        URI: URI,
    }

    /// Emitted when `value` token is transferred from `from` to `to` for `id`.
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct TransferSingle {
        #[key]
        pub operator: ContractAddress,
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        pub id: u256,
        pub value: u256,
    }

    /// A TransferBatch Event, emitted when values token `id`s are transferred from `from` to `to`
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct TransferBatch {
        #[key]
        pub operator: ContractAddress,
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        pub ids: Span<u256>,
        pub values: Span<u256>,
    }

    /// Emitted when `account` enables or disables (`approved`) `operator` to manage
    /// all of its assets.
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct ApprovalForAll {
        #[key]
        pub owner: ContractAddress,
        #[key]
        pub operator: ContractAddress,
        pub approved: bool,
    }

    /// Emitted when the URI for token type `id` changes to `value`
    #[derive(Drop, PartialEq, starknet::Event)]
    pub struct URI {
        pub value: ByteArray,
        #[key]
        pub id: u256,
    }

    /// CONSTRUCTOR
    /// Sets a new URI for all token types, by relying on the token type ID
    /// substitution mechanism defined in the ERC1155 standard.
    /// See https://eips.ethereum.org/EIPS/eip-1155#metadata.
    ///
    /// By this mechanism, any occurrence of the `\{id\}` substring in either the
    /// URI or any of the values in the JSON file at said URI will be replaced by
    /// clients with the token type ID.
    ///
    /// For example, the `https://token-cdn-domain/\{id\}.json` URI would be
    /// interpreted by clients as
    /// `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
    /// for token type ID 0x4cce0.
    ///
    /// Because these URIs cannot be meaningfully represented by the `URI` event,
    /// this function emits no events.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        token_uri: ByteArray,
        recipient: ContractAddress,
        token_ids: Span<u256>,
        values: Span<u256>,
    ) {
        self.ERC1155_uri.write(token_uri);
        // mint
        self.batch_mint(Zero::zero(), recipient, token_ids, values, array![].span());
    }

    /// ABI
    #[abi(embed_v0)]
    pub impl ERC1155Impl of super::IERC1155<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress, token_id: u256) -> u256 {
            self.ERC1155_balances.read((token_id, account))
        }

        /// Returns a list of balances derived from the `accounts` and `token_ids` pairs.
        /// accounts and token_ids must have the same length.
        fn balance_of_batch(
            self: @ContractState, accounts: Span<ContractAddress>, token_ids: Span<u256>,
        ) -> Span<u256> {
            assert(accounts.len() == token_ids.len(), Errors::INVALID_ARRAY_LENGTH);

            let mut batch_balances = array![];
            for i in 0..token_ids.len() {
                batch_balances.append(self.balance_of(*accounts.at(i), *token_ids.at(i)));
            };

            batch_balances.span()
        }

        /// Enables or disables approval for `operator` to manage all of the
        /// callers assets.
        /// caller must not be the `operator`
        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool,
        ) {
            let owner = get_caller_address();
            assert(owner.is_non_zero(), 'ZERO ADDRESS CALLER');
            assert(owner != operator, Errors::SELF_APPROVAL);

            self.ERC1155_operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner, operator, approved });
        }

        /// When using this function in real life, Ensure to follow the checks-effects-interactions
        /// pattern and consider employing reentrancy guards when interacting with untrusted
        /// contracts.
        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            value: u256,
            data: Span<felt252>,
        ) {
            let token_ids = array![token_id].span();
            let values = array![value].span();
            self.safe_batch_transfer_from(from, to, token_ids, values, data);
        }

        fn safe_batch_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>,
        ) {
            assert(from.is_non_zero(), Errors::INVALID_SENDER);
            assert(to.is_non_zero(), Errors::INVALID_RECEIVER);

            let operator = get_caller_address();
            if from != operator {
                assert(self.is_approved_for_all(from, operator), Errors::UNAUTHORIZED);
            }
            self.batch_mint(from, to, token_ids, values, data);
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress,
        ) -> bool {
            self.ERC1155_operator_approvals.read((owner, operator))
        }

        /// check out https://eips.ethereum.org/EIPS/eip-1155#metadata for more info on how this
        /// may be used.
        fn uri(self: @ContractState, token_id: u256) -> ByteArray {
            self.ERC1155_uri.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn batch_mint(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>,
        ) {
            assert(to.is_non_zero(), Errors::INVALID_RECEIVER);
            assert(token_ids.len() == values.len(), Errors::INVALID_ARRAY_LENGTH);

            for i in 0..token_ids.len() {
                let token_id = *token_ids.at(i);
                let value = *values.at(i);
                if from.is_non_zero() { // update from's balance, it's a transfer, not a mint.
                    let from_balance = self.ERC1155_balances.read((token_id, from));
                    assert(from_balance >= value, Errors::INSUFFICIENT_BALANCE);
                    self.ERC1155_balances.write((token_id, from), from_balance - value);
                }
                if to.is_non_zero() {
                    let to_balance = self.ERC1155_balances.read((token_id, to));
                    self.ERC1155_balances.write((token_id, to), to_balance + value);
                }
            };

            let operator = get_caller_address();
            if token_ids.len() == 1 {
                self
                    .emit(
                        TransferSingle {
                            operator, from, to, id: *token_ids.at(0), value: *values.at(0),
                        },
                    );
            } else {
                self.emit(TransferBatch { operator, from, to, ids: token_ids, values });
            }
        }
    }
}

