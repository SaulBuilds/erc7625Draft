// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MetadataLib {
    struct Metadata {
        address contractAddress;
        uint256 contractId;
        string name;
        string description;
        string image;
        string externalLink;
        string contractType;
        string creator;
        string network;
        string sourceCodeLink;
        string license;
        string attributesJSON; // Encoded JSON for attributes
        string functionsJSON; // Encoded JSON for functions
        string eventsJSON; // Encoded JSON for events
        string mappingsJSON; // Encoded JSON for mappings
    }

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

    function decodeMetadata(bytes memory data) external pure returns (Metadata memory) {
        return abi.decode(data, (Metadata));
    }
}
