// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "src/MetadataGenerator.sol";
import "src/ERC7625.sol";

// Define the script contract
contract DeployERC7625 is Script {
    function run() external {
        // Deploy the MetadataGenerator contract
        vm.startBroadcast(); // Start broadcasting transactions

        MetadataGenerator metadataGenerator = new MetadataGenerator();
        console.log("MetadataGenerator deployed at:", address(metadataGenerator));

        // Deploy the ERC7625 contract, passing the address of the MetadataGenerator
        ERC7625 erc7625 = new ERC7625(address(metadataGenerator));
        console.log("ERC7625 deployed at:", address(erc7625));

        vm.stopBroadcast(); // Stop broadcasting transactions
    }
}
