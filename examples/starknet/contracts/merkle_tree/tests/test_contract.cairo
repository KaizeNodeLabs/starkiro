use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use merkle_tree::MerkleTree::IMerkleTreeDispatcher;
use merkle_tree::MerkleTree::IMerkleTreeDispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_build_tree() {
    let contract_address = deploy_contract("MerkleTree");

    let dispatcher = IMerkleTreeDispatcher { contract_address };

    let mut data: Array<ByteArray> = array!["1", "2", "3", "4", "5", "6", "7", "8",];

    let hashes = dispatcher.build_tree(data);
    assert!(hashes.len() == 15);
}

#[test]
fn test_build_tree_uneven() {
    let contract_address = deploy_contract("MerkleTree");

    let dispatcher = IMerkleTreeDispatcher { contract_address };

    let mut data: Array<ByteArray> = array!["1", "2", "3", "4", "5", "6", "7",];

    let hashes = dispatcher.build_tree(data);
    assert!(hashes.len() == 15);
}

#[test]
fn test_get_root() {
    let contract_address = deploy_contract("MerkleTree");

    let dispatcher = IMerkleTreeDispatcher { contract_address };

    let mut data: Array<ByteArray> = array!["1", "2", "3", "4", "5", "6", "7", "8",];

    let hashes = dispatcher.build_tree(data);
    let root = dispatcher.get_root();
    assert!(root == *hashes.at(hashes.len() - 1));
}

#[test]
#[should_panic(expected: 'No element in merkle tree')]
fn test_get_root_raises() {
    let contract_address = deploy_contract("MerkleTree");
    let dispatcher = IMerkleTreeDispatcher { contract_address };

    dispatcher.get_root();
}

