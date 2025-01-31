![DARK LOGO](https://github.com/user-attachments/assets/b91f4412-9790-4ac1-99af-098dbfbb922f)




# STARKIRO 🔗💡

## 📖 Overview

**STARKIRO** is a collection of educational scripts built using the Cairo programming language, specifically designed for the Starknet ecosystem. These scripts are ideal for both beginners and intermediate developers looking to deepen their understanding of Cairo and Starknet concepts.

## ⚙️ Steps to Build and Run Cairo Scripts

### 1. 🛠️ **Set Up Your Environment**

- **Install Cargo**

  Scarb, the official build tool for Cairo, relies on Cargo as a dependency. Cargo is included with the Rust programming language. Follow these steps to install Cargo:

  Visit the [Rust installation page](https://doc.rust-lang.org/cargo/getting-started/installation.html) and follow the instructions to install Rust, which includes Cargo.

   Alternatively, use the appropriate command for your operating system
    - **Linux and macOS**
      ```bash
      curl https://sh.rustup.rs -sSf | sh
      ```
    - **Windows**
      Download and run the installer from the [official Rust website](https://www.rust-lang.org/tools/install).

- **Verify Cargo Installation**

  Confirm that Cargo is installed by checking its version:

```bash
cargo --version
```
   
- **Install Scarb**

  Please refer to the [asdf documentation](https://asdf-vm.com/guide/getting-started.html) to install all prerequisites

  To get started, install Scarb by running the following commands in your terminal:

```bash
  asdf plugin add scarb
  asdf install scarb latest
  asdf global scarb latest
```

- **Verify Scarb Installation**

  Confirm that Scarb is installed correctly by checking its version:

```bash
scarb --version
```

### 2. 📂 **Navigate to the Scripts Directory**

First, navigate to the general cairo/scripts/ directory:

```bash
cd cairo/scripts/
```

Then, navigate to the specific script's directory you want to run. For example, if the script you want to execute is in a folder named example_script, navigate into that directory:

```bash
cd example_script
```

### 3. 🏗️ **Build the Project**

Build the project with the following command:

```bash
scarb build
```

### 4. 🚀 **Run the Script**

To execute the main function of the script, use:

```bash
scarb cairo-run
```
<!-- Deploying smart contract on sepolia using sncast 👇 -->

# 🚀 Deploying Smart Contracts on Sepolia using sncast

## 📖 Overview

This guide demonstrates how to deploy a Starknet smart contract to Sepolia testnet using `sncast`. We'll use the SimpleHelloWorld contract as an example to walk through the entire deployment process.

## ⚙️ Steps to Deploy Your Contract

### 1. 🏗️ Building the Contract

First, let's prepare and build our contract:

```bash
# Navigate to the contract directory
cd starknet/contracts/hello_world

# Build the contract
scarb build

# Run tests to verify everything works
scarb test
```

### 2. 👤 Account Setup

#### Create New Account
```bash
sncast account create \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --name my_deployer_account
```

⚠️ **Important**: Save the output address and max_fee information

![Account Creation](https://github.com/user-attachments/assets/a1038a13-4860-496e-9584-9d7c540aaf23)

🔍 View your account at:
https://sepolia.starkscan.co/contract/0x03d18e21dcb1f460c287af9b84e6da83b5577569e69371d39ad3415067abdbc4

#### Get Test Tokens
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

### 3. 📄 Contract Deployment

#### Declare Contract
```bash
sncast --account my_deployer_account declare \
    --url https://free-rpc.nethermind.io/sepolia-juno/v0_7 \
    --contract-name SimpleHelloWorld
```

⚠️ **Important**: Save the class_hash from the output

![Contract Declaration](https://github.com/user-attachments/assets/f1db05e8-5e5c-49c3-8464-77ec9c88ab19)

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

🔍 Track deployment:
- Contract: https://sepolia.starkscan.co/contract/0x003b6059a58c96c5db118808d722f240797223900248201250e9e8b4aa34c033
- Transaction: https://sepolia.starkscan.co/tx/0x005abf392b7828aae946f271b5560ec54414dfaf5b324de14deb4f1fd5fa19a5

### 4. ✅ Verifying Deployment

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

## ⚙️ Steps to build and and test contracts

### 1. 🛠️ **Set Up Your Environment** 

- **Install Cargo**

  Scarb, the official build tool for Cairo, relies on Cargo as a dependency. Cargo is included with the Rust programming language. Follow these steps to install Cargo:

  Visit the [Rust installation page](https://doc.rust-lang.org/cargo/getting-started/installation.html) and follow the instructions to install Rust, which includes Cargo.

   Alternatively, use the appropriate command for your operating system
    - **Linux and macOS**
      ```bash
      curl https://sh.rustup.rs -sSf | sh
      ```
    - **Windows**
      Download and run the installer from the [official Rust website](https://www.rust-lang.org/tools/install).

- **Verify Cargo Installation**

  Confirm that Cargo is installed by checking its version:

```bash
cargo --version
```

-**Install asdf**
Before installing Scarb, you have to install asdf by following the [official asdf docs](https://asdf-vm.com/guide/getting-started.html#getting-started)

- **Verify asdf Installation**

  Confirm that asdf is installed by checking its version:

```bash
asdf --version
```

- **Install Scarb**
Before you can build and test Cairo contracts, you need to have Scarb, the official build tool for Cairo. 
Install it with these steps:

```bash
asdf plugin add scarb
asdf install scarb latest
```

- **Install Starknet Foundry**
Install SnForge (Cairo Testing Framework) SnForge is the tool used to run unit tests for Cairo contracts in the Starknet ecosystem. Install it by running:

```bash
asdf plugin add starknet-foundry
asdf install starknet-foundry latest
```
### 2. ✅ Verify Installations
After installation, confirm that both tools are correctly installed by running:

For Scarb:

```bash
scarb --version
```

For SnForge:

```bash
snforge --version
```

### 3. 📂 Navigate to the Contract Directory
Proceed to the directory where your Cairo contract is located.

Example:

```bash
cd path/to/your/cairo-contract-directory
```

### 4. 🏗️ Compile the Contract
Use Scarb to compile your Cairo contract by running:

```bash
scarb build
```
This will generate the necessary artifacts for your Cairo contract.

### 5. 🏃 Run Unit Tests with SnForge
Once the contract is compiled, you can run unit tests using SnForge. .

To run your contract's tests, use the following command:

```bash
snforge test
```
SnForge will automatically detect the test files in your project and run them.

### 6. 🔁 Review Test Results
After running the tests, you will see the results in your terminal. If the tests fail, the output will include details that will help you debug the issue. If everything passes, you’ll see confirmation that your contract is working as expected.



## 🔧 Managing Dependencies with .tool-versions

### Purpose of .tool-versions

The `.tool-versions` file is a configuration file used by [asdf](https://asdf-vm.com/) to manage the versions of tools and dependencies required for each script or contract. It ensures consistency across development environments and helps avoid version mismatches.

When you navigate to a directory containing a `.tool-versions` file, `asdf` automatically switches to the specified versions of the tools listed in the file.

### Example of a .tool-versions File

Here is an example of how a `.tool-versions` file might look:

```plaintext
scarb 0.5.2
cairo-lang 2.0.0
```

This example specifies that the project requires Scarb version `0.5.2` and Cairo version `2.0.0`.

### Common Errors and Warnings

If you attempt to compile a Cairo file with incorrect versions of dependencies, you may encounter an error like this:

```plaintext
Error: No such command `cairo-build`. Please ensure you have the correct version of Cairo installed.
```

To resolve this, navigate to the directory containing the `.tool-versions` file and run:

```bash
asdf install
```

This will install the correct versions of the tools specified in the `.tool-versions` file.

### Best Practices

- Always check the `.tool-versions` file in the script or contract directory before building or running.
- Use `asdf install` to ensure all required dependencies are correctly installed.




## Give us a star! ⭐
