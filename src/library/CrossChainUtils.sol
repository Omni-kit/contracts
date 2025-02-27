// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IL2ToL2CrossDomainMessenger} from "optimism-contracts/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {ISuperchainERC20} from "optimism-contracts/interfaces/L2/ISuperchainERC20.sol";
import {ISuperchainWETH} from "optimism-contracts/interfaces/L2/ISuperchainWETH.sol";
import {ISuperchainTokenBridge} from "optimism-contracts/interfaces/L2/ISuperchainTokenBridge.sol";

import {Predeploys} from "optimism-contracts/src/libraries/Predeploys.sol";

// Custom error definitions for better gas efficiency
error CallerNotL2ToL2CrossDomainMessenger();
error InvalidCrossDomainSender();
error TransferFailed();
error InvalidArrayLength();

library CrossChainUtils {
    // Immutable reference to the L2 CrossDomainMessenger
    IL2ToL2CrossDomainMessenger internal constant messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    // Events
    event StateSynced(uint256 indexed chainId, bytes encodedCall);

    /**
     * @notice Sends a cross-chain message to deploy or interact with a contract on another chain.
     * @param _toChainId The destination chain ID.
     * @param _message The encoded message to send.
     */
    function _sendCrossChainMessage(
        uint256 _toChainId,
        bytes memory _message
    ) internal {
        messenger.sendMessage(_toChainId, address(this), _message);
    }

    /**
     * @notice Wraps ETH to WETH.
     * @param _amount The amount of ETH to wrap.
     */
    function wrapETH(uint256 _amount) internal {
        ISuperchainWETH(payable(Predeploys.SUPERCHAIN_WETH)).deposit{
            value: _amount
        }();
    }

    /**
     * @notice Sends ERC20 tokens via the Superchain token bridge.
     * @param _token The address of the ERC20 token.
     * @param _to The recipient address on the destination chain.
     * @param _amount The amount of tokens to send.
     * @param _toChainId The destination chain ID.
     */
    function sendERC20ViaBridge(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _toChainId
    ) internal {
        ISuperchainTokenBridge(Predeploys.SUPERCHAIN_TOKEN_BRIDGE).sendERC20(
            _token,
            _to,
            _amount,
            _toChainId
        );
    }

    /**
     * @notice Sends ERC20 tokens via the bridge and then sends a cross-chain message.
     * @param _token The address of the ERC20 token.
     * @param _to The recipient address on the destination chain.
     * @param _amount The amount of tokens to send.
     * @param _toChainId The destination chain ID.
     * @param _message The encoded message to send.
     */
    function sendTokenWithMessage(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _toChainId,
        bytes memory _message
    ) internal {
        // Send the ERC20 tokens first
        sendERC20ViaBridge(_token, _to, _amount, _toChainId);

        // Send the cross-chain message after the token transfer
        _sendCrossChainMessage(_toChainId, _message);
    }

    /**
     * @notice Validates and calculates the total amount from an array of amounts.
     * @param _amounts The array of amounts.
     * @return totalAmount The total amount.
     */
    function calculateTotal(
        uint256[] memory _amounts
    ) internal pure returns (uint256 totalAmount) {
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
    }

    /**
     * @notice Transfers tokens to multiple recipients.
     * @param _token The address of the ERC20 token.
     * @param _recipients The array of recipient addresses.
     * @param _amounts The array of amounts to transfer.
     */
    function disperseTokens(
        address _token,
        address[] memory _recipients,
        uint256[] memory _amounts
    ) internal {
        if (_recipients.length != _amounts.length) revert InvalidArrayLength();
        for (uint256 i = 0; i < _recipients.length; i++) {
            bool success = ISuperchainERC20(_token).transfer(
                _recipients[i],
                _amounts[i]
            );
            if (!success) revert TransferFailed();
        }
    }

    /**
     * @dev Syncs state across multiple chains using Optimism's interop contracts.
     * @param encodedCall The encoded function call to sync.
     * @param chainIds The list of chain IDs to sync the state to.
     */
    function syncStates(
        bytes memory encodedCall,
        uint256[] memory chainIds
    ) internal {
        require(
            chainIds.length > 0,
            "CrossChainStateSync: No chain IDs provided"
        );
        require(
            encodedCall.length > 0,
            "CrossChainStateSync: Empty encoded call"
        );

        uint256 length = chainIds.length;
        for (uint256 i = 0; i < length; i++) {
            messenger.sendMessage(chainIds[i], address(this), encodedCall);
            emit StateSynced(chainIds[i], encodedCall);
        }
    }

    /**
     * @notice Modifier to ensure the caller is the L2ToL2CrossDomainMessenger and the sender is valid.
     */
    modifier onlyCrossDomainCallback() {
        if (msg.sender != address(messenger))
            revert CallerNotL2ToL2CrossDomainMessenger();
        if (messenger.crossDomainMessageSender() != address(this))
            revert InvalidCrossDomainSender();
        _;
    }
}
