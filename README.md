# Cross-Chain Smart Contract Abstraction

## Overview

This project abstracts cross-chain features and leverages Superchain capabilities to simplify cross-chain smart contract development. It provides a suite of contracts and a utility library to enable seamless cross-chain deployments, token transfers, and state synchronization.

## When to Use This Package

- **Providing Cross-Chain Functionality**: Seamlessly deploy contracts and manage state across different chains.
- **Token and ETH Transfers**: Send ERC20 tokens or native ETH across chains via Superchain bridges.
- **Cross-Chain Communication**: Execute function calls on destination chains at the time of relay.
- **Abstracted Deployment**: Utilize the provided npm package to deploy contracts on multiple chains with minimal hassle.

### Prerequisites for Superchain Cross-Chain Features

- **Exclusive to Superchain:** These features are only available for the Superchain network.
- **Uniform Deployment:** Your contract must be deployed at the same address on every chain.
- **Automated Handling:** Use our npm package (`@omni-kit/omni-deployer`) to automatically manage uniform deployment across all specified Superchains.

## Contracts

### 1. DeploymentFactory

**Address:** `0x538DB2dF0f1CCF9fBA392A0248D41292f01D3966`

The `DeploymentFactory` contract enables deploying contracts on multiple chains in a single transaction. It interacts with the Optimism L2-to-L2 cross-domain messenger to send deployment messages across chains.

#### Key Function:

```solidity
function deployContract(
    uint256[] calldata chainIds,
    bytes memory bytecode,
    bytes32 salt
) external returns (address deployedAddr);
```

- Deploys the contract on the current chain.
- Sends messages to other chains to deploy the same contract.
- Only requires gas fees on one chain.

**NPM Package:** [@omni-kit/omni-deployer](https://www.npmjs.com/package/@omni-kit/omni-deployer)

### 2. CrossChainDisperse

The `CrossChainDisperse` contract allows ERC20 token transfers to multiple recipients across chains. It uses the Superchain ecosystem for bridging tokens and sending cross-chain messages.

#### Key Function:

```solidity
function transferERC20TokensToSingleChain(
    address token,
    uint256 chainId,
    address[] memory recipients,
    uint256[] memory amounts
) external;
```

- Transfers tokens within the same chain or to a different chain.
- Uses `ISuperchainERC20` for token transfers.
- Sends messages for cross-chain execution.

### 3. CrossChainStateSync

The `CrossChainStateSync` contract ensures state consistency across multiple chains by leveraging Optimism's interoperability features.

#### Key Function:

```solidity
function syncStates(
    bytes memory encodedCall,
    uint256[] memory chainIds
) internal;
```

- Syncs function calls across multiple chains.
- Uses Optimism's `IL2ToL2CrossDomainMessenger` for communication.

## Library: CrossChainUtils

The `CrossChainUtils` library abstracts common cross-chain operations such as sending messages, bridging tokens, and wrapping ETH.

### Key Functions:

```solidity
function _sendCrossChainMessage(
    uint256 _toChainId,
    bytes memory _message
) internal;
```

- Sends messages to another chain using Optimism's cross-domain messenger.

```solidity
function sendERC20ViaBridge(
    address _token,
    address _to,
    uint256 _amount,
    uint256 _toChainId
) internal;
```

- Transfers ERC20 tokens to another chain using Superchain bridges.

```solidity
function sendTokenWithMessage(
    address _token,
    address _to,
    uint256 _amount,
    uint256 _toChainId,
    bytes memory _message
) internal;
```

- Transfers tokens and executes a cross-chain message in one call.

## Examples

### Example: Using `_sendCrossChainMessage`

When you want to call a function on the destination chain at the time of relay, you can encode the function call and send a cross-chain message as follows:

```solidity
// Prepare the message to call a function on the destination chain.
bytes memory message = abi.encodeCall(
    this.functionName,
    (arg1, arg2)
);

// Send the cross-chain message.
CrossChainUtils._sendCrossChainMessage(chainId, message);
```

On the destination chain, the contract should implement the function with cross-domain validation:

```solidity
function functionName(
    Type1 arg1,
    Type2 arg2
) external {
    // Ensure that the call is from a valid cross-domain messenger.
    CrossChainUtils.validateCrossDomainCallback();

    // Implementation of function logic.
}
```

### Example: Using `syncStates`

To synchronize state across multiple chains, encode the function call you wish to execute on all target chains and call `syncStates`:

```solidity
// Suppose you want to update state using the function updateState on all target chains.
bytes memory encodedCall = abi.encodeCall(
    MyContract.updateState,
    (newState)
);

// Define the chain IDs to sync state to.
uint256[] memory targetChainIds = new uint256[](2);
targetChainIds[0] = 100; // Example chain ID 1
targetChainIds[1] = 200; // Example chain ID 2

// Sync state across the specified chains.
syncStates(encodedCall, targetChainIds);
```

## Usage

1. **Deploy contracts on multiple chains** using `DeploymentFactory`.
2. **Transfer tokens across chains** using `CrossChainDisperse`.
3. **Sync contract state across chains** using `CrossChainStateSync`.
4. **Utilize the `CrossChainUtils` library** in your custom smart contracts to enable comprehensive cross-chain functionality.

## Want to See More Examples?  

Curious to see how this package works in action? We've put together detailed examples to help you get started quickly. Check them out here: **[Example Repository](https://github.com/Omni-kit/omnikit-examples)** 🚀  


