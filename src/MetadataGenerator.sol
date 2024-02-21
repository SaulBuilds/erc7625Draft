// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetadataLib.sol";

/// @title Metadata Generator
/// @dev Contract for generating and storing metadata for other contracts.
/// Utilizes the MetadataLib library for encoding and decoding metadata.
contract MetadataGenerator {
    /// @notice Stores metadata for contract addresses.
    mapping(address => bytes) public metadataStorage;

    /// @notice Emitted when new metadata is created for a contract.
    event MetadataCreated(address indexed contractAddress, bytes metadata);

    /// @notice Creates and stores metadata for a specific contract address.
    /// @dev Encodes various details about a contract into a bytes array and stores it.
    /// Emits a MetadataCreated event upon success.
    /// @param contractAddress The address of the contract for which metadata is created.
    /// @param contractId Unique identifier for the contract.
    /// @param name Name of the contract.
    /// @param description Description of the contract.
    /// @param image URL to an image representing the contract.
    /// @param externalLink External link providing more information about the contract.
    /// @param contractType Type of the contract (e.g., "ERC721", "ERC20").
    /// @param creator Address or identifier of the creator of the contract.
    /// @param network Network on which the contract is deployed.
    /// @param sourceCodeLink Link to the source code of the contract.
    /// @param license License under which the contract is released.
    /// @param attributesJSON JSON string representing attributes of the contract.
    /// @param functionsJSON JSON string listing functions of the contract.
    /// @param eventsJSON JSON string listing events of the contract.
    /// @param mappingsJSON JSON string listing mappings of the contract.
    function createMetadata(
        address contractAddress,
        uint256 contractId,
        string memory name,
        string memory description,
        string memory image,
        string memory externalLink,
        string memory contractType,
        string memory creator,
        string memory network,
        string memory sourceCodeLink,
        string memory license,
        string memory attributesJSON,
        string memory functionsJSON,
        string memory eventsJSON,
        string memory mappingsJSON
    ) public {
        require(metadataStorage[contractAddress].length == 0, "Metadata already exists for this contract");

        bytes memory encodedMetadata = MetadataLib.encodeMetadata(
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
        metadataStorage[contractAddress] = encodedMetadata;

        emit MetadataCreated(contractAddress, encodedMetadata);
    }

    /// @notice Retrieves metadata for a given contract address.
    /// @dev Decodes the stored bytes array into a Metadata struct.
    /// Requires that metadata exists for the contract address.
    /// @param contractAddress The address of the contract whose metadata is being retrieved.
    /// @return A Metadata struct containing the decoded details of the contract.
    function getMetadata(address contractAddress) public view returns (MetadataLib.Metadata memory) {
        require(metadataStorage[contractAddress].length > 0, "No metadata exists for this contract");
        return MetadataLib.decodeMetadata(metadataStorage[contractAddress]);
    }
}