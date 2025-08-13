// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaToken.sol";
import "../src/LiquidYakaVault.sol";

contract DeployVaultOnly is Script {
    // Real contract addresses
    address constant YAKA = 0x51121BCAE92E302f19D06C193C95E1f7b81a444b;
    address constant VE_YAKA = 0x86a247Ef0Fc244565BCab93936E867407ac81580;
    address constant VOTER_V3 = 0x36068f15f257896E03fb7EdbA3D18898d0ade809;
    
    // Existing LiquidYakaToken 
    address constant EXISTING_LIQUID_TOKEN = 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Deploy New Vault with Fixed Logic ===");
        console.log("Deployer:", deployer);
        console.log("Using existing LiquidYakaToken:", EXISTING_LIQUID_TOKEN);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy new LiquidYakaVault with fixed lock extension logic
        console.log("Deploying new LiquidYakaVault...");
        LiquidYakaVault newVault = new LiquidYakaVault(
            YAKA,
            VE_YAKA,
            VOTER_V3,
            EXISTING_LIQUID_TOKEN
        );
        console.log("New LiquidYakaVault deployed at:", address(newVault));
        
        // Connect existing token to new vault
        LiquidYakaToken liquidToken = LiquidYakaToken(EXISTING_LIQUID_TOKEN);
        
        // Remove authorization from old vault (if any) and authorize new vault
        console.log("Authorizing new vault for liquid token operations...");
        liquidToken.setVaultAuthorization(address(newVault), true);
        console.log("New vault authorized");
        
        // Optionally revoke old vault authorization
        address oldVault = 0xb45243027fdC5c52862b3f9d81b296420491b4CE;
        console.log("Revoking authorization from old vault...");
        liquidToken.setVaultAuthorization(oldVault, false);
        console.log("Old vault authorization revoked");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== New Vault Deployment Complete ===");
        console.log("LiquidYakaToken (LYT):", EXISTING_LIQUID_TOKEN, "(existing)");
        console.log("New LiquidYakaVault:", address(newVault));
        console.log("Old LiquidYakaVault:", oldVault, "(deauthorized)");
        console.log("");
        console.log("Ready to test deposits with fixed lock extension logic!");
    }
}