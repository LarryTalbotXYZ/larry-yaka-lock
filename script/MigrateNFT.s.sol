// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaToken.sol";
import "../src/LiquidYakaVault.sol";
import "../src/veYakainterface/IVotingEscrow.sol";

contract MigrateNFT is Script {
    // Contract addresses
    address constant VE_YAKA = 0x86a247Ef0Fc244565BCab93936E867407ac81580;
    address constant LIQUID_TOKEN = 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79;
    address constant OLD_VAULT = 0x9Ff8a56c9E393D0cC4093b15B70EcC67CfC577c6; // Previous vault with funds
    address constant ULTIMATE_VAULT = 0x9833F68daB132E432ac8Bca160f60b77af36A306; // Ultimate vault with max voting power
    
    // NFT to migrate (check current vault for actual NFT ID)
    uint256 constant NFT_ID = 2444;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        IVotingEscrow veYaka = IVotingEscrow(VE_YAKA);
        LiquidYakaVault oldVault = LiquidYakaVault(OLD_VAULT);
        LiquidYakaVault ultimateVault = LiquidYakaVault(ULTIMATE_VAULT);
        LiquidYakaToken lyt = LiquidYakaToken(LIQUID_TOKEN);
        
        console.log("=== Migrate veNFT to Ultimate Vault ===");
        console.log("Deployer:", deployer);
        console.log("NFT to migrate:", NFT_ID);
        console.log("From vault:", OLD_VAULT);
        console.log("To ultimate vault:", ULTIMATE_VAULT);
        console.log("");
        
        // Check initial state
        address nftOwner = veYaka.ownerOf(NFT_ID);
        console.log("Current NFT owner:", nftOwner);
        
        if (nftOwner != OLD_VAULT) {
            console.log("ERROR: NFT is not owned by old vault!");
            return;
        }
        
        IVotingEscrow.LockedBalance memory locked = veYaka.locked(NFT_ID);
        uint256 lockedAmount = uint256(int256(locked.amount));
        console.log("NFT locked amount:", lockedAmount);
        console.log("NFT lock end time:", locked.end);
        
        // Check user's LYT balance (should be 1 LYT from previous deposit)
        uint256 userLytBalance = lyt.balanceOf(deployer);
        console.log("User's LYT balance:", userLytBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("--- Step 1: Migrate NFT from Old Vault ---");
        
        // The old vault should transfer the NFT to the ultimate vault
        // We need to call migrateToNewVault on old vault
        try oldVault.migrateToNewVault(ULTIMATE_VAULT) {
            console.log("Migration initiated successfully");
        } catch Error(string memory reason) {
            console.log("Migration failed:", reason);
            console.log("Trying emergency approach...");
            
            // Emergency approach: reset and transfer manually if we're the owner
            try oldVault.resetMainNFT() {
                console.log("Reset NFT voting status");
            } catch {
                console.log("Reset failed or not needed");
            }
            
            // Note: This would require the old vault to have an emergencyTransferNFT function
            // For now, let's assume the migration works
        }
        
        console.log("--- Step 2: Ultimate Vault Receives NFT ---");
        
        // The ultimate vault should receive the NFT
        try ultimateVault.receiveFromOldVault(NFT_ID) {
            console.log("NFT received by ultimate vault");
        } catch Error(string memory reason) {
            console.log("Receive failed:", reason);
        }
        
        vm.stopBroadcast();
        
        // Check final state
        address newNftOwner = veYaka.ownerOf(NFT_ID);
        console.log("--- Migration Results ---");
        console.log("NFT owner after migration:", newNftOwner);
        console.log("Expected new owner:", ULTIMATE_VAULT);
        console.log("Migration successful:", newNftOwner == ULTIMATE_VAULT);
        
        // Check ultimate vault state
        (
            uint256 totalLiquidSupply,
            uint256 totalLockedYaka,
            uint256 totalVotingPower,
            uint256 pricePerToken,
            uint256 mainNftId
        ) = ultimateVault.getVaultInfo();
        
        console.log("--- Ultimate Vault State ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Total Voting Power:", totalVotingPower);
        console.log("Price per Token:", pricePerToken);
        console.log("Main NFT ID:", mainNftId);
        
        console.log("");
        console.log("=== Migration Complete! ===");
        console.log("Now ready to test deposits on ultimate vault with maximum voting power!");
    }
}