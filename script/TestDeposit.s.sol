// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaToken.sol";
import "../src/LiquidYakaVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestDeposit is Script {
    // Deployed contract addresses
    address constant YAKA = 0x51121BCAE92E302f19D06C193C95E1f7b81a444b;
    address constant LIQUID_TOKEN = 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79;
    address constant VAULT = 0xb45243027fdC5c52862b3f9d81b296420491b4CE;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        IERC20 yaka = IERC20(YAKA);
        LiquidYakaToken lyt = LiquidYakaToken(LIQUID_TOKEN);
        LiquidYakaVault vault = LiquidYakaVault(VAULT);
        
        console.log("=== Test Deposit: 1 YAKA ===");
        console.log("User:", deployer);
        console.log("");
        
        // Check initial balances
        uint256 yakaBalance = yaka.balanceOf(deployer);
        uint256 lytBalance = lyt.balanceOf(deployer);
        console.log("Initial YAKA balance:", yakaBalance);
        console.log("Initial LYT balance:", lytBalance);
        
        if (yakaBalance < 1e18) {
            console.log("ERROR: Insufficient YAKA balance. Need at least 1 YAKA");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Approve vault to spend YAKA
        console.log("Approving vault to spend YAKA...");
        yaka.approve(VAULT, 1e18);
        console.log("Approval successful");
        
        // Step 2: Check vault info before deposit
        (
            uint256 totalLiquidSupply,
            uint256 totalLockedYaka,
            uint256 totalVotingPower,
            uint256 pricePerToken,
            uint256 mainNftId
        ) = vault.getVaultInfo();
        
        console.log("--- Vault Info Before Deposit ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Total Voting Power:", totalVotingPower);
        console.log("Price per Token:", pricePerToken);
        console.log("Main NFT ID:", mainNftId);
        console.log("");
        
        // Step 3: Deposit 1 YAKA
        console.log("Depositing 1 YAKA...");
        vault.deposit(1e18);
        console.log("Deposit successful!");
        
        vm.stopBroadcast();
        
        // Step 4: Check balances after deposit
        uint256 yakaBalanceAfter = yaka.balanceOf(deployer);
        uint256 lytBalanceAfter = lyt.balanceOf(deployer);
        console.log("--- Balances After Deposit ---");
        console.log("YAKA balance:", yakaBalanceAfter);
        console.log("LYT balance:", lytBalanceAfter);
        console.log("LYT received:", lytBalanceAfter - lytBalance);
        
        // Step 5: Check vault info after deposit
        (
            totalLiquidSupply,
            totalLockedYaka,
            totalVotingPower,
            pricePerToken,
            mainNftId
        ) = vault.getVaultInfo();
        
        console.log("--- Vault Info After Deposit ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Total Voting Power:", totalVotingPower);
        console.log("Price per Token:", pricePerToken);
        console.log("Main NFT ID:", mainNftId);
        
        // Step 6: Check main NFT details
        if (mainNftId > 0) {
            (
                uint256 tokenId,
                uint256 lockedAmount,
                uint256 endTime,
                uint256 timeLeft,
                uint256 votingPower
            ) = vault.getMainNFTLockInfo();
            
            console.log("--- Main NFT Details ---");
            console.log("Token ID:", tokenId);
            console.log("Locked Amount:", lockedAmount);
            console.log("Lock End Time:", endTime);
            console.log("Time Left (seconds):", timeLeft);
            console.log("Voting Power:", votingPower);
            console.log("Time Left (days):", timeLeft / 86400);
        }
        
        console.log("");
        console.log("=== Test Deposit Complete! ===");
        console.log("Next: Try voting with the accumulated voting power");
    }
}