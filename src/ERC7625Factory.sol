// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/utils/Create2.sol";
import "./ERC7625.sol";


contract ERC7625Factory {
    // Constructor code of the ERC7625 contract
    // Assuming ERC7625 has an initializer or no need for constructor arguments
    bytes private constant ERC7625Bytecode = type(ERC7625).creationCode;

    function getDeployedAddress(bytes32 salt) public view returns (address) {
        // Compute the address of the contract to be deployed
        return Create2.computeAddress(salt, keccak256(ERC7625Bytecode));
    }

    function createERC7625(bytes32 salt) external payable returns (address) {
        // Deploy the ERC7625 contract using Create2
        address deployedAddress = Create2.deploy(0, salt, ERC7625Bytecode);
        require(deployedAddress != address(0), "Failed to deploy using Create2");
        
        // Optional: Initialize the contract if needed
        // ERC7625(deployedAddress).initialize([]);

        return deployedAddress;
    }
}