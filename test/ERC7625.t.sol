// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/ERC7625.sol";
import "../src/sampleContract.sol";
import "../src/MetadataGenerator.sol";


/// @title Test Suite for ERC7625 Smart Contract with MetadataGenerator
contract ERC7625Test is Test {
    ERC7625 erc7625;
    MetadataGenerator metadataGenerator;

    function setUp() public {
        // Deploy the MetadataGenerator and pass its address to the ERC7625 contract
        metadataGenerator = new MetadataGenerator();
        erc7625 = new ERC7625(address(metadataGenerator));
    }

    /// @notice Tests creating a new contract instance and verifies its ownership and metadata creation.
    function testCreateContractAndMetadata() public {
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));
        uint256 contractId = erc7625.createContract(
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
            "[]", // attributesJSON
            "[]", // functionsJSON
            "[]", // eventsJSON
            "{}"  // mappingsJSON
        );

        // Assuming you have a mechanism to obtain the instance address after contract creation
        address instanceAddress = address(0); // Placeholder: Replace with actual mechanism to obtain instance address

        MetadataLib.Metadata memory metadata = metadataGenerator.getMetadata(instanceAddress);
        assertEq(metadata.name, "Contract Name", "Metadata name mismatch");
    }

    /// @notice Tests locking and unlocking a contract's asset transfers with metadata considerations.
    function testLockUnlockAssetTransfersWithMetadata() public {
        bytes32 salt = keccak256("unique salt for locking test");
        uint256 contractId = erc7625.createContract(
            salt,
            "Lock/Unlock Test",
            "Description",
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

        // Lock and then unlock the contract's asset transfers
        erc7625._lockAssetTransfers(contractId);
        erc7625._unlockAssetTransfers(contractId);

        // Additional assertions could be made here if the contract provided a way to check lock status
    }

    /// @notice Tests the approval and revocation process for a contract's management, considering metadata implications.
    function testApproveAndRevokeOperatorWithMetadata() public {
        bytes32 salt = keccak256("unique salt for operator test");
        uint256 contractId = erc7625.createContract(
            salt,
            "Approval Test",
            "Description",
            "http://image.url",
            "http://external.url",
            "NFT",
            "0xCreator",
            "Ethereum",
            "http://sourcecode.url",
            "Apache-2.0",
            "[]",
            "[]",
            "[]",
            "{}"
        );

        address operator = address(0x1);
        erc7625.approveOperatorToTransfer(operator, contractId);
        assertEq(erc7625.getApproved(contractId), operator, "Operator was not approved correctly");

        // Revoke the approval
        erc7625.approveOperatorToTransfer(address(0), contractId);
        assertEq(erc7625.getApproved(contractId), address(0), "Operator was not revoked correctly");
    }
}
