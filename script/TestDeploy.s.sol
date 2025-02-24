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
    ChainConfig[] public chains;
    uint256 fork901;
    uint256 fork902;
    address factoryAddress;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Configure two chains: 901 and 902.
        
        chains.push(ChainConfig(901, "http://127.0.0.1:9545")); // OPChainA
        chains.push(ChainConfig(902, "http://127.0.0.1:9546")); // OPChainB

        // Create persistent forks for both chains.
        fork901 = vm.createFork(chains[0].rpcUrl);
        fork902 = vm.createFork(chains[1].rpcUrl);

        // The factory is already deployed at the same address on both chains.
        factoryAddress = 0x6F4A341ca76DC55B67F547b7BD70d6C76FbeD753; //change after deployment
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
    }

    function TestDeployedToken() external {
        // Known TestToken contract address on both chains.
        address testTokenAddress = 0x700b6A60ce7EaaEA56F065753d8dcB9653dbAD35;

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
}
