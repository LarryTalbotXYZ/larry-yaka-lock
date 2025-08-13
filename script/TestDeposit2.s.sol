// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaVault.sol";
import "../src/LiquidYakaToken.sol";
import "../src/veYakainterface/IVotingEscrow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestDeposit2 is Script {
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
        
        console.log("=== Test Deposit to New Vault ===");
        console.log("User:", deployer);
        console.log("New Vault:", NEW_VAULT);
        console.log("");
        
        // Check initial state
        uint256 userYakaBalance = yaka.balanceOf(deployer);
        uint256 userLytBalance = lyt.balanceOf(deployer);
        
        console.log("User's YAKA balance:", userYakaBalance);
        console.log("User's LYT balance before:", userLytBalance);
        
        (
            uint256 totalLiquidSupply,
            uint256 totalLockedYaka,
            uint256 totalVotingPower,
            uint256 pricePerToken,
            uint256 mainNftId
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State Before Deposit ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Price per Token:", pricePerToken);
        console.log("Main NFT ID:", mainNftId);
        console.log("");
        
        // Test deposit amount
        uint256 depositAmount = 3 ether; // 3 YAKA
        console.log("Attempting to deposit:", depositAmount, "YAKA");
        
        if (userYakaBalance < depositAmount) {
            console.log("ERROR: Insufficient YAKA balance for deposit");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve vault to spend YAKA tokens
        console.log("Approving vault to spend YAKA tokens...");
        yaka.approve(NEW_VAULT, depositAmount);
        
        // Perform deposit
        console.log("Executing deposit...");
        vault.deposit(depositAmount);
        console.log("Deposit transaction completed!");
        
        vm.stopBroadcast();
        
        // Check final state
        uint256 userYakaBalanceAfter = yaka.balanceOf(deployer);
        uint256 userLytBalanceAfter = lyt.balanceOf(deployer);
        uint256 lytReceived = userLytBalanceAfter - userLytBalance;
        
        console.log("");
        console.log("=== Deposit Results ===");
        console.log("User's YAKA balance after:", userYakaBalanceAfter);
        console.log("YAKA deposited:", userYakaBalance - userYakaBalanceAfter);
        console.log("User's LYT balance after:", userLytBalanceAfter);
        console.log("LYT received:", lytReceived);
        
        // Check vault state after
        (
            uint256 totalLiquidSupplyAfter,
            uint256 totalLockedYakaAfter,
            uint256 totalVotingPowerAfter,
            uint256 pricePerTokenAfter,
            uint256 mainNftIdAfter
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State After Deposit ---");
        console.log("Total Liquid Supply:", totalLiquidSupplyAfter);
        console.log("Total Locked YAKA:", totalLockedYakaAfter);
        console.log("Price per Token:", pricePerTokenAfter);
        console.log("Main NFT ID:", mainNftIdAfter);
        
        // Check main NFT locked amount
        if (mainNftIdAfter > 0) {
            IVotingEscrow.LockedBalance memory locked = veYaka.locked(mainNftIdAfter);
            uint256 mainNftAmount = uint256(int256(locked.amount));
            console.log("Main NFT locked amount:", mainNftAmount);
            console.log("Main NFT lock end:", locked.end);
        }
        
        // Verify results
        uint256 expectedLyt = (depositAmount * 1e18) / pricePerToken;
        bool depositSuccess = (
            userYakaBalanceAfter == userYakaBalance - depositAmount &&
            lytReceived >= expectedLyt * 995 / 1000 && // Allow 0.5% tolerance
            lytReceived <= expectedLyt * 1005 / 1000 &&
            totalLockedYakaAfter == totalLockedYaka + depositAmount
        );
        
        console.log("");
        console.log("=== Test Results ===");
        console.log("Deposit test passed:", depositSuccess);
        console.log("Expected LYT received ~", expectedLyt);
        console.log("Actual LYT received:", lytReceived);
        
        if (!depositSuccess) {
            console.log("ERROR: Deposit test failed");
            console.log("Expected YAKA deposited:", depositAmount, "Got:", userYakaBalance - userYakaBalanceAfter);
            console.log("Expected vault YAKA increase:", depositAmount, "Got:", totalLockedYakaAfter - totalLockedYaka);
        } else {
            console.log("SUCCESS: Deposit to new vault works correctly!");
        }
    }
}