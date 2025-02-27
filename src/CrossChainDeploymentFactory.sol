// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IL2ToL2CrossDomainMessenger} from "optimism-contracts/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";

import {CrossChainUtils} from "./libraries/CrossChainUtils.sol";
import {Common} from "./libraries/Common.sol";
import "solady/src/utils/CREATE3.sol"; 

/**
 * @title CrossChainDeploymentFactory
 * @dev A factory contract for deploying contracts on the current chain and sending cross-chain messages to deploy the contract on other chains.
 * This contract uses the Optimism L2-to-L2 cross-domain messenger for cross-chain communication.
 * @notice
 */
contract CrossChainDeploymentFactory {
    using CrossChainUtils for *;
    using Common for *;
    using CREATE3 for bytes32;

    // Immutable reference to the L2 CrossDomainMessenger
    IL2ToL2CrossDomainMessenger internal immutable messenger;

    // Owner of the contract
    address public owner;

    // Events for tracking deployments
    event ContractDeployed(
        address indexed contractAddress,
        uint256 indexed chainId
    );
    event CrossChainMessageSent(
        uint256 indexed chainId,
        address indexed targetFactory
    );

    constructor() {
        messenger = IL2ToL2CrossDomainMessenger(
            Common.L2_TO_L2_CROSS_DOMAIN_MESSENGER
        );
        owner = msg.sender;
    }

    /**
     * @dev Deploys a contract on the current chain and sends cross-chain messages to deploy it on the specified chains.
     * @param chainIds Array of chain IDs on which to deploy the contract.
     * @param bytecode The creation bytecode of the contract to deploy.
     * @param salt A unique salt for deterministic deployment (CREATE2).
     * @return deployedAddr The address of the deployed contract.
     */
    function deployContract(
        uint256[] calldata chainIds,
        bytes memory bytecode,
        bytes32 salt
    ) external returns (address deployedAddr) {
        // Step 1: Deploy on the current chain
        deployedAddr = _deploy(bytecode, salt);
        emit ContractDeployed(deployedAddr, block.chainid);

        // Step 2: Send cross-chain messages to each target chain.
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (block.chainid == chainIds[i]) continue;
            bytes memory message = abi.encodeCall(
                this.deploy,
                (bytecode, salt)
            );
            messenger.sendMessage(chainIds[i], address(this), message);
            emit CrossChainMessageSent(chainIds[i], address(this));
        }
    }

    /**
     * @dev Deploys a Hub contract on the current chain and Spoke contracts on specified chains, all at the same address using CREATE3.
     * @param hubBytecode The creation bytecode of the Hub(primary chain) contract.
     * @param spokeBytecode The creation bytecode of the Spoke(secondary chains) contracts.
     * @param salt A unique salt for deterministic deployment (CREATE3).
     * @param spokeChainIds Array of chain IDs on which to deploy the spoke contracts.
     * @return hubAddr The address of the deployed hub contract.
     */
    function deployHubAndSpokes(
        bytes memory hubBytecode,
        bytes memory spokeBytecode,
        bytes32 salt,
        uint256[] calldata spokeChainIds
    ) external returns (address hubAddr) {
        // Deploy the hub on the current chain using CREATE3
        hubAddr = salt.deploy(hubBytecode, 0);
        emit ContractDeployed(hubAddr, block.chainid);

        // Send cross-chain messages to deploy spokes on other chains
        for (uint256 i = 0; i < spokeChainIds.length; i++) {
            uint256 chainId = spokeChainIds[i];
            if (chainId == block.chainid) continue; // Skip current chain
            bytes memory message = abi.encodeCall(
                this.deployWithCREATE3,
                (spokeBytecode, salt)
            );
            messenger.sendMessage(chainId, address(this), message);
            emit CrossChainMessageSent(chainId, address(this));
        }
    }

    /**
     * @dev Deploys a contract on the current chain when triggered by a cross-chain message using CREATE3.
     * @param bytecode The creation bytecode of the contract to deploy.
     * @param salt A unique salt for deterministic deployment (CREATE3).
     */
    function deployWithCREATE3(bytes memory bytecode, bytes32 salt) external {
        CrossChainUtils.validateCrossDomainCallback();
        address deployed = salt.deploy(bytecode, 0);
        emit ContractDeployed(deployed, block.chainid);
    }

    /**
     * @dev Deploys a contract on the current chain when triggered by a cross-chain message.
     * @param bytecode The creation bytecode of the contract to deploy.
     * @param salt A unique salt for deterministic deployment (CREATE2).
     */
    function deploy(bytes memory bytecode, bytes32 salt) external {
        CrossChainUtils.validateCrossDomainCallback();
        _deploy(bytecode, salt);
    }

    /**
     * @dev Internal helper function to deploy a contract using CREATE2.
     * @param bytecode The creation bytecode of the contract to deploy.
     * @param salt A unique salt for deterministic deployment.
     * @return addr The address of the deployed contract.
     */
    function _deploy(
        bytes memory bytecode,
        bytes32 salt
    ) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }
}
