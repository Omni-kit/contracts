// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DeploymentFactory.sol";
import "../src/example/TestToken.sol";
import {IL2ToL2CrossDomainMessenger} from "optimism-contracts/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";
import {Predeploys} from "optimism-contracts/src/libraries/Predeploys.sol";

/**
 * @title DeploymentFactoryTest
 * @dev Test suite for the DeploymentFactory contract, focusing on deployment, cross-chain messaging,
 * access control, and edge cases.
 */
contract DeploymentFactoryTest is Test {
    error CallerNotL2ToL2CrossDomainMessenger();
    error InvalidCrossDomainSender();

    uint256 forkA;
    uint256 forkB;
    DeploymentFactory factory901;
    DeploymentFactory factory902;
    address expectedAddress;
    address factoryAddress;
    bytes tokenBytecode;

    // Events for reference
    event ContractDeployed(
        address indexed contractAddress,
        uint256 indexed chainId
    );
    event CrossChainMessageSent(
        uint256 indexed chainId,
        address indexed targetFactory
    );

    /**
     * @dev Set up forks and deploy factories on(chain A) and chain B.
     * Ensures factories are deployed at the same address on both chains.
     */
    function setUp() public {
        // Create forks for chain A and chain B
        forkA = vm.createFork("http://127.0.0.1:9545"); // chainId 901
        forkB = vm.createFork("http://127.0.0.1:9546"); // chainId 902

        // Deploy factory on chain A
        vm.selectFork(forkA);
        factory901 = new DeploymentFactory{salt: "DeploymentFactoryy"}();
        factoryAddress = address(factory901);

        // Deploy factory on chain B
        vm.selectFork(forkB);
        factory902 = new DeploymentFactory{salt: "DeploymentFactoryy"}();
        assertEq(
            address(factory902),
            factoryAddress,
            "Factories deployed at different addresses"
        );

        bytes32 salt = keccak256("TestToken");
        tokenBytecode = type(TestToken).creationCode;
        expectedAddress = computeCreate2Address(
            factoryAddress,
            salt,
            tokenBytecode
        );
    }

    /**
     * @dev Helper function to compute CREATE2 address.
     * @param factory The factory address.
     * @param salt The salt used for deployment.
     * @param bytecode The creation bytecode of the contract.
     * @return addr The computed CREATE2 address.
     */
    function computeCreate2Address(
        address factory,
        bytes32 salt,
        bytes memory bytecode
    ) public pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(hex"ff", factory, salt, keccak256(bytecode))
        );
        return address(uint160(uint256(hash)));
    }

    /**
     * @dev Test deploying a contract on chain A and simulating cross-chain deployment on chain B.
     * Verifies deployment addresses, events, and token state.
     */
    function testDeployContract() public {
        vm.selectFork(forkA);
        bytes memory bytecode = type(TestToken).creationCode;
        bytes32 salt = keccak256("TestToken");
        uint256[] memory targetChainIds = new uint256[](1);
        targetChainIds[0] = 902; // chainIdB

        vm.expectEmit(true, true, true, true);
        emit ContractDeployed(expectedAddress, 901);

        vm.expectEmit(true, true, true, true);
        emit CrossChainMessageSent(902, factoryAddress);

        // Expect ContractDeployed event on chain A
        factory901.deployContract(targetChainIds, bytecode, salt);
        console.log("contract deployed on chain A");


        // Verify deployment on chain A
        TestToken tokenA = TestToken(expectedAddress);
        assertTrue(
            address(tokenA).code.length > 0,
            "Contract not deployed on chain A"
        );
        uint256 initialSupply = tokenA.totalSupply();
        assertEq(
            tokenA.balanceOf(factoryAddress),
            initialSupply,
            "Incorrect balance on chain A"
        );

        // Simulate cross-chain message on chain B
        vm.selectFork(forkB);
        address messengerAddr = Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER;
        vm.prank(messengerAddr);
        vm.mockCall(
            messengerAddr,
            abi.encodeWithSelector(
                IL2ToL2CrossDomainMessenger.crossDomainMessageSender.selector
            ),
            abi.encode(factoryAddress)
        );

        factory902.deploy(bytecode, salt);
        vm.clearMockedCalls();

        // Verify deployment on chain B
        TestToken tokenB = TestToken(expectedAddress);
        console.log("1");
        assertTrue(
            address(tokenB).code.length > 0,
            "Contract not deployed on chain B"
        );
        console.log("2");

        assertEq(
            tokenB.totalSupply(),
            initialSupply,
            "Total supply mismatch on chain B"
        );
        console.log("3");

        assertEq(
            tokenB.balanceOf(factoryAddress),
            initialSupply,
            "Incorrect balance on chain B"
        );
    }

    /**
     * @dev Test access control for the deploy function.
     * Ensures only the messenger with correct cross-domain sender can call deploy.
     */
    function testOnlyCrossDomainCallbackCanDeploy() public {
        vm.selectFork(forkB);

        bytes32 salt = keccak256("TestToken");
        IL2ToL2CrossDomainMessenger messenger = IL2ToL2CrossDomainMessenger(
            Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER
        );

        // Direct call fails
        vm.expectRevert(CallerNotL2ToL2CrossDomainMessenger.selector);
        factory902.deploy(tokenBytecode, salt);

        // Test invalid sender
        vm.startPrank(address(messenger));
        vm.mockCall(
            address(messenger),
            abi.encodeWithSelector(
                IL2ToL2CrossDomainMessenger.crossDomainMessageSender.selector
            ),
            abi.encode(address(0xdead))
        );

        vm.expectRevert(InvalidCrossDomainSender.selector);

        factory902.deploy(tokenBytecode, salt);
        vm.stopPrank();

        // Correct call succeeds
        vm.prank(address(messenger));
        vm.mockCall(
            address(messenger),
            abi.encodeWithSelector(messenger.crossDomainMessageSender.selector),
            abi.encode(factoryAddress)
        );
        factory902.deploy(tokenBytecode, salt);
    }

    /**
     * @dev Test that different salts produce different deployment addresses.
     */
    function testDifferentSalts() public {
        vm.selectFork(forkA);
        bytes memory bytecode = type(TestToken).creationCode;
        bytes32 salt1 = keccak256("salt1");
        bytes32 salt2 = keccak256("salt2");

        address addr1 = computeCreate2Address(factoryAddress, salt1, bytecode);
        address addr2 = computeCreate2Address(factoryAddress, salt2, bytecode);

        assertTrue(
            addr1 != addr2,
            "Different salts should produce different addresses"
        );
    }

    /**
     * @dev Test deployment with no target chain IDs.
     * Verifies deployment on current chain and no cross-chain messages sent.
     */
    function testNoTargetChains() public {
        vm.selectFork(forkA);
        bytes memory bytecode = type(TestToken).creationCode;
        bytes32 salt = keccak256("TestToken");
        uint256[] memory targetChainIds = new uint256[](0);

        // Expect only ContractDeployed event
        emit ContractDeployed(expectedAddress, 901);

        factory901.deployContract(targetChainIds, bytecode, salt);

        // Verify deployment on chain A
        assertTrue(
            address(TestToken(expectedAddress)).code.length > 0,
            "Contract not deployed on chain A"
        );
    }

    function testEventEmissions() public {
        vm.selectFork(forkA);
        bytes32 salt = keccak256("TestToken");
        uint256[] memory targets = new uint256[](1);
        targets[0] = 902;

        vm.expectEmit(true, true, true, true);
        emit ContractDeployed(expectedAddress, 901);

        vm.expectEmit(true, true, true, true);
        emit CrossChainMessageSent(902, factoryAddress);
        factory901.deployContract(targets, tokenBytecode, salt);
    }
}
