// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/DeploymentFactory.sol";
import "../src/example/TestToken.sol";

struct ChainConfig {
    uint256 chainId;
    string rpcUrl;
}

contract DeployAndVerifyTestToken is Script {
    /// @notice Computes the CREATE2 deployed address.
    /// @param factory The deploying (factory) contract address.
    /// @param salt The salt used for CREATE2.
    /// @param bytecodeHash The keccak256 hash of the creation bytecode.
    function computeCreate2Address(
        address factory,
        bytes32 salt,
        bytes32 bytecodeHash
    ) public pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                factory,
                                salt,
                                bytecodeHash
                            )
                        )
                    )
                )
            );
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Configure two chains: 901 and 902.
        ChainConfig[] memory chains = new ChainConfig[](2);
        chains[0] = ChainConfig(901, "http://127.0.0.1:9545"); // Chain 901
        chains[1] = ChainConfig(902, "http://127.0.0.1:9546"); // Chain 902

        // Create persistent forks for both chains.
        uint256 fork901 = vm.createFork(chains[0].rpcUrl);
        // uint256 fork902 = vm.createFork(chains[1].rpcUrl);

        // The factory is already deployed at the same address on both chains.
        address factoryAddress = 0x6F4A341ca76DC55B67F547b7BD70d6C76FbeD753;
        DeploymentFactory factory = DeploymentFactory(factoryAddress);

        // --- Deploy TestToken via the factory from chain 901 ---
        vm.selectFork(fork901);
        vm.startBroadcast(deployerPrivateKey);

        // Retrieve the creation bytecode for TestToken.
        bytes memory tokenBytecode = type(TestToken).creationCode;
        // Define a unique salt for deterministic deployment.
        bytes32 salt = keccak256("TestToken");

        // Specify target chain IDs (other than the current one).
        uint256[] memory targetChainIds = new uint256[](1);
        targetChainIds[0] = chains[1].chainId; // Chain 902

        // Call deployEverywhere: this deploys on chain 901 and sends a cross-chain message for chain 902.
        factory.deployContract(targetChainIds, tokenBytecode, salt);
        vm.stopBroadcast();

        // --- Compute the deterministic TestToken address ---
        bytes32 tokenBytecodeHash = keccak256(tokenBytecode);
        address tokenAddress = computeCreate2Address(
            factoryAddress,
            salt,
            tokenBytecodeHash
        );
        console.log("TestToken deployed at:", tokenAddress);

        // --- Verify the deployment on Chain 901 ---
        vm.selectFork(fork901);
        TestToken token901 = TestToken(tokenAddress);
        uint256 supply901 = token901.totalSupply();
        uint256 factoryBalance901 = token901.balanceOf(factoryAddress);
        console.log("Chain 901 TestToken totalSupply:", supply901);
        console.log("Chain 901 Factory Token Balance:", factoryBalance901);
    }
}
