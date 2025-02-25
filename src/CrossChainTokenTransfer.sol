// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISuperchainERC20} from "optimism-contracts/interfaces/L2/ISuperchainERC20.sol";
import {CrossChainUtils} from "./library/CrossChainUtils.sol";

error InvalidArrayLength();
error CallerNotL2ToL2CrossDomainMessenger();
error InvalidCrossDomainSender();

contract CrossChainTokenTransfer is ReentrancyGuard {
    using CrossChainUtils for *;

    struct ChainTransfer {
        uint256 chainId;
        address[] recipients;
        uint256[] amounts;
    }

    /*******************************     EVENTS      ***********************************/

    event TokensReceived(
        uint256 indexed fromChainId,
        uint256 indexed toChainId,
        uint256 totalAmount
    );

    // Function to transfer ERC20 tokens to recipients on the same chain or a single different chain
    function transferERC20TokensToSingleChain(
        address token,
        uint256 chainId,
        address[] memory recipients,
        uint256[] memory amounts
    ) external nonReentrant {
        require(recipients.length == amounts.length, "Array length mismatch");

        if (chainId == block.chainid) {
            // Local transfers on the current chain
            uint256 totalAmount = 0;
            for (uint256 i = 0; i < amounts.length; i++) {
                totalAmount += amounts[i];
            }
            require(
                ISuperchainERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    totalAmount
                ),
                "TransferFrom failed"
            );

            CrossChainUtils.disperseTokens(token, recipients, amounts);
        } else {
            // Cross-chain transfer to a single different chain
            uint256 totalAmount = 0;
            for (uint256 i = 0; i < amounts.length; i++) {
                totalAmount += amounts[i];
            }
            require(
                ISuperchainERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    totalAmount
                ),
                "TransferFrom failed"
            );

            token.sendERC20ViaBridge(address(this), totalAmount, chainId);

            bytes memory message = abi.encodeCall(
                this.receiveERC20Tokens,
                (token, recipients, amounts)
            );
            CrossChainUtils._sendCrossChainMessage(chainId, message);
        }
    }

    /**
     * @dev Receives and distributes tokens on the destination chain.
     * @param token The ERC20 token address.
     * @param recipients Array of recipient addresses.
     * @param amounts Array of amounts to send to each recipient.
     */
    function receiveERC20Tokens(
        address token,
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyCrossDomainCallback {
        if (recipients.length != amounts.length) revert InvalidArrayLength();

        uint256 totalAmount = amounts.calculateTotal();
        token.disperseTokens(recipients, amounts);

        emit TokensReceived(
            CrossChainUtils.messenger.crossDomainMessageSource(),
            block.chainid,
            totalAmount
        );
    }

    modifier onlyCrossDomainCallback() {
        if (msg.sender != address(CrossChainUtils.messenger))
            revert CallerNotL2ToL2CrossDomainMessenger();
        if (
            CrossChainUtils.messenger.crossDomainMessageSender() !=
            address(this)
        ) revert InvalidCrossDomainSender();
        _;
    }
}
