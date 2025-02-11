use starknet::{ContractAddress, contract_address_const};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use random_number_generator::RandomNumberGeneratorContract::IRandomNumberGeneratorContractDispatcher;
use random_number_generator::RandomNumberGeneratorContract::IRandomNumberGeneratorContractDispatcherTrait;

use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

const ADDRESS_WITH_ETH_1: felt252 =
    0x0416575467BBE3E3D1ABC92d175c71e06C7EA1FaB37120983A08b6a2B2D12794;
const ADDRESS_WITH_ETH_2: felt252 =
    0x0092fB909857ba418627B9e40A7863F75768A0ea80D306Fb5757eEA7DdbBd4Fc;

const PRAGMA_VRF_ADDRESS: felt252 =
    0x60c69136b39319547a4df303b6b3a26fab8b2d78de90b6bd215ce82e9cb515c;
const ETH_ADDRESS: felt252 = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

fn deploy_contract() -> ContractAddress {
    let contract = declare("RandomNumberGeneratorContract").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_get_random_number_with_block_data() {
    let contract_address = deploy_contract();
    let dispatcher = IRandomNumberGeneratorContractDispatcher { contract_address };
    let entropy_injector = 356; // any random value 
    dispatcher.get_random_number_with_block_data(entropy_injector);
}

#[test]
fn get_random_number_with_keccak256() {
    let contract_address = deploy_contract();
    let dispatcher = IRandomNumberGeneratorContractDispatcher { contract_address };
    let entropy_injector = 356; // any random value 
    dispatcher.get_random_number_with_keccak256(entropy_injector);
}

#[test]
fn get_random_number_with_user_entropy() {
    let contract_address = deploy_contract();
    let dispatcher = IRandomNumberGeneratorContractDispatcher { contract_address };
    let entropy_injector = array![345, 231, 535, 6566]; // any random values 
    dispatcher.get_random_number_with_user_entropy(entropy_injector);
}

#[test]
#[fork(url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_number: 388964)]
fn get_random_number_with_vrf() {
    let contract_address = deploy_contract();
    let dispatcher = IRandomNumberGeneratorContractDispatcher { contract_address };

    // Prefunding VRF contract
    let eth_dispatcher = IERC20Dispatcher {
        contract_address: contract_address_const::<ETH_ADDRESS>() // ETH Contract Address
    };
    start_cheat_caller_address(
        eth_dispatcher.contract_address, contract_address_const::<ADDRESS_WITH_ETH_2>(),
    );
    eth_dispatcher.transfer(dispatcher.contract_address, 20000000000000000);
    stop_cheat_caller_address(eth_dispatcher.contract_address);
    //

    start_cheat_caller_address(contract_address, contract_address_const::<ADDRESS_WITH_ETH_1>());
    dispatcher.get_random_number_with_vrf();
}
