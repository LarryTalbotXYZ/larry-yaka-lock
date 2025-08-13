// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaVault.sol";

contract TestVote is Script {
    // Deployed contract addresses
    address constant VAULT = 0x9833F68daB132E432ac8Bca160f60b77af36A306;
    
    // Pool to vote on (100%)
    address constant TARGET_POOL = 0xef3a845A6da5e00599e097c8a0E062dcFF45DFfc;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        LiquidYakaVault vault = LiquidYakaVault(VAULT);
        
        console.log("=== Test Vote: 100% on Target Pool ===");
        console.log("Voter (vault owner):", deployer);
        console.log("Target pool:", TARGET_POOL);
        console.log("");
        
        // Check vault state before voting
        (
            uint256 totalLiquidSupply,
            uint256 totalLockedYaka,
            uint256 totalVotingPower,
            uint256 pricePerToken,
            uint256 mainNftId
        ) = vault.getVaultInfo();
        
        console.log("--- Vault State Before Vote ---");
        console.log("Total Liquid Supply:", totalLiquidSupply);
        console.log("Total Locked YAKA:", totalLockedYaka);
        console.log("Total Voting Power:", totalVotingPower);
        console.log("Main NFT ID:", mainNftId);
        
        if (mainNftId == 0) {
            console.log("ERROR: No main NFT found!");
            return;
        }
        
        if (totalVotingPower == 0) {
            console.log("ERROR: No voting power available!");
            return;
        }
        
        // Get detailed NFT info
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
        console.log("Voting Power:", votingPower);
        console.log("Time Left (days):", timeLeft / 86400);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Prepare vote parameters
        address[] memory pools = new address[](1);
        uint256[] memory weights = new uint256[](1);
        
        pools[0] = TARGET_POOL;
        weights[0] = 10000; // 100% (10000 basis points)
        
        console.log("Voting 100% (10000 basis points) on pool:", TARGET_POOL);
        
        // Execute vote
        try vault.vote(pools, weights) {
            console.log("Vote executed successfully!");
        } catch Error(string memory reason) {
            console.log("Vote failed:", reason);
            vm.stopBroadcast();
            return;
        }
        
        vm.stopBroadcast();
        
        // Check vote results
        (address[] memory lastPools, uint256[] memory lastWeights) = vault.getLastVote();
        
        console.log("--- Vote Results ---");
        console.log("Number of pools voted on:", lastPools.length);
        if (lastPools.length > 0) {
            console.log("Pool voted on:", lastPools[0]);
            console.log("Weight assigned:", lastWeights[0]);
            console.log("Percentage:", (lastWeights[0] * 100) / 10000, "%");
        }
        
        // Display voting power utilization
        console.log("--- Voting Power Utilization ---");
        console.log("Total voting power:", votingPower);
        console.log("Voting power used: 100% on", TARGET_POOL);
        
        console.log("");
        console.log("=== Vote Complete! ===");
        console.log("Next steps:");
        console.log("1. Wait for voting epoch to complete");
        console.log("2. Claim bribes/fees from the pool");
        console.log("3. Compound rewards or withdraw to treasury");
    }
}