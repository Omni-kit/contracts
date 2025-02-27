// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISuperchainERC20} from "optimism-contracts/interfaces/L2/ISuperchainERC20.sol";
import {CrossChainUtils} from "./libraries/CrossChainUtils.sol";
import {Common} from "./libraries/Common.sol";


contract CrossChainTokenTransfer is ReentrancyGuard {
    using CrossChainUtils for *;
    using Common for *;

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

        uint256 totalAmount = amounts.calculateTotal();
        require(
            ISuperchainERC20(token).transferFrom(
                msg.sender,
                address(this),
                totalAmount
            ),
            "TransferFrom failed"
        );

        if (chainId == block.chainid) {
            CrossChainUtils.disperseTokens(token, recipients, amounts);
        } else {
            CrossChainUtils.sendERC20ViaBridge(
                token,
                address(this),
                totalAmount,
                chainId
            );
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
    ) external {
        CrossChainUtils.validateCrossDomainCallback();

        if (recipients.length != amounts.length)
            revert Common.InvalidArrayLength();

        uint256 totalAmount = amounts.calculateTotal();
        CrossChainUtils.disperseTokens(token, recipients, amounts);

        emit TokensReceived(
            CrossChainUtils.messenger.crossDomainMessageSource(),
            block.chainid,
            totalAmount
        );
    }
}
