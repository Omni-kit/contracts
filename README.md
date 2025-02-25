# DeploymentFactory Project

## Description
This project features a single factory contract, `DeploymentFactory`, designed to deploy smart contracts across multiple Superchains in a gas-efficient manner. By paying gas fees on just one Superchain, the contract leverages the Optimism L2-to-L2 Cross-Domain Messenger to deploy a specified smart contract on all targeted Superchains simultaneously. This approach simplifies multi-chain deployment, ensuring deterministic contract addresses via CREATE2 and reducing operational overhead by centralizing gas costs.

Key features:
- **Multi-Chain Deployment**: Deploys contracts on multiple Superchains with a single transaction.
- **Gas Efficiency**: Gas fees are paid only on the initiating Superchain.
- **Deterministic Addresses**: Uses CREATE2 with a salt for consistent contract addresses across chains.

The project includes deployment scripts and a comprehensive test suite to verify functionality.

## Setup Steps for Testing Deployment Scripts

To test the deployment and test deployment scripts, follow these steps. This assumes you’re using Supersim (a simulation environment for Optimism Superchains) and Foundry for development.

### Prerequisites
- **Foundry**: Install Foundry by following the [official instructions](https://book.getfoundry.sh/getting-started/installation).
- **Supersim**: Clone and install Supersim from its repository (e.g., `git clone https://github.com/ethereum-optimism/supersim` and follow its setup guide).
- **Dependencies**: Ensure project dependencies (e.g., `optimism-contracts`, `forge-std`) are installed via `forge install`.

### Steps
1. **Start Supersim with Auto-Relay**:
   - In one terminal, navigate to your Supersim directory and start it with the auto-relay feature to simulate multiple Superchains (e.g., chain IDs 901 and 902):
     ```bash
     supersim --interop.autorelay
     ```
   - This sets up local RPC endpoints like `http://127.0.0.1:9545` (chain 901) and `http://127.0.0.1:9546` (chain 902).

2. **Install Dependencies**:
   - In a second terminal, navigate to your project directory and install all required packages:
     ```bash
     forge install
     ```

3. **Run the Deployment Script**:
   - Execute the deployment script `DeployFactory.s.sol` to deploy the `DeploymentFactory` contract on chain 901 with broadcasting enabled:
     ```bash
     forge script script/DeployFactory.s.sol --broadcast
     ```
   - Add `<PRIVATE_KEY>` with a valid private key in .env file in root directory.
   - After execution, note the deployed `DeploymentFactory` address printed in the console (e.g., `0x1234...`).

4. **Update and Run the Test Deployment Script**:
   - Open `script/TestDeploy.s.sol` in your project.
   - Paste the factory address from Step 3 into the script where indicated (e.g., replace a placeholder like `address factoryAddress = 0x...;` with your address).
   - Run the test deployment script to deploy a `TestToken` contract via the factory:
     ```bash
     forge script script/TestDeploy.s.sol --broadcast
     ```
   - This script uses the deployed factory to deploy `TestToken` on chain 901 and sends a cross-chain message to chain 902.

## Running the Test Script

To run the unit tests for the `DeploymentFactory` contract, use the following command:

```bash
forge test --match-path test/DeploymentFactoryTest.t.sol

