// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/ERC7625.sol";
import "../src/sampleContract.sol";
import "../src/MetadataGenerator.sol";


/// @title Test Suite for ERC7625 Smart Contract with MetadataGenerator
/// @dev Using forge-std's Test contract for setting up and executing tests.
contract ERC7625Test is Test {
    ERC7625 erc7625;
    MetadataGenerator metadataGenerator;
    
    /// Fixed fee for contract creation within the ERC7625 contract.
    uint256 public constant CONTRACT_CREATION_FEE = 1 ether; 

    /// Stores the last created contract ID for verification in tests.
    uint256 public contractId;

    /// @dev Sets up the ERC7625 and MetadataGenerator contracts before each test.
    function setUp() public {
        metadataGenerator = new MetadataGenerator();
        erc7625 = new ERC7625(address(metadataGenerator));

        // Provide the test contract with Ether to cover contract creation fees and other expenses.
        uint256 initialTestContractBalance = 100 ether; 
        vm.deal(address(this), initialTestContractBalance);

        // Optionally, allocate Ether to the ERC7625 contract if needed for testing its Ether handling capabilities.
        uint256 initialERC7625ContractBalance = 50 ether; // Adjust the amount as needed
        vm.deal(address(erc7625), initialERC7625ContractBalance);
    }

    /// @dev Tests creating a contract and its metadata through the ERC7625 contract.
    function testCreateContractAndMetadata() public {
        vm.deal(address(this), 1 ether);

        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));
        vm.prank(address(this)); 
        contractId = erc7625.createContract{value: 1 ether}(
            salt,
            "Contract Name",
            "Contract Description",
            "http://image.url",
            "http://external.url",
            "DeFi",
            "0xCreatorAddress",
            "Ethereum",
            "http://sourcecode.url",
            "MIT License",
            "[]",
            "[]",
            "[]",
            "{}"
        );

        address ownerOfContractId = erc7625.ownerOfContractId(contractId);
        assertEq(
            ownerOfContractId,
            address(this),
            "Owner should be this contract"
        );
    }

    /// @dev Tests the locking and unlocking functionality of a contract in ERC7625.
    function testLockAndUnlockContract() public {
        vm.deal(address(this), 1 ether);

        bytes32 salt = keccak256("Test Salt for Locking");
        vm.prank(address(this)); 
        uint256 newContractId = erc7625.createContract{value: 1 ether}(
            salt,
            "Lock Test",
            "Testing lock and unlock functionality",
            "http://image.url",
            "http://external.url",
            "Utility",
            "0xCreator",
            "Polygon",
            "http://sourcecode.url",
            "GPL-3.0",
            "[]",
            "[]",
            "[]",
            "{}"
        );

        assertTrue(
            !erc7625.isContractLocked(newContractId),
            "Contract should be unlocked initially"
        );
        erc7625._lockAssetTransfers(newContractId);
        assertTrue(
            erc7625.isContractLocked(newContractId),
            "Contract should be locked after lock operation"
        );

        erc7625._unlockAssetTransfers(newContractId);
        assertFalse(
            erc7625.isContractLocked(newContractId),
            "Contract should be unlocked after unlock operation"
        );
    }

    /// @dev Tests creating multiple contracts and withdrawing Ether from the ERC7625 contract.
    function testCreateMultipleContractsAndWithdraw() public {
        uint256 contractsToCreate = 10;
        uint256 totalPayment = CONTRACT_CREATION_FEE * contractsToCreate;

        vm.deal(address(this), totalPayment);

        uint256[] memory createdContractIds = new uint256[](contractsToCreate);
        for (uint256 i = 0; i < contractsToCreate; i++) {
            bytes32 salt = keccak256(abi.encodePacked(block.timestamp, i));
            vm.prank(address(this)); // Ensure the caller is this test contract
            uint256 newContractId = erc7625.createContract{
                value: CONTRACT_CREATION_FEE
            }(
                salt,
                "Contract Name",
                "Contract Description",
                "http://image.url",
                "http://external.url",
                "DeFi",
                "0xCreatorAddress",
                "Ethereum",
                "http://sourcecode.url",
                "MIT License",
                "[]",
                "[]",
                "[]",
                "{}"
            );
            createdContractIds[i] = newContractId;
        }

        for (uint256 i = 0; i < contractsToCreate; i++) {
            assertTrue(
                erc7625.ownerOfContractId(createdContractIds[i]) ==
                    address(this),
                "Contract creation failed"
            );
        }

        uint256 initialBalance = address(this).balance;
        uint256 withdrawAmount = totalPayment / 2;
        erc7625.withdraw(address(this), withdrawAmount);

        uint256 finalBalance = address(this).balance;
        assertEq(
            finalBalance,
            initialBalance + withdrawAmount,
            "Withdrawal amount does not match"
        );
    }

    /// @dev Tests setting approval for a contract and the auto-locking mechanism in ERC7625.
    function testSetApprovalAndAutoLock() public {
        vm.deal(address(this), 10 ether);

        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));
        contractId = erc7625.createContract{value: 1 ether}(
            salt,
            "Approval Test",
            "Testing approval and auto lock functionality",
            "http://image.url",
            "http://external.url",
            "Utility",
            "0xCreator",
            "Ethereum",
            "http://sourcecode.url",
            "GPL-3.0",
            "[]",
            "[]",
            "[]",
            "{}"
        );

        address approvedAddress = address(0x123);
        vm.prank(address(this));
        erc7625.approveOperatorToTransfer(approvedAddress, contractId);

        assertTrue(erc7625.isContractLocked(contractId), "Contract should be automatically locked after setting approval");

        vm.prank(address(this)); // Simulating the owner
        erc7625._unlockAssetTransfers(contractId);
        assertFalse(erc7625.isContractLocked(contractId), "Contract should be unlocked by the owner");
    }

    /// @dev Tests attempting to unlock an already unlocked contract, expecting it to revert.
    function testUnlockUnlockedContract() public {
    bytes32 salt = keccak256(abi.encodePacked("UniqueSalt"));
    contractId = erc7625.createContract{value: CONTRACT_CREATION_FEE}(
        salt, "Name", "Description", "ImageURL", "ExternalLink", "Type", "Creator", "Network", "SourceCodeLink", "License", "[]", "[]", "[]", "{}"
    );

    vm.prank(address(this)); 
    vm.expectRevert("ERC7625: Contract is not locked");
    erc7625._unlockAssetTransfers(contractId);
}
    receive() external payable {}
}
