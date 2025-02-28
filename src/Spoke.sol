// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CrossChainUtils} from "./libraries/CrossChainUtils.sol";

contract Spoke {
    uint256 public immutable HubChainId;

    constructor(uint256 _hubChainId) {
        HubChainId = _hubChainId;
    }

    /**
     * @notice Calls any write function on the Hub contract across chains.
     * @param hubCallData The ABI-encoded function call data for the Hub contract.
     *
     * Example of `hubCallData` encoding:
     * Suppose the Hub contract has a function `updateData(uint256 newValue)`.
     * 
     * To call it with `newValue = 42`, encode it as follows:
     * 
     *   bytes memory hubCallData = abi.encodeWithSignature(
     *       "updateData(uint256)",
     *       42
     *   );
     * Pass this `hubCallData` to this function to trigger the cross-chain call.
     */

    function callAnyHubFunction(bytes memory hubCallData) external {
        // Send the cross-chain message to the Hub's chain
        CrossChainUtils._sendCrossChainMessage(HubChainId, hubCallData);
    }
}
