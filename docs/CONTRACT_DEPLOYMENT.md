# 🚀 Deployment Guide for Starknet Smart Contracts by Stark Cairo Nodes

This guide provides step-by-step instructions for deploying smart contracts on Starknet using **Remix IDE** and **sncast**. It covers the installation, compilation, and deployment processes for proper use of the IDE and sncast



---
## 📚 Table of Contents
1. [🚢 Deployment of Contracts using IDE](#-1-deployment-of-contracts-using-ide)

2. [🚢 Deployment of Contracts using sncast](#-2-deployment-of-contracts-using-sncast)
---

---
## 🚀 1. Deployment of Contracts using IDE
The following steps are required for deployment of contracts using IDE


a. [⚙️ Prerequisites](#️-a-prerequisites)
b. [🔌 Installing the Starknet Plugin](#-b-installing-the-starknet-plugin)
c. [🛠️ Compiling Smart Contracts](#️-c-compiling-smart-contracts)
d. [🚢 Deploying Contracts](#-d-deploying-contracts)
e. [📄 Example Deployment](#-e-example-deployment)
f. [🔗 Troubleshooting Tips](#-f-troubleshooting-tips)

---

---

## 🚀 2. Deployment of Contracts using sncast
The following steps are required for deployment of contracts using sncast


a. [🏗️ Building the Contract](#a-️-building-the-contract)
b. [👤 Account Setup](#b--account-setup)
c. [📄 Contract Deployment](#c--contract-deployment)
d. [✅ Verifying Deployment](#d--verifying-deployment)



---
---
## 🚀 1. Deployment of Contracts using IDE

<!-- Deploying smart contract using IDE 👇 -->

## ⚙️ a. Prerequisites
Ensure you have the following before starting:
- **Remix IDE**: [Access Remix IDE](https://remix.ethereum.org/)
- Starknet Wallet (Argent X or Braavos).
- Access to the `stark-cairo-nodes` repository: [GitHub Repo](https://github.com/KaizeNodeLabs/stark-cairo-nodes).

## 🔌 b. Installing the Starknet Plugin
Follow these steps to install the `Starknet` plugin on Remix IDE:

1. Open **Remix IDE**.
2. Navigate to the **Plugin Manager**.
3. Search for **Starknet** and click "Activate".
4. Click to **Install** the plugin.

Once activated, you will see a Starknet tab in Remix.

## 🛠️ c. Compiling Smart Contracts
To compile contracts in Remix using the Starknet plugin:

**Open Remix IDE** and create a new workspace
   - In the **File Explorer**, click **Create** → **New Workspace**.
   - Name the workspace as needed.

1. **Create a New File**
   - Within the new workspace, click **New File**.
   - Name the file `hello_world.cairo`.

2. **Copy and Paste the Contract Code**
   - Go to the [`stark-cairo-nodes`](https://github.com/KaizeNodeLabs/stark-cairo-nodes) repository.
   - Navigate to `examples/contracts/helloWorld/hello_world.cairo`.
   - Copy the contents of the file.
   - Paste the code into the new `hello_world.cairo` file in Remix.

3. **Compile the Contract**
   - Select the `hello_world.cairo` file in the File Explorer.
   - Open the **Starknet** tab in Remix IDE.
   - Click **Compile** to generate the compiled artifacts.

#### **Example Contract: `helloWorld`**
Here is the `HelloWorld` contract used in this guide:

```rust
#[starknet::interface] 
pub trait ISimpleHelloWorld<TContractState> {
    fn get_hello_world(self: @TContractState) -> felt252;
    fn set_hello_world(ref self: TContractState);
}

#[starknet::contract]
pub mod SimpleHelloWorld {
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    #[storage]
    struct Storage {
        stored_data: felt252
    }

    #[abi(embed_v0)]
    impl SimpleHelloWorld of super::ISimpleHelloWorld<ContractState> {
        fn set_hello_world(ref self: ContractState) {
            self.stored_data.write('Hello world!')
        }

        fn get_hello_world(self: @ContractState) -> felt252 {
            self.stored_data.read()
        }
    }
}
```

> **Note**: Ensure the contract is error-free before proceeding.

## 🚢 d. Deploying Contracts
Steps to deploy a compiled contract:

1. Open the Starknet `tab` in Remix IDE.
2. Navigate to the **Deployment** section.
3. Connect your Starknet wallet (Argent X).
4. Upload the compiled contract and click **Deploy**.
5. Confirm the transaction in your wallet.

After deployment, you will receive a **Contract Address**.

---

## 📄 e. Example Deployment
**To demonstrate, we deploy the `HelloWorld` from this repository:**

1. **Compile the Contract:** 
```bash
Open the `HelloWorld` contract in Remix and click Compile in the Starknet tab.
```

2. **Connect Your Wallet:** 
```bash
Use the Connect Wallet button to link your Starknet wallet (Argent X).
```

3. **Deploy the Contract:** 
```bash
In the Deployment section of the Starknet tab, select the compiled SimpleHelloWorld contract and click Deploy.
```

4. **Deployment Result:** Once the deployment succeeds, a message will show a contract address:
```rust
Contract address: 0x0123456789ABCDEF
```

5. **Interact with the Contract:**
```bash
 Use the functions set_hello_world and get_hello_world to test the contract.
 ```


## 🔗 f. Troubleshooting Tips
- **Compilation errors**: 
  - Ensure the contract is written in the correct Starknet-compatible syntax.
  - Update the Starknet plugin to the latest version if needed.

- **Wallet connection issues**:
  - Refresh both Remix IDE and your wallet extension.
  - Confirm that your wallet is connected to the correct network (Testnet or Mainnet).
  
- **Deployment failure**:
  - Check if you have sufficient balance for deployment fees.
  - Double-check your network configuration in the wallet.


## 📝 Additional Notes
- Reference this guide in the root `README.md` for clarity.
- Follow our guidelines for further contributions.

<!-- Deploying smart contract using IDE 👆 -->

---

---


# 🚀2. Deploying Smart Contracts on Sepolia testnet using sncast

<!-- Deploying smart contract on sepolia using sncast 👇 -->

## 📖 Overview

This guide demonstrates how to deploy a Starknet smart contract to Sepolia testnet using `sncast`. We'll use the SimpleHelloWorld contract as an example to walk through the entire deployment process.

## ⚙️ Steps to Deploy Your Contract

### a. 🏗️ Building the Contract

First, let's prepare and build our contract:

```bash
# Navigate to the contract directory
cd examples/starknet/contracts/hello_world

# Build the contract
scarb build

# Run tests to verify everything works
scarb test
```

### b. 👤 Account Setup

#### Create New Account
```bash
sncast account create \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --name my_deployer_account
```

⚠️ **Important**: Save the output address and max_fee information

In this case, account address : 0x03d18e21dcb1f460c287af9b84e6da83b5577569e69371d39ad3415067abdbc4

![Account Creation](https://github.com/user-attachments/assets/a1038a13-4860-496e-9584-9d7c540aaf23)

🔍 View your account at:
https://sepolia.starkscan.co/contract/0x03d18e21dcb1f460c287af9b84e6da83b5577569e69371d39ad3415067abdbc4

#### Get Test Tokens (or fund with Sepolia test tokens from existing braavos or argent x wallet )
1. Visit [Sepolia STRK Faucet](https://faucet.sepolia.starknet.io/strk)
2. Visit [Sepolia ETH Faucet](https://faucet.sepolia.starknet.io/eth)
3. Request tokens for your account address
4. Monitor on [Starkscan](https://sepolia.starkscan.co)

#### Deploy Account
```bash
sncast account deploy \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --name my_deployer_account
```

![Account Deployment](https://github.com/user-attachments/assets/23ef6213-8a84-477f-8fd1-51a76558d558)

🔍 Track deployment:
https://sepolia.starkscan.co/tx/0x073e6c7e7efea34708a73fcfdbfa5fef911e5516a5e7ea6b48814c6d4c4bd281

### c. 📄 Contract Deployment

#### Declare Contract
```bash
sncast --account my_deployer_account declare \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --contract-name SimpleHelloWorld
```

⚠️ **Important**: Save the class_hash from the output

![Contract Declaration](https://github.com/user-attachments/assets/f1db05e8-5e5c-49c3-8464-77ec9c88ab19)

Class-hash : 0x0574f6f6f9c70bbbcd08260a78653e1a21e48c4027375d2113e286883c9e513f

🔍 Verify declaration:
- Class: https://sepolia.starkscan.co/class/0x0574f6f6f9c70bbbcd08260a78653e1a21e48c4027375d2113e286883c9e513f
- Transaction: https://sepolia.starkscan.co/tx/0x00a678cb5bfed2508583f27e82879dd1e2f7c6010b1b8435c7829def3192bc24

#### Deploy Contract
```bash
sncast --account my_deployer_account deploy \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --class-hash 0x0574f6f6f9c70bbbcd08260a78653e1a21e48c4027375d2113e286883c9e513f
```

![Contract Deployment](https://github.com/user-attachments/assets/014a2082-b549-4369-9040-d7e14e4ed967)

Contract deployed at address : 0x003b6059a58c96c5db118808d722f240797223900248201250e9e8b4aa34c033

🔍 Track deployment:
- Contract: https://sepolia.starkscan.co/contract/0x003b6059a58c96c5db118808d722f240797223900248201250e9e8b4aa34c033
- Transaction: https://sepolia.starkscan.co/tx/0x005abf392b7828aae946f271b5560ec54414dfaf5b324de14deb4f1fd5fa19a5

### d. ✅ Verifying Deployment

#### Set Contract Value
```bash
sncast --account my_deployer_account invoke \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --contract-address 0x003b6059a58c96c5db118808d722f240797223900248201250e9e8b4aa34c033 \
    --function set_hello_world
```

![Setting Value](https://github.com/user-attachments/assets/5239e43b-5a61-4eff-bb85-a0fd9cdf4bd2)

🔍 View transaction:
https://sepolia.starkscan.co/tx/0x076143df3b9b9341a39b205a600177f632b96b4f38430569ee3d15deb57b8466

#### Read Contract Value
```bash
sncast --account my_deployer_account call \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --contract-address 0x003b6059a58c96c5db118808d722f240797223900248201250e9e8b4aa34c033 \
    --function get_hello_world
```

![Reading Value](https://github.com/user-attachments/assets/08c4bde6-7713-4e17-b8f7-5f37b1a3ee5c)

The successful execution of these steps confirms your contract is properly deployed and functional on the Sepolia testnet. 🎉

<!-- Deploying smart contract on sepolia using sncast 👆 -->

---
#### **Happy Coding!** 🎄🎅
