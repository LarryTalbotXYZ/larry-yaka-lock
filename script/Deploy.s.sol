// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaToken.sol";
import "../src/LiquidYakaVault.sol";

contract Deploy is Script {
    // Real contract addresses
    address constant YAKA = 0x51121BCAE92E302f19D06C193C95E1f7b81a444b;
    address constant VE_YAKA = 0x86a247Ef0Fc244565BCab93936E867407ac81580;
    address constant VOTER_V3 = 0x36068f15f257896E03fb7EdbA3D18898d0ade809;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Liquid YAKA Deployment ===");
        console.log("Deployer:", deployer);
        console.log("YAKA Token:", YAKA);
        console.log("veYAKA (VotingEscrow):", VE_YAKA);
        console.log("VoterV3:", VOTER_V3);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy LiquidYakaToken (LYT)
        console.log("Deploying LiquidYakaToken...");
        LiquidYakaToken liquidToken = new LiquidYakaToken(deployer);
        console.log("LiquidYakaToken (LYT) deployed at:", address(liquidToken));
        
        // 2. Deploy LiquidYakaVault
        console.log("Deploying LiquidYakaVault...");
        LiquidYakaVault vault = new LiquidYakaVault(
            YAKA,
            VE_YAKA,
            VOTER_V3,
            address(liquidToken)
        );
        console.log("LiquidYakaVault deployed at:", address(vault));
        
        // 3. Authorize vault to mint/burn liquid tokens
        console.log("Authorizing vault for liquid token operations...");
        liquidToken.setVaultAuthorization(address(vault), true);
        console.log("Vault authorized");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Deployment Complete ===");
        console.log("LiquidYakaToken (LYT):", address(liquidToken));
        console.log("LiquidYakaVault:", address(vault));
        console.log("");
        console.log("Next steps:");
        console.log("1. Verify contracts on block explorer");
        console.log("2. Test deposit functionality");
        console.log("3. Configure voting strategies");
    }
}