use snforge_std::DeclareResultTrait;
use starknet::{ContractAddress, get_block_timestamp, contract_address_const};

use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait};

use token_vesting::vesting::{IVestingDispatcher};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher};
use token_vesting::mocks::free_erc20::{IFreeMintDispatcher, IFreeMintDispatcherTrait};

pub const ONE_E18: u256 = 1000000000000000000_u256;

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn RECIPIENT() -> ContractAddress {
    contract_address_const::<'RECIPIENT'>()
}

pub fn OTHER() -> ContractAddress {
    contract_address_const::<'OTHER'>()
}

pub fn OTHER_ADMIN() -> ContractAddress {
    contract_address_const::<'OTHER_ADMIN'>()
}

pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}

pub fn declare_and_deploy(contract_name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(contract_name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

pub fn deploy_erc20() -> ContractAddress {
    let mut calldata = array![];
    let initial_supply: u256 = 1000_000_000_u256;
    let name: ByteArray = "DummyERC20";
    let symbol: ByteArray = "DUMMY";

    calldata.append_serde(initial_supply);
    calldata.append_serde(name);
    calldata.append_serde(symbol);
    let erc20_address = declare_and_deploy("FreeMintERC20", calldata);

    erc20_address
}

pub fn deploy_vesting_contract() -> IVestingDispatcher {
    let mut calldata = array![];
    calldata.append_serde(OWNER());
    let vesting_contract = declare_and_deploy("Vesting", calldata);
    IVestingDispatcher { contract_address: vesting_contract }
}

pub fn setup() -> (IVestingDispatcher, IERC20Dispatcher) {
    let erc20_address = deploy_erc20();
    let initial_amount: u256 = 1_000_000_u256 * ONE_E18;
    IFreeMintDispatcher { contract_address: erc20_address }.mint(OWNER(), initial_amount);
    let erc20_contract = IERC20Dispatcher { contract_address: erc20_address };
    let vesting_contract = deploy_vesting_contract();
    (vesting_contract, erc20_contract)
}


pub fn generate_schedule(duration_in_secs: u64, cliff: bool) -> (u64, u64, u64) {
    let start_time = get_block_timestamp() + 1000_u64;

    let cliff_time = if cliff {
        start_time + (duration_in_secs / 5_u64) // 20% = 1/5
    } else {
        start_time
    };

    let end_time = start_time + duration_in_secs;

    (start_time, cliff_time, end_time)
}
