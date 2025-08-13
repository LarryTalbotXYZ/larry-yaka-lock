// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract VerifyToken is Script {
    function run() external {
        console.log("=== Token Verification Info ===");
        console.log("Token Address: 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79");
        console.log("API Key: 0f3eea4b-ad42-42dd-a48d-76cf6d14955b");
        console.log("Network: Sei Network (Chain ID: 1329)");
        console.log("");
        console.log("Use this information to verify the contract manually on Sei block explorer");
    }
}