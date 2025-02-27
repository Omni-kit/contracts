// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IL2ToL2CrossDomainMessenger} from "optimism-contracts/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Common} from "./libraries/Common.sol";

contract CrossChainStateSync {
    using Common for *;

    // Events
    event StateSynced(uint256 indexed chainId, bytes encodedCall);

    // Immutable reference to the L2 CrossDomainMessenger
    IL2ToL2CrossDomainMessenger internal immutable messenger;

    constructor() {
        messenger = IL2ToL2CrossDomainMessenger(
            Common.L2_TO_L2_CROSS_DOMAIN_MESSENGER
        );
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
}
