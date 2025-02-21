use starknet::ContractAddress;

//mock erc20
#[starknet::interface]
pub trait IFreeMint<T> {
    fn mint(ref self: T, recipient: ContractAddress, amount: u256);
}

#[starknet::contract]
mod FreeMintERC20 {
    use openzeppelin_token::erc20::ERC20Component;
    use openzeppelin_token::erc20::ERC20HooksEmptyImpl;
    use starknet::ContractAddress;
    use super::IFreeMint;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_supply: u256,
        name: core::byte_array::ByteArray,
        symbol: core::byte_array::ByteArray,
    ) {
        self.erc20.initializer(name, symbol);
    }

    #[abi(embed_v0)]
    impl ImplFreeMint of IFreeMint<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.erc20.mint(recipient, amount);
        }
    }
}
