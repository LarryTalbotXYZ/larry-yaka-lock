// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaVault.sol";
import "../src/LiquidYakaToken.sol";
import "../src/veYakainterface/IVotingEscrow.sol";

contract TestDepositNFT is Script {
    // Contract addresses
    address constant NEW_VAULT = 0x2fB0DA76902E13810460A80045C3FC5170776543;
    address constant LIQUID_TOKEN = 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79;
    address constant VE_YAKA = 0x86a247Ef0Fc244565BCab93936E867407ac81580;
    address constant VOTER_V3 = 0x36068f15f257896E03fb7EdbA3D18898d0ade809;
    
    // Your NFT ID from the withdrawal test
    uint256 constant NFT_ID = 2426;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        LiquidYakaVault vault = LiquidYakaVault(NEW_VAULT);
        LiquidYakaToken lyt = LiquidYakaToken(LIQUID_TOKEN);
        IVotingEscrow veYaka = IVotingEscrow(VE_YAKA);
        IVoter voter = IVoter(VOTER_V3);
        
        console.log("=== Test Deposit NFT #2426 ===");
        console.log("User:", deployer);
        console.log("Vault:", NEW_VAULT);
        console.log("NFT ID:", NFT_ID);
        console.log("");
        
        // Check initial state
        uint256 userLytBalance = lyt.balanceOf(deployer);
        
        console.log("User's LYT balance before:", userLytBalance);
        
        // Check NFT ownership and details
        address nftOwner = veYaka.ownerOf(NFT_ID);
        console.log("NFT owner:", nftOwner);
        
        if (nftOwner != deployer) {
            console.log("ERROR: You don't own NFT", NFT_ID);
            return;
        }
        
        IVotingEscrow.LockedBalance memory locked = veYaka.locked(NFT_ID);
        uint256 nftLockedAmount = uint256(int256(locked.amount));
        console.log("NFT locked amount:", nftLockedAmount);
        console.log("NFT lock end:", locked.end);
        console.log("");
        
        // Check vault state before
        (
            uint256 totalLiquidSupply,
            uint256 totalLockedYaka,
            uint256 totalVotingPower,
            uint256 pricePerToken,
            uint256 mainNftId
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State Before NFT Deposit ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Price per Token:", pricePerToken);
        console.log("Main NFT ID:", mainNftId);
        
        // Check main NFT state before
        if (mainNftId > 0) {
            IVotingEscrow.LockedBalance memory mainLocked = veYaka.locked(mainNftId);
            uint256 mainNftAmount = uint256(int256(mainLocked.amount));
            console.log("Main NFT locked amount (before):", mainNftAmount);
        }
        console.log("");
        
        // Calculate expected LYT to receive
        uint256 expectedLyt = (nftLockedAmount * 1e18) / pricePerToken;
        console.log("Expected LYT to receive:", expectedLyt);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Reset votes if NFT has any votes
        try voter.reset(NFT_ID) {
            console.log("Reset votes for NFT", NFT_ID);
        } catch {
            console.log("NFT", NFT_ID, "has no votes to reset (or already reset)");
        }
        
        // Approve and deposit NFT (using low-level call since approve not in interface)
        console.log("Approving vault to receive NFT...");
        (bool success,) = VE_YAKA.call(abi.encodeWithSignature("approve(address,uint256)", NEW_VAULT, NFT_ID));
        require(success, "Approval failed");
        
        console.log("Depositing NFT", NFT_ID, "...");
        vault.depositNFT(NFT_ID);
        console.log("NFT deposit completed!");
        
        vm.stopBroadcast();
        
        // Check final state
        uint256 userLytBalanceAfter = lyt.balanceOf(deployer);
        uint256 lytReceived = userLytBalanceAfter - userLytBalance;
        
        console.log("");
        console.log("=== NFT Deposit Results ===");
        console.log("LYT received:", lytReceived);
        console.log("User's LYT balance after:", userLytBalanceAfter);
        
        // Check NFT ownership after deposit
        try veYaka.ownerOf(NFT_ID) returns (address newOwner) {
            console.log("NFT", NFT_ID, "now owned by:", newOwner);
            if (newOwner == NEW_VAULT) {
                console.log("SUCCESS: NFT transferred to vault");
            } else {
                console.log("ERROR: NFT not owned by vault");
            }
        } catch {
            console.log("NFT", NFT_ID, "no longer exists (merged into main NFT)");
        }
        
        // Check vault state after
        (
            uint256 totalLiquidSupplyAfter,
            uint256 totalLockedYakaAfter,
            uint256 totalVotingPowerAfter,
            uint256 pricePerTokenAfter,
            uint256 mainNftIdAfter
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State After NFT Deposit ---");
        console.log("Total Liquid Supply:", totalLiquidSupplyAfter);
        console.log("Total Locked YAKA:", totalLockedYakaAfter);
        console.log("Price per Token:", pricePerTokenAfter);
        console.log("Main NFT ID:", mainNftIdAfter);
        
        // Check main NFT state after
        if (mainNftIdAfter > 0) {
            IVotingEscrow.LockedBalance memory mainLockedAfter = veYaka.locked(mainNftIdAfter);
            uint256 mainNftAmountAfter = uint256(int256(mainLockedAfter.amount));
            console.log("Main NFT locked amount (after):", mainNftAmountAfter);
            console.log("Main NFT amount increased by:", mainNftAmountAfter - totalLockedYaka);
        }
        
        // Verify results
        bool nftDepositSuccess = (
            lytReceived >= expectedLyt * 995 / 1000 && // Allow 0.5% tolerance
            lytReceived <= expectedLyt * 1005 / 1000 &&
            totalLiquidSupplyAfter == totalLiquidSupply + lytReceived &&
            totalLockedYakaAfter >= totalLockedYaka + nftLockedAmount * 995 / 1000
        );
        
        console.log("");
        console.log("=== Test Results ===");
        console.log("NFT deposit test passed:", nftDepositSuccess);
        console.log("Expected LYT:", expectedLyt);
        console.log("Actual LYT received:", lytReceived);
        console.log("Vault total supply change:", totalLiquidSupplyAfter - totalLiquidSupply);
        console.log("Vault locked YAKA change:", totalLockedYakaAfter - totalLockedYaka);
        
        if (nftDepositSuccess) {
            console.log("SUCCESS: NFT deposit works correctly!");
            console.log("Your NFT was merged into the main NFT and you received LYT!");
        } else {
            console.log("ERROR: NFT deposit test failed");
        }
        
        // Show price stability
        if (pricePerTokenAfter == pricePerToken) {
            console.log("SUCCESS: Price remained stable at", pricePerToken);
        } else {
            console.log("NOTE: Price changed from", pricePerToken, "to", pricePerTokenAfter);
        }
    }
}