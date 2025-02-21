# Counter Access Control Contract Documentation

## Overview

This contract provides a counter functionality with limited access control functionalities.
Authorized owners can increase or decrease the value displayed by the counter,
while limiting the use in order to avoid any changes by other persons who may have access to the contract.

## Key Features

- Increment and decrement counter values
- Get current counter value
- Retrieve owner address
- Add new owners

## Usage

Here's a breakdown of how to use the **CounterAccessControl** contract:

### Public Methods

1. **_Increase Counter:_**
   _fn increase_counter(ref self: TContractState)_

   - Increases the counter value by 1.
   - Only the owner can all the contract.

2. **_Decrease Counter:_**
   _fn decrease_counter(ref self: TContractState)_

   - Decreases the counter value by 1.
   - Only the owner can all the contract.

3. **_Get Current Counter Value:_**
   _fn get_counter(self: @TContractState) -> u32_

   - Retrieves the current value of the counter without modifying it.

4. **_Get Owner Address:_**
   _fn get_owner(self: @TContractState) -> ContractAddress_

   - Returns the address of the current owner of the contract.

5. **_Add New Owner:_**
   _fn add_new_owner(ref self: TContractState, new_owner: ContractAddress)_
   - Changes the ownership of the contract to a new address.
   - Only callable by the current owner.

### Private Methods

Not all functions are accessible through external calls, these internal methods are crucial for those contract's functionality:

1. **Initialize Contract: fn initialize_contract()**

   - Deploys the full specification of the contract at the moment when the contract is initiated,
     specifying the owner and the counter value of 0.

2. **Update Owner: fn update_owner(new_owner address.Contract)**

   - Internal method called by \_add_new_owner func to change the actual owner address.

3. **Validate Caller: fn validate_caller()**

   - Verifies if the speaker of the function call is the current owner of the contract.

4. **Increment Counter: fn increment_counter()**
   - Internal method called by the public method \_increase_counter to raise the counter value.
5. **Decrement Counter: fn decrement_counter()**
   - Internal method that contains the logic of counter deflation which is invoked by \_decrease_counter.

## Events

- `CounterIncreased`: Emitted when the counter is increased.
- `CounterDecreased`: Emitted when the counter is decreased.
- `OwnerChanged`: Emitted when the contract owner is updated.

## Contract Structure

- `counter`: Saves the current value stored in the counter – unsigned u32
- `owner`: Saves the address of the contract owner so that anyone can view the contract owner’s address (ContractAddress)

## Security Considerations

- Counter can be changed only by the owner

- Eliminates zero address exploits

- Prevents unauthorized addition of new owners to prevent unauthorized access

## Use Cases

- A counter with an access control mechanism, restricting unauthorized users
- Basic voting system
- Resource allocation tracker

## Upgrades

- This contract supports upgrades using [proxy pattern](https://docs.openzeppelin.com/upgrades/4.8/proxies)

## How the Contract Works

The contract uses a combination of public and private methods to ensure secure and controlled access to the counter functionality:

1. When the contract is created, it sets an owner account and a counter value to start with before any interaction.
2. The _validate_caller()_ method ensures that the caller made the counter or owner therefore allowing any changes to it.
3. The _increment_counter()_ and _decrement_counter()_ methods are responsible for the actual modification of counter value.
4. The _update_owner()_ function is tasked with the function of updating the owner address.

## References for Newcomers

For those new to Cairo and StarkNet development, here are some recommended resources:

1. **Cairo Language Tutorial:** [Cairo Programming Language Documentation](https://www.google.com/search?client=ubuntu&channel=fs&q=Cairo+Programming+Language+Documentation+)
2. **StarkNet Developer Portal:** [StarkNet Developers Guide](https://www.google.com/search?client=ubuntu&channel=fs&q=StarkNet+Developers+Guide+)
3. .**Cairo Cookbook:** [Cairo Cookbook](https://www.google.com/search?client=ubuntu&channel=fs&q=Cairo+Cookbook+)
4. **StarkNet Book:StarkNet:** [An Introduction to Shards](https://www.google.com/search?client=ubuntu&channel=fs&q=StarkNet%3A+An+Introduction+to+Shards+)

These will ensure that you get to know how Cairo programming language works, architecture of StarkNet
besides other important things when developing smart contracts on StarkNet.

## Note:

Refer to this link for all the necessary installations [asdf documentation](https://asdf-vm.com/guide/getting-started.html)
