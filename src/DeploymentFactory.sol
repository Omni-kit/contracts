// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IL2ToL2CrossDomainMessenger} from "optimism-contracts/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {CrossChainUtils} from "./library/CrossChainUtils.sol";
import {Common} from "./library/Common.sol";

/**
 * @title DeploymentFactory
 * @dev A factory contract for deploying contracts on the current chain and sending cross-chain messages to deploy the contract on other chains.
 * This contract uses the Optimism L2-to-L2 cross-domain messenger for cross-chain communication.
 * @notice
 */
contract DeploymentFactory {
    using CrossChainUtils for *;
    using Common for *;

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
