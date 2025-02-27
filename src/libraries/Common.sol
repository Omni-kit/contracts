// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Predeploys} from "optimism-contracts/src/libraries/Predeploys.sol";

library Common {
    // Errors
    error CallerNotL2ToL2CrossDomainMessenger();
    error InvalidCrossDomainSender();
    error TransferFailed();
    error InvalidArrayLength();

    // Constants (fetched dynamically from Predeploys)
    address internal constant L2_TO_L2_CROSS_DOMAIN_MESSENGER =
        Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER;
    address internal constant SUPERCHAIN_WETH = Predeploys.SUPERCHAIN_WETH;
    address internal constant SUPERCHAIN_TOKEN_BRIDGE =
        Predeploys.SUPERCHAIN_TOKEN_BRIDGE;
}
