// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaVault.sol";
import "../src/LiquidYakaToken.sol";
import "../src/veYakainterface/IVotingEscrow.sol";

contract TestWithdraw is Script {
    // Contract addresses  
    address constant NEW_VAULT = 0x2fB0DA76902E13810460A80045C3FC5170776543;
    address constant LIQUID_TOKEN = 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79;
    address constant VE_YAKA = 0x86a247Ef0Fc244565BCab93936E867407ac81580;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        LiquidYakaVault vault = LiquidYakaVault(NEW_VAULT);
        LiquidYakaToken lyt = LiquidYakaToken(LIQUID_TOKEN);
        IVotingEscrow veYaka = IVotingEscrow(VE_YAKA);
        
        console.log("=== Test Withdrawal (1 LYT -> veNFT) ===");
        console.log("User:", deployer);
        console.log("Vault:", NEW_VAULT);
        console.log("");
        
        // Check initial state
        uint256 userLytBalance = lyt.balanceOf(deployer);
        console.log("User's LYT balance before:", userLytBalance);
        
        (
            uint256 totalLiquidSupply,
            uint256 totalLockedYaka,
            uint256 totalVotingPower,
            uint256 pricePerToken,
            uint256 mainNftId
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State Before Withdrawal ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Price per Token:", pricePerToken);
        console.log("Main NFT ID:", mainNftId);
        console.log("");
        
        // Test withdrawal amount
        uint256 withdrawAmount = 1 ether; // 1 LYT
        console.log("Attempting to withdraw:", withdrawAmount, "LYT");
        
        if (userLytBalance < withdrawAmount) {
            console.log("ERROR: Insufficient LYT balance for withdrawal");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve vault to burn LYT tokens
        console.log("Approving vault to burn LYT tokens...");
        lyt.approve(NEW_VAULT, withdrawAmount);
        
        // Perform withdrawal
        console.log("Executing withdrawal...");
        vault.withdraw(withdrawAmount);
        console.log("Withdrawal transaction completed!");
        
        // Find the NFT we just received by checking our NFT balance
        // The new NFT should be one we didn't have before
        uint256 nftId = 0;
        // Since we know the split creates NFTs sequentially after the main NFT (2424)
        // We can check the range after the main NFT
        for (uint256 i = 2425; i <= 2450; i++) {
            try veYaka.ownerOf(i) returns (address owner) {
                if (owner == deployer) {
                    nftId = i;
                    console.log("Found received NFT ID:", nftId);
                    break;
                }
            } catch {
                continue;
            }
        }
        
        vm.stopBroadcast();
        
        // Check final state
        uint256 userLytBalanceAfter = lyt.balanceOf(deployer);
        
        if (nftId == 0) {
            console.log("ERROR: Could not find received NFT!");
            return;
        }
        
        address nftOwner = veYaka.ownerOf(nftId);
        IVotingEscrow.LockedBalance memory locked = veYaka.locked(nftId);
        uint256 nftLockedAmount = uint256(int256(locked.amount));
        
        console.log("");
        console.log("=== Withdrawal Results ===");
        console.log("User's LYT balance after:", userLytBalanceAfter);
        console.log("LYT burned:", userLytBalance - userLytBalanceAfter);
        console.log("NFT received:", nftId);
        console.log("NFT owner:", nftOwner);
        console.log("NFT locked amount:", nftLockedAmount);
        console.log("NFT lock end:", locked.end);
        
        // Check vault state after
        (
            uint256 totalLiquidSupplyAfter,
            uint256 totalLockedYakaAfter,
            uint256 totalVotingPowerAfter,
            uint256 pricePerTokenAfter,
            uint256 mainNftIdAfter
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State After Withdrawal ---");
        console.log("Total Liquid Supply:", totalLiquidSupplyAfter);
        console.log("Total Locked YAKA:", totalLockedYakaAfter);
        console.log("Price per Token:", pricePerTokenAfter);
        console.log("Main NFT ID:", mainNftIdAfter);
        
        // Verify results
        bool withdrawalSuccess = (
            nftOwner == deployer &&
            userLytBalanceAfter == userLytBalance - withdrawAmount &&
            nftLockedAmount >= withdrawAmount * 995 / 1000 && // Allow 0.5% tolerance
            nftLockedAmount <= withdrawAmount * 1005 / 1000
        );
        
        console.log("");
        console.log("=== Test Results ===");
        console.log("Withdrawal test passed:", withdrawalSuccess);
        
        if (!withdrawalSuccess) {
            console.log("ERROR: Withdrawal test failed");
            console.log("Expected NFT owner:", deployer, "Got:", nftOwner);
            console.log("Expected LYT burned:", withdrawAmount, "Got:", userLytBalance - userLytBalanceAfter);
            console.log("Expected NFT amount ~", withdrawAmount, "Got:", nftLockedAmount);
        } else {
            console.log("SUCCESS: Fixed withdrawal logic works correctly!");
        }
    }
}