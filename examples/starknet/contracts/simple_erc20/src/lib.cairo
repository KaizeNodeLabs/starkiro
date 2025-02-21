use starknet::ContractAddress;

// Interface for the mint() and burn() functions
#[starknet::interface]
pub trait IERC20MintingAndBurning<TState> {
    fn mint(ref self: TState, to: ContractAddress, amount: u256);
    fn burn(ref self: TState, amount: u256);
}

#[starknet::contract]
mod MyToken {
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::{ContractAddress, get_caller_address};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        // Add owner field
        owner: ContractAddress,
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        let name = "MyToken";
        let symbol = "MTK";
        self.erc20.initializer(name, symbol);

        // Initialize owner
        self.owner.write(owner);
    }

    // Mint() and burn() external functions  
    #[abi(embed_v0)]
    impl MyToken of super::IERC20MintingAndBurning<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            // Check that the caller is the owner
            assert(self._check_owner() == true, 'Just the owner can mint tokens');

            // Mint the tokens
            self.erc20.mint(to, amount);
        }

        fn burn(ref self: ContractState, amount: u256) {
            self.erc20.burn(get_caller_address(), amount);
        }
    }

    // Internal function for checking that the caller is the owner
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _check_owner(self: @ContractState) -> bool {
            return get_caller_address() == self.owner.read();
        }
    }
}
