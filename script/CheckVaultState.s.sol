// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaVault.sol";

contract CheckVaultState is Script {
    // Contract addresses
    address constant OLD_VAULT = 0x9Ff8a56c9E393D0cC4093b15B70EcC67CfC577c6;
    address constant ULTIMATE_VAULT = 0x9833F68daB132E432ac8Bca160f60b77af36A306;
    
    function run() external view {
        LiquidYakaVault oldVault = LiquidYakaVault(OLD_VAULT);
        LiquidYakaVault ultimateVault = LiquidYakaVault(ULTIMATE_VAULT);
        
        console.log("=== Vault States ===");
        console.log("");
        
        // Check old vault
        console.log("--- Old Vault ---");
        (
            uint256 oldTotalLiquidSupply,
            uint256 oldTotalLockedYaka,
            uint256 oldTotalVotingPower,
            uint256 oldPricePerToken,
            uint256 oldMainNftId
        ) = oldVault.getVaultInfo();
        
        console.log("Total Liquid Supply:", oldTotalLiquidSupply);
        console.log("Total Locked YAKA:", oldTotalLockedYaka);
        console.log("Total Voting Power:", oldTotalVotingPower);
        console.log("Main NFT ID:", oldMainNftId);
        
        if (oldMainNftId != 0) {
            (
                uint256 tokenId,
                uint256 lockedAmount,
                uint256 endTime,
                uint256 timeLeft,
                uint256 votingPower
            ) = oldVault.getMainNFTLockInfo();
            
            console.log("--- Old Vault NFT Details ---");
            console.log("Token ID:", tokenId);
            console.log("Locked Amount:", lockedAmount);
            console.log("End Time:", endTime);
            console.log("Time Left (days):", timeLeft / 86400);
            console.log("Voting Power:", votingPower);
        }
        
        console.log("");
        
        // Check ultimate vault
        console.log("--- Ultimate Vault ---");
        (
            uint256 ultimateTotalLiquidSupply,
            uint256 ultimateTotalLockedYaka,
            uint256 ultimateTotalVotingPower,
            uint256 ultimatePricePerToken,
            uint256 ultimateMainNftId
        ) = ultimateVault.getVaultInfo();
        
        console.log("Total Liquid Supply:", ultimateTotalLiquidSupply);
        console.log("Total Locked YAKA:", ultimateTotalLockedYaka);
        console.log("Total Voting Power:", ultimateTotalVotingPower);
        console.log("Main NFT ID:", ultimateMainNftId);
        
        if (ultimateMainNftId != 0) {
            (
                uint256 tokenId,
                uint256 lockedAmount,
                uint256 endTime,
                uint256 timeLeft,
                uint256 votingPower
            ) = ultimateVault.getMainNFTLockInfo();
            
            console.log("--- Ultimate Vault NFT Details ---");
            console.log("Token ID:", tokenId);
            console.log("Locked Amount:", lockedAmount);
            console.log("End Time:", endTime);
            console.log("Time Left (days):", timeLeft / 86400);
            console.log("Voting Power:", votingPower);
        }
    }
}