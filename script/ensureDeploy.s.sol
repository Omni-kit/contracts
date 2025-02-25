// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/example/TestToken.sol";

struct ChainConfig {
    uint256 chainId;
    string rpcUrl;
}

contract VerifyTestTokenDeployment is Script {
    function run() external {
        // Known TestToken contract address on both chains.
        address testTokenAddress = 0xc8295769FbAE26871FFCA431f18fdC2FE1EF7A64;

        // Define chain configurations for chain 901 and chain 902.
        ChainConfig[] memory chains = new ChainConfig[](2);
        chains[0] = ChainConfig(901, "http://127.0.0.1:9545"); // Chain 901 RPC URL
        chains[1] = ChainConfig(902, "http://127.0.0.1:9546"); // Chain 902 RPC URL

        // Create persistent forks for both chains.
        uint256 fork901 = vm.createFork(chains[0].rpcUrl);
        uint256 fork902 = vm.createFork(chains[1].rpcUrl);

        // --- Verify on Chain 901 ---
        vm.selectFork(fork901);
        TestToken token901 = TestToken(testTokenAddress);
        uint256 totalSupply901 = token901.totalSupply();
        string memory name901 = token901.name();
        string memory symbol901 = token901.symbol();
        console.log("Chain 901 - TestToken Verification:");
        console.log("Address:", testTokenAddress);
        console.log("Name:", name901);
        console.log("Symbol:", symbol901);
        console.log("Total Supply:", totalSupply901);

        // --- Verify on Chain 902 ---
        vm.selectFork(fork902);
        TestToken token902 = TestToken(testTokenAddress);
        uint256 totalSupply902 = token902.totalSupply();
        string memory name902 = token902.name();
        string memory symbol902 = token902.symbol();
        console.log("Chain 902 - TestToken Verification:");
        console.log("Address:", testTokenAddress);
        console.log("Name:", name902);
        console.log("Symbol:", symbol902);
        console.log("Total Supply:", totalSupply902);
    }
}
