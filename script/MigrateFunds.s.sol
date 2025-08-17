// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaVault.sol";

contract MigrateFunds is Script {
    // Contract addresses
    address constant OLD_VAULT = 0x9833F68daB132E432ac8Bca160f60b77af36A306; // Previous ultimate vault
    address constant NEW_VAULT = 0x25184F590aAf61D41677ea3CD6Df009dEAEBBB13; // Current vault with fees
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        LiquidYakaVault oldVault = LiquidYakaVault(OLD_VAULT);
        LiquidYakaVault newVault = LiquidYakaVault(NEW_VAULT);
        
        console.log("=== Fund Migration ===");
        console.log("Owner:", deployer);
        console.log("Old Vault:", OLD_VAULT);
        console.log("New Vault:", NEW_VAULT);
        console.log("");
        
        // Check old vault info
        (
            uint256 oldMainNftId,
            uint256 oldLockedAmount,
            uint256 oldEndTime,
            uint256 oldTimeLeft,
            uint256 oldVotingPower
        ) = oldVault.getMainNFTLockInfo();
        
        console.log("--- Old Vault Info ---");
        console.log("Main NFT ID:", oldMainNftId);
        console.log("Locked Amount:", oldLockedAmount);
        console.log("End Time:", oldEndTime);
        console.log("Time Left:", oldTimeLeft);
        console.log("Voting Power:", oldVotingPower);
        console.log("");
        
        // Check new vault info
        (
            uint256 newMainNftId,
            uint256 newLockedAmount,
            uint256 newEndTime,
            uint256 newTimeLeft,
            uint256 newVotingPower
        ) = newVault.getMainNFTLockInfo();
        
        console.log("--- New Vault Info (Before Migration) ---");
        console.log("Main NFT ID:", newMainNftId);
        console.log("Locked Amount:", newLockedAmount);
        console.log("End Time:", newEndTime);
        console.log("Time Left:", newTimeLeft);
        console.log("Voting Power:", newVotingPower);
        console.log("");
        
        if (oldMainNftId == 0) {
            console.log("No funds to migrate - old vault has no main NFT");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Migrate from old vault to new vault
        console.log("--- Migration Process ---");
        console.log("Step 1: Migrating NFT from old vault to new vault...");
        oldVault.migrateToNewVault(NEW_VAULT);
        console.log("Migration completed");
        
        // Step 2: New vault receives the NFT
        console.log("Step 2: New vault receiving NFT...");
        newVault.receiveFromOldVault(oldMainNftId);
        console.log("NFT received by new vault");
        
        vm.stopBroadcast();
        
        // Check final status
        console.log("");
        console.log("--- Final Status ---");
        
        // Check old vault (should be empty now)
        (
            uint256 finalOldMainNftId,
            uint256 finalOldLockedAmount,,,
        ) = oldVault.getMainNFTLockInfo();
        
        console.log("Old Vault - Main NFT ID:", finalOldMainNftId);
        console.log("Old Vault - Locked Amount:", finalOldLockedAmount);
        
        // Check new vault (should have the migrated NFT)
        (
            uint256 finalNewMainNftId,
            uint256 finalNewLockedAmount,
            uint256 finalNewEndTime,
            uint256 finalNewTimeLeft,
            uint256 finalNewVotingPower
        ) = newVault.getMainNFTLockInfo();
        
        console.log("New Vault - Main NFT ID:", finalNewMainNftId);
        console.log("New Vault - Locked Amount:", finalNewLockedAmount);
        console.log("New Vault - End Time:", finalNewEndTime);
        console.log("New Vault - Time Left:", finalNewTimeLeft);
        console.log("New Vault - Voting Power:", finalNewVotingPower);
        
        // Verification
        bool migrationSuccess = (
            finalOldMainNftId == 0 && 
            finalNewMainNftId == oldMainNftId &&
            finalNewLockedAmount == oldLockedAmount
        );
        
        console.log("");
        console.log("=== Migration Result ===");
        console.log("Migration successful:", migrationSuccess);
        
        if (migrationSuccess) {
            console.log("SUCCESS: Funds migrated successfully!");
            console.log("- Old vault is now empty");
            console.log("- New vault has the migrated NFT");
            console.log("- All YAKA tokens preserved");
        } else {
            console.log("WARNING: Migration verification failed!");
            if (finalOldMainNftId != 0) console.log("- Old vault still has NFT");
            if (finalNewMainNftId != oldMainNftId) console.log("- New vault NFT ID mismatch");
            if (finalNewLockedAmount != oldLockedAmount) console.log("- Amount mismatch");
        }
    }
}