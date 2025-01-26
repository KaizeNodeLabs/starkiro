use core::num::traits::Zero;
use starknet::{ContractAddress};


/// Check whether address felt is a valid starknet address
fn validate_starknet_address(address: felt252) -> (bool, ByteArray) {
    // Check if address is zero
    if address == Zero::zero() {
        return (false, "Zero Address");
    }

    // Check if felt is a valid a starknet address
    let contract_address: Option<ContractAddress> = address.try_into();
    if let Option::Some(_) = contract_address {
        return (true, "Valid starknet address");
    }
    return (false, "Invalid Address");
}


fn main() {
    let (check, msg) = validate_starknet_address(
        0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    );
    if (check) {
        println!("{}", msg);
    } else {
        println!("Invalid Address - Error: {}", msg);
    }
}
