use starknet::ContractAddress;
use core::poseidon::PoseidonTrait;
use core::hash::{HashStateTrait, HashStateExTrait};

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

    let mut data: Array<ByteArray> = array!["1", "2", "3", "4", "5", "6", "7", "8"];

    let hashes = dispatcher.build_tree(data);
    assert!(hashes.len() == 15);
    let hash_1 = dispatcher.hash("1");
    assert!(*hashes.at(0) == hash_1);

    let hash_1_2 = PoseidonTrait::new().update_with((hash_1, *hashes.at(1))).finalize();
    assert!(*hashes.at(8) == hash_1_2);

    let hash_3_4 = PoseidonTrait::new().update_with((*hashes.at(2), *hashes.at(3))).finalize();
    let hash_1_2_3_4 = PoseidonTrait::new().update_with((hash_1_2, hash_3_4)).finalize();
    assert!(*hashes.at(12) == hash_1_2_3_4);

    let hash_root = PoseidonTrait::new()
        .update_with((hash_1_2_3_4, *hashes.at(hashes.len() - 2)))
        .finalize();
    assert!(*hashes.at(hashes.len() - 1) == hash_root);
}

#[test]
fn test_build_tree_uneven() {
    let contract_address = deploy_contract("MerkleTree");

    let dispatcher = IMerkleTreeDispatcher { contract_address };

    let mut data: Array<ByteArray> = array!["1", "2", "3", "4", "5", "6", "7"];

    let hashes = dispatcher.build_tree(data);
    assert!(hashes.len() == 15);
}

#[test]
fn test_get_root() {
    let contract_address = deploy_contract("MerkleTree");

    let dispatcher = IMerkleTreeDispatcher { contract_address };

    let mut data: Array<ByteArray> = array!["1", "2", "3", "4", "5", "6", "7", "8"];

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

#[test]
fn test_verify_positive_4() {
    let contract_address = deploy_contract("MerkleTree");
    let dispatcher = IMerkleTreeDispatcher { contract_address };

    let mut data = array!["1", "2", "3", "4"];
    let hashes = dispatcher.build_tree(data);
    let root = dispatcher.get_root();
    assert!(root == *hashes.at(hashes.len() - 1));
    // to verify the 0th element exists in the tree:
    // we need to provide merkle proof array with
    // its sibling (1st) and the sibling of its intermediate node (hash of 2nd and 3rd)
    assert!(
        dispatcher.verify(array![*hashes.at(1), *hashes.at(5)], root, *hashes.at(0), 0) == true,
    );
}

#[test]
fn test_verify_positive_7() {
    let contract_address = deploy_contract("MerkleTree");
    let dispatcher = IMerkleTreeDispatcher { contract_address };
    // since data is uneven, the last element is added to the tree
    // [1, 2, 3, 4, 5, 6, 7] -> [1, 2, 3, 4, 5, 6, 7, 7]
    let mut data = array!["1", "2", "3", "4", "5", "6", "7"];
    let hashes = dispatcher.build_tree(data);
    let root = dispatcher.get_root();
    assert!(root == *hashes.at(hashes.len() - 1));
    // to verify the 3rd element exists in the tree:
    // we need to provide merkle proof array with
    // its sibling (2nd) and the sibling of its intermediate node (hash of 0th and 1st)
    // and the last sibling = (hash of (4th, 5st), (6th, 7th))
    assert!(
        dispatcher
            .verify(
                array![*hashes.at(2), *hashes.at(8), *hashes.at(13)], root, *hashes.at(3), 3,
            ) == true,
    );
}

#[test]
fn test_verify_positive_5() {
    let contract_address = deploy_contract("MerkleTree");
    let dispatcher = IMerkleTreeDispatcher { contract_address };
    // since data is uneven, the last element is added to the tree
    // [1, 2, 3, 4, 5] -> [1, 2, 3, 4, 5, 5]
    let mut data = array!["1", "2", "3", "4", "5"];
    // and data is even bot not a power of 2,
    // so the last hash on first level is duplicated
    // [((1, 2), (3, 4)), ((5, 5), (5, 5))]
    let hashes = dispatcher.build_tree(data);
    let root = dispatcher.get_root();
    assert!(root == *hashes.at(hashes.len() - 1));
    assert!(hashes.len() == 13);
    // to verify the 4th (last) element exists in the tree:
    // we need to provide merkle proof array with
    // its sibling (5th(duplicate of him)) and the sibling of its intermediate node (him and him)
    // and the last sibling = (hash of (0th, 1st, 2nd, 3rd))
    assert!(
        dispatcher
            .verify(
                array![*hashes.at(5), *hashes.at(9), *hashes.at(10)], root, *hashes.at(4), 4,
            ) == true,
    );
}

#[test]
fn test_verify_positive_6() {
    let contract_address = deploy_contract("MerkleTree");
    let dispatcher = IMerkleTreeDispatcher { contract_address };
    let mut data = array!["1", "2", "3", "4", "5", "6"];
    // data is even bot not a power of 2,
    // so the last hash on first level is duplicated
    // [((1, 2), (3, 4)), ((5, 6), (5, 6))]
    let hashes = dispatcher.build_tree(data);
    let root = dispatcher.get_root();
    assert!(root == *hashes.at(hashes.len() - 1));
    assert!(hashes.len() == 13);
    // to verify the 4th element exists in the tree:
    // we need to provide merkle proof array with
    // its sibling (5th) and the sibling of its
    // intermediate node (hash of him (4th) and his sibling (5th))
    // and the last sibling = (hash of (0th, 1st, 2nd, 3rd))
    assert!(
        dispatcher
            .verify(
                array![*hashes.at(5), *hashes.at(9), *hashes.at(10)], root, *hashes.at(4), 4,
            ) == true,
    );
}


#[test]
fn test_verify_positive_8() {
    let contract_address = deploy_contract("MerkleTree");
    let dispatcher = IMerkleTreeDispatcher { contract_address };
    let mut data = array!["1", "2", "3", "4", "5", "6", "7", "8"];
    let hashes = dispatcher.build_tree(data);
    let root = dispatcher.get_root();
    assert!(root == *hashes.at(hashes.len() - 1));
    // to verify the 5th element exists in the tree:
    // we need to provide merkle proof array with
    // its sibling (4th) and the sibling of its intermediate node (hash of 6th and 7th)
    // and the last sibling = (hash of (0th, 1st), (2nd, 3rd))
    assert!(
        dispatcher
            .verify(
                array![*hashes.at(4), *hashes.at(11), *hashes.at(12)], root, *hashes.at(5), 5,
            ) == true,
    );
}

#[test]
fn test_verify_negative() {
    let contract_address = deploy_contract("MerkleTree");
    let dispatcher = IMerkleTreeDispatcher { contract_address };
    let mut data = array!["1", "2", "3", "4", "5", "6", "7", "8"];
    let hashes = dispatcher.build_tree(data);
    let root = dispatcher.get_root();
    assert!(root == *hashes.at(hashes.len() - 1));
    // bad index
    assert!(
        dispatcher
            .verify(
                array![*hashes.at(4), *hashes.at(11), *hashes.at(12)], root, *hashes.at(5), 6,
            ) == false,
    );
    // bad proof
    assert!(
        dispatcher
            .verify(
                array![*hashes.at(4), *hashes.at(11), *hashes.at(13)], root, *hashes.at(5), 5,
            ) == false,
    );
    // bad root
    assert!(
        dispatcher
            .verify(
                array![*hashes.at(4), *hashes.at(11), *hashes.at(12)],
                *hashes.at(0),
                *hashes.at(5),
                5,
            ) == false,
    );
}
