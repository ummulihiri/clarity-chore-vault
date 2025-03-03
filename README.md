# ChoreVault
A family chore management smart contract with reward systems for kids on the Stacks blockchain.

## Features
- Create and manage family accounts
- Add and assign chores with reward amounts
- Complete chores and earn rewards
- Transfer rewards between family members
- View chore history and reward balances

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Create a family account (parent only)
(contract-call? .chore-vault create-family 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Add a chore (parent only)
(contract-call? .chore-vault add-chore "Clean room" u100 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Complete a chore
(contract-call? .chore-vault complete-chore u1)

;; Check reward balance
(contract-call? .chore-vault get-reward-balance 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
