// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MetadataLib.sol";

contract MetadataGenerator {
    mapping(address => bytes) public metadataStorage;

    event MetadataCreated(address indexed contractAddress, bytes metadata);

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

    function getMetadata(address contractAddress) public view returns (MetadataLib.Metadata memory) {
        require(metadataStorage[contractAddress].length > 0, "No metadata exists for this contract");
        return MetadataLib.decodeMetadata(metadataStorage[contractAddress]);
    }
}