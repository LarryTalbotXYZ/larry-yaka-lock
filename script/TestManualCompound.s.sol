// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaVault.sol";
import "../src/LiquidYakaToken.sol";
import "../src/veYakainterface/IVotingEscrow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestManualCompound is Script {
    // Updated contract addresses (new vault)
    address constant NEW_VAULT = 0x2fB0DA76902E13810460A80045C3FC5170776543;
    address constant LIQUID_TOKEN = 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79;
    address constant YAKA_TOKEN = 0x51121BCAE92E302f19D06C193C95E1f7b81a444b;
    address constant VE_YAKA = 0x86a247Ef0Fc244565BCab93936E867407ac81580;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        LiquidYakaVault vault = LiquidYakaVault(NEW_VAULT);
        LiquidYakaToken lyt = LiquidYakaToken(LIQUID_TOKEN);
        IERC20 yaka = IERC20(YAKA_TOKEN);
        IVotingEscrow veYaka = IVotingEscrow(VE_YAKA);
        
        console.log("=== Test Manual Compound + Price Impact ===");
        console.log("User:", deployer);
        console.log("Vault:", NEW_VAULT);
        console.log("");
        
        // Check initial state
        uint256 userYakaBalance = yaka.balanceOf(deployer);
        uint256 userLytBalance = lyt.balanceOf(deployer);
        
        console.log("User's YAKA balance:", userYakaBalance);
        console.log("User's LYT balance:", userLytBalance);
        
        (
            uint256 totalLiquidSupply,
            uint256 totalLockedYaka,
            uint256 totalVotingPower,
            uint256 pricePerToken,
            uint256 mainNftId
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State Before Compound ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Price per Token (before):", pricePerToken);
        console.log("Main NFT ID:", mainNftId);
        
        // Check main NFT state before
        if (mainNftId > 0) {
            IVotingEscrow.LockedBalance memory locked = veYaka.locked(mainNftId);
            uint256 mainNftAmount = uint256(int256(locked.amount));
            console.log("Main NFT locked amount (before):", mainNftAmount);
        }
        console.log("");
        
        // === STEP 1: Manual Compound ===
        uint256 compoundAmount = 2 ether; // 2 YAKA to compound
        console.log("=== Step 1: Manual Compound ===");
        console.log("Compounding:", compoundAmount, "YAKA");
        
        if (userYakaBalance < compoundAmount) {
            console.log("ERROR: Insufficient YAKA balance for compound");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve vault to spend YAKA for compounding
        console.log("Approving vault to spend YAKA for compound...");
        yaka.approve(NEW_VAULT, compoundAmount);
        
        // Execute manual compound
        console.log("Executing manual compound...");
        vault.manualCompound(compoundAmount);
        console.log("Manual compound completed!");
        
        vm.stopBroadcast();
        
        // Check state after compound
        uint256 userYakaBalanceAfterCompound = yaka.balanceOf(deployer);
        
        (
            uint256 totalLiquidSupplyAfterCompound,
            uint256 totalLockedYakaAfterCompound,
            uint256 totalVotingPowerAfterCompound,
            uint256 pricePerTokenAfterCompound,
            uint256 mainNftIdAfterCompound
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State After Compound ---");
        console.log("YAKA spent on compound:", userYakaBalance - userYakaBalanceAfterCompound);
        console.log("Total Liquid Supply:", totalLiquidSupplyAfterCompound);
        console.log("Total Locked YAKA:", totalLockedYakaAfterCompound);
        console.log("Price per Token (after compound):", pricePerTokenAfterCompound);
        console.log("Main NFT ID:", mainNftIdAfterCompound);
        
        // Check main NFT state after compound
        if (mainNftIdAfterCompound > 0) {
            IVotingEscrow.LockedBalance memory locked = veYaka.locked(mainNftIdAfterCompound);
            uint256 mainNftAmount = uint256(int256(locked.amount));
            console.log("Main NFT locked amount (after compound):", mainNftAmount);
            console.log("NFT amount increased by:", mainNftAmount - totalLockedYaka);
        }
        
        // Price impact from compound
        uint256 priceIncrease = pricePerTokenAfterCompound > pricePerToken ? 
            pricePerTokenAfterCompound - pricePerToken : 0;
        console.log("Price increase from compound:", priceIncrease);
        console.log("");
        
        // === STEP 2: Test Deposit After Compound ===
        uint256 depositAmount = 1 ether; // 1 YAKA deposit
        console.log("=== Step 2: Test Deposit After Compound ===");
        console.log("Depositing:", depositAmount, "YAKA");
        
        uint256 currentYakaBalance = yaka.balanceOf(deployer);
        if (currentYakaBalance < depositAmount) {
            console.log("ERROR: Insufficient YAKA balance for deposit");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve and deposit
        console.log("Approving vault for deposit...");
        yaka.approve(NEW_VAULT, depositAmount);
        
        console.log("Executing deposit...");
        vault.deposit(depositAmount);
        console.log("Deposit completed!");
        
        vm.stopBroadcast();
        
        // Check final state
        uint256 userYakaBalanceAfterDeposit = yaka.balanceOf(deployer);
        uint256 userLytBalanceAfterDeposit = lyt.balanceOf(deployer);
        uint256 lytReceived = userLytBalanceAfterDeposit - userLytBalance;
        
        (
            uint256 totalLiquidSupplyFinal,
            uint256 totalLockedYakaFinal,
            uint256 totalVotingPowerFinal,
            uint256 pricePerTokenFinal,
            uint256 mainNftIdFinal
        ) = vault.getVaultInfo();
        
        console.log("--- Final State After Deposit ---");
        console.log("YAKA deposited:", userYakaBalanceAfterCompound - userYakaBalanceAfterDeposit);
        console.log("LYT received:", lytReceived);
        console.log("Total Liquid Supply:", totalLiquidSupplyFinal);
        console.log("Total Locked YAKA:", totalLockedYakaFinal);
        console.log("Price per Token (final):", pricePerTokenFinal);
        
        // Check main NFT final state
        if (mainNftIdFinal > 0) {
            IVotingEscrow.LockedBalance memory locked = veYaka.locked(mainNftIdFinal);
            uint256 mainNftAmountFinal = uint256(int256(locked.amount));
            console.log("Main NFT locked amount (final):", mainNftAmountFinal);
        }
        
        // === ANALYSIS ===
        console.log("");
        console.log("=== ANALYSIS ===");
        console.log("Original price:", pricePerToken);
        console.log("Price after compound:", pricePerTokenAfterCompound);
        console.log("Final price:", pricePerTokenFinal);
        
        uint256 expectedLytFromDeposit = (depositAmount * 1e18) / pricePerTokenAfterCompound;
        console.log("Expected LYT from deposit:", expectedLytFromDeposit);
        console.log("Actual LYT received:", lytReceived);
        
        bool priceIncreased = pricePerTokenAfterCompound > pricePerToken;
        bool depositWorksWithNewPrice = lytReceived <= expectedLytFromDeposit * 1005 / 1000 && 
                                       lytReceived >= expectedLytFromDeposit * 995 / 1000;
        
        console.log("");
        console.log("=== RESULTS ===");
        console.log("Manual compound increased price:", priceIncreased);
        console.log("Deposit works with new price:", depositWorksWithNewPrice);
        
        if (priceIncreased) {
            console.log("SUCCESS: Manual compound increases LYT value!");
            console.log("LYT holders benefit from compounded rewards!");
        } else {
            console.log("NOTE: Price did not increase - this might be expected behavior");
        }
        
        if (depositWorksWithNewPrice) {
            console.log("SUCCESS: Deposits work correctly with updated price!");
        } else {
            console.log("ERROR: Deposit pricing issue after compound");
        }
    }
}