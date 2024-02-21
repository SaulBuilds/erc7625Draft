// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Metadata Library
/// @dev Library for encoding and decoding metadata related to contracts.
///      Provides functionality to handle complex data structures associated with contract metadata. 
library MetadataLib {
    /// @dev Struct to hold detailed metadata for contracts.
    struct Metadata {
        address contractAddress;// Address of the contract
        uint256 contractId;     // Unique identifier for the contract
        string name;            // Name of the contract
        string description;     // Description of the contract
        string image;           // Image URL for the contract
        string externalLink;    // External URL for more information about the contract
        string contractType;    // Type of the contract (e.g., ERC20, ERC721)
        string creator;         // Creator of the contract
        string network;         // Network where the contract is deployed
        string sourceCodeLink;  // Link to the contract's source code
        string license;         // License of the contract
        string attributesJSON;  // Encoded JSON for attributes
        string functionsJSON;   // Encoded JSON for functions
        string eventsJSON;      // Encoded JSON for events
        string mappingsJSON;    // Encoded JSON for mappings
    }

    /// @notice Encodes contract metadata into a bytes array.
    /// @dev Encodes various pieces of information about a contract into a single bytes array.
    /// @param contractAddress The address of the contract.
    /// @param contractId Unique identifier for the contract.
    /// @param name Name of the contract.
    /// @param description Description of the contract.
    /// @param image Image URL for the contract.
    /// @param externalLink External URL for more information about the contract.
    /// @param contractType Type of the contract.
    /// @param creator Creator of the contract.
    /// @param network Network where the contract is deployed.
    /// @param sourceCodeLink Link to the contract's source code.
    /// @param license License of the contract.
    /// @param attributesJSON Encoded JSON string for attributes.
    /// @param functionsJSON Encoded JSON string for functions.
    /// @param eventsJSON Encoded JSON string for events.
    /// @param mappingsJSON Encoded JSON string for mappings.
    /// @return bytes memory The encoded metadata as a bytes array.
    function encodeMetadata(
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
    ) external pure returns (bytes memory) {
        return abi.encode(
            Metadata(
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
            )
        );
    }

    /// @notice Decodes a bytes array back into a Metadata struct.
    /// @dev Decodes a previously encoded bytes array containing metadata information back into the Metadata struct.
    /// @param data The bytes array to be decoded.
    /// @return Metadata The decoded Metadata struct.
    function decodeMetadata(bytes memory data) external pure returns (Metadata memory) {
        return abi.decode(data, (Metadata));
    }
}
