// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaToken.sol";
import "../src/LiquidYakaVault.sol";

contract DeployLiquidYaka is Script {
    // Mainnet addresses
    address constant YAKA = 0x51121BCAE92E302f19D06C193C95E1f7b81a444b;
    address constant VE_YAKA = 0x86a247Ef0Fc244565BCab93936E867407ac81580;
    address constant VOTER_V3 = 0x36068f15f257896E03fb7EdbA3D18898d0ade809;
    address constant REWARD_DISTRIBUTOR = 0xaC76B04F87ccbfb4ba01f76F34B9f1B770839ebe;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts...");
        console.log("Deployer:", deployer);
        console.log("YAKA:", YAKA);
        console.log("veYAKA:", VE_YAKA);
        console.log("VoterV3:", VOTER_V3);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy LiquidYakaToken first
        LiquidYakaToken liquidToken = new LiquidYakaToken(deployer);
        console.log("LiquidYakaToken deployed at:", address(liquidToken));
        
        // Deploy LiquidYakaVault
        LiquidYakaVault vault = new LiquidYakaVault(
            YAKA,
            VE_YAKA,
            VOTER_V3,
            REWARD_DISTRIBUTOR,
            address(liquidToken),
            deployer  // fee recipient
        );
        console.log("LiquidYakaVault deployed at:", address(vault));
        
        // Authorize the vault to mint/burn liquid tokens
        liquidToken.setVaultAuthorization(address(vault), true);
        console.log("Vault authorized for liquid token operations");
        
        vm.stopBroadcast();
        
        console.log("\nDeployment Summary:");
        console.log("LiquidYakaToken:", address(liquidToken));
        console.log("LiquidYakaVault:", address(vault));
        console.log("\nNext steps:");
        console.log("1. Verify contracts on explorer");
        console.log("2. Test deposit functionality");
        console.log("3. Set up voting strategies");
    }
}