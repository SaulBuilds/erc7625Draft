// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/MetadataGenerator.sol";

contract MetadataGeneratorTest is Test {
    MetadataGenerator metadataGenerator;

    function setUp() public {
        metadataGenerator = new MetadataGenerator();
    }

    function testCreateMetadata() public {
        // Define the metadata parameters
        address contractAddress = address(this);
        uint256 contractId = 1;
        string memory name = "TestContract";
        string memory description = "A test contract";
        string memory image = "http://example.com/image.png";
        string memory externalLink = "http://example.com";
        string memory contractType = "Utility";
        string memory creator = "0xCreator";
        string memory network = "Ethereum";
        string memory sourceCodeLink = "http://github.com/sourcecode";
        string memory license = "MIT";
        string memory attributesJSON = "[]";
        string memory functionsJSON = "[]";
        string memory eventsJSON = "[]";
        string memory mappingsJSON = "{}";

        // Create metadata
        metadataGenerator.createMetadata(
            contractAddress,
            contractId,
            name,
            description,
            image,
            externalLink,
            contractType,
            creator,
            network,
            sourceCodeLink,
            license,
            attributesJSON,
            functionsJSON,
            eventsJSON,
            mappingsJSON
        );

        // Retrieve and validate the created metadata
        MetadataLib.Metadata memory metadata = metadataGenerator.getMetadata(contractAddress);
        assertEq(metadata.name, name);
        assertEq(metadata.description, description);
        assertEq(metadata.image, image);
        // Continue assertions for other fields...
    }

    function testFailCreateMetadataTwice() public {
        // Parameters for the metadata creation
        address contractAddress = address(this);
        uint256 contractId = 1;
        // Parameters omitted for brevity

        // First metadata creation should succeed
        metadataGenerator.createMetadata(
            contractAddress,
            contractId,
            "First", "First description", "http://first.com/image.png",
            "http://first.com", "Utility", "0xCreator", "Ethereum",
            "http://github.com/first", "MIT", "[]", "[]", "[]", "{}"
        );

        // Attempting to create metadata again for the same contract should fail
        vm.expectRevert("Metadata already exists for this contract");
        metadataGenerator.createMetadata(
            contractAddress,
            contractId,
            "Second", "Second description", "http://second.com/image.png",
            "http://second.com", "Utility", "0xCreator", "Ethereum",
            "http://github.com/second", "MIT", "[]", "[]", "[]", "{}"
        );
    }

    function testNonexistentMetadata() public {
        // Attempt to retrieve metadata for an address that hasn't had metadata created
        vm.expectRevert("No metadata exists for this contract");
        metadataGenerator.getMetadata(address(this));
    }
}