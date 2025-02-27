// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/CrossChainDeploymentFactory.sol";

struct ChainConfig {
    uint256 chainId;
    string rpcUrl;
}

contract DeployFactory is Script {
    CrossChainDeploymentFactory factory1;
    CrossChainDeploymentFactory factory2;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address:", deployer);

        // Define configurations for two chains.
        ChainConfig[] memory chains = new ChainConfig[](2);
        chains[0] = ChainConfig(901, "http://127.0.0.1:9545"); // OPChainA
        chains[1] = ChainConfig(902, "http://127.0.0.1:9546"); // OPChainB

        // Create persistent forks for each chain.
        uint256 fork1 = vm.createFork(chains[0].rpcUrl);
        uint256 fork2 = vm.createFork(chains[1].rpcUrl);

        // Deploy factories on both chains.
        address[] memory factoryAddresses = new address[](2);

        // Deploy on Chain 1 (OPChainA).
        vm.selectFork(fork1);
        vm.startBroadcast(deployerPrivateKey);

        factory1 = new CrossChainDeploymentFactory{
            salt: "CrossChainDeploymentFactory"
        }();
        factoryAddresses[0] = address(factory1);
        vm.stopBroadcast();
        console.log("Factory on OPChainA:", factoryAddresses[0]);

        // Deploy on Chain 2 (OPChainB).
        vm.selectFork(fork2);
        vm.startBroadcast(deployerPrivateKey);

        factory2 = new CrossChainDeploymentFactory{
            salt: "CrossChainDeploymentFactory"
        }();
        factoryAddresses[1] = address(factory2);
        vm.stopBroadcast();
        console.log("Factory on OPChainB:", factoryAddresses[1]);
    }
}
