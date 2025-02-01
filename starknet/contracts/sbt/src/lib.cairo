use starknet::ContractAddress;

#[starknet::interface]
pub trait ISBT<TState> {
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn ownerOf(self: @TState, token_id: u256) -> ContractAddress;
    fn safeTransferFrom(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn transferFrom(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn setApprovalForAll(ref self: TState, operator: ContractAddress, approved: bool);
    fn getApproved(self: @TState, token_id: u256) -> ContractAddress;
    fn isApprovedForAll(self: @TState, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn mint(ref self: TState, to: ContractAddress) -> u256;
    fn burn(ref self: TState, token_id: u256) -> bool;
    fn has_any_sbt(self: @TState, address: ContractAddress) -> bool;
}

#[starknet::contract]
pub mod SBT {
    use core::num::traits::Zero;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::interface::IERC721Metadata;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use core::starknet::{ContractAddress, get_caller_address};    

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // External
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    // Internal
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        nft_count: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: ByteArray, symbol: ByteArray, token_uri: ByteArray) {
        let caller = get_caller_address();

        self.ownable.initializer(caller);
        self.erc721.initializer(name, symbol, token_uri);
    }

    #[abi(embed_v0)]
    impl ERC721Metadata of IERC721Metadata<ContractState> {
        /// Returns the NFT name.
        fn name(self: @ContractState) -> ByteArray {
            self.erc721.ERC721_name.read()
        }

        /// Returns the NFT symbol.
        fn symbol(self: @ContractState) -> ByteArray {
            self.erc721.ERC721_symbol.read()
        }

        /// Returns the Uniform Resource Identifier (URI) for the `token_id` token.
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            self.erc721._base_uri()
        }
    }

    #[abi(embed_v0)]
    impl SBTImpl of super::ISBT<ContractState> {
        /// Returns the number of NFTs owned by `account`.
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc721.balance_of(account)
        }

        /// Returns the owner address of `token_id`.
        fn ownerOf(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.owner_of(token_id)
        }

        /// Transfers ownership of `token_id` from `from` if `to` is either an account or
        /// `IERC721Receiver`.
        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            panic!("SBT: Tokens are non-transferable");
        }

        /// Transfers ownership of `token_id` from `from` to `to`.
        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            panic!("SBT: Tokens are non-transferable");
        }

        /// Enable or disable approval for `operator` to manage all of the
        /// caller's assets.
        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            self.erc721.set_approval_for_all(operator, approved);
        }

        /// Returns the address approved for `token_id`.
        fn getApproved(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.get_approved(token_id)
        }

        /// Query if `operator` is an authorized operator for `owner`.
        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc721.is_approved_for_all(owner, operator)
        }

        /// Mints `token_id`, transfers it to `to` and returns the 'token_id'.
        fn mint(ref self: ContractState, to: ContractAddress) -> u256 {
            // access modifier for only owner
            self.ownable.assert_only_owner();

            let mut token_id = self.nft_count.read();

            if token_id < 1 {
                token_id += 1;
            }

            self.erc721.mint(to, token_id);
            self.nft_count.write(token_id + 1);
            token_id
        }

        // Burns user tokens 
        fn burn(ref self: ContractState, token_id: u256) -> bool {
            let token_owner = self.erc721.owner_of(token_id);
            let caller = get_caller_address();

            assert!(token_owner == caller, "Not token owner! Cannot burn unowned token");

            self.erc721.update(Zero::zero(), token_id, get_caller_address());

            true
        }

        fn has_any_sbt(self: @ContractState, address: ContractAddress) -> bool {
            let tokens = self.erc721.balance_of(address);
            tokens > 0
        }
    }

    /// An empty implementation of the ERC721 hooks.
    impl ERC721HooksEmptyImpl<
        TContractState
    > of ERC721Component::ERC721HooksTrait<TContractState> {}
}
