// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import "../src/CrossChainStateSync.sol";
import {IL2ToL2CrossDomainMessenger} from "optimism-contracts/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "optimism-contracts/src/libraries/Predeploys.sol";

contract CrossChainStateSyncTest is Test {
    function setUp() public {}
}
