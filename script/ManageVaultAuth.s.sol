// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiquidYakaToken.sol";

contract ManageVaultAuth is Script {
    // Contract addresses
    address constant LIQUID_TOKEN = 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79;
    
    // Vault addresses
    address constant OLD_VAULT_1 = 0x6d5FE504b236738D160B56A493F8c369fd5eB433;
    address constant OLD_VAULT_2 = 0xb45243027fdC5c52862b3f9d81b296420491b4CE;
    address constant OLD_VAULT_3 = 0x2fB0DA76902E13810460A80045C3FC5170776543; // Previous vault
    address constant OLD_VAULT_4 = 0x9Ff8a56c9E393D0cC4093b15B70EcC67CfC577c6; // Fixed vault
    address constant OLD_VAULT_5 = 0x12386fE7bd1b001a10635f5288dAde955788BD84; // Max voting power vault (old)
    address constant ULTIMATE_VAULT = 0x9833F68daB132E432ac8Bca160f60b77af36A306; // Ultimate vault with max voting power
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        LiquidYakaToken lyt = LiquidYakaToken(LIQUID_TOKEN);
        
        console.log("=== Vault Authorization Management ===");
        console.log("Owner:", deployer);
        console.log("LiquidYakaToken:", LIQUID_TOKEN);
        console.log("");
        
        // Check current authorizations
        console.log("--- Current Authorization Status ---");
        bool oldVault1Auth = lyt.authorizedVaults(OLD_VAULT_1);
        bool oldVault2Auth = lyt.authorizedVaults(OLD_VAULT_2);
        bool oldVault3Auth = lyt.authorizedVaults(OLD_VAULT_3);
        bool oldVault4Auth = lyt.authorizedVaults(OLD_VAULT_4);
        bool oldVault5Auth = lyt.authorizedVaults(OLD_VAULT_5);
        bool ultimateVaultAuth = lyt.authorizedVaults(ULTIMATE_VAULT);
        
        console.log("Old Vault 1 (0x6d5F...33): ", oldVault1Auth);
        console.log("Old Vault 2 (0xb452...CE): ", oldVault2Auth);
        console.log("Old Vault 3 (0x2fB0...43): ", oldVault3Auth);
        console.log("Old Vault 4 (0x9Ff8...c6): ", oldVault4Auth);
        console.log("Old Vault 5 (0x1238...84): ", oldVault5Auth);
        console.log("Ultimate Vault (0x9833...06):", ultimateVaultAuth);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Ensure old vaults are deauthorized
        if (oldVault1Auth) {
            console.log("Deauthorizing old vault 1...");
            lyt.setVaultAuthorization(OLD_VAULT_1, false);
            console.log("Old vault 1 deauthorized");
        } else {
            console.log("Old vault 1 already deauthorized");
        }
        
        if (oldVault2Auth) {
            console.log("Deauthorizing old vault 2...");
            lyt.setVaultAuthorization(OLD_VAULT_2, false);
            console.log("Old vault 2 deauthorized");
        } else {
            console.log("Old vault 2 already deauthorized");
        }
        
        if (oldVault3Auth) {
            console.log("Deauthorizing old vault 3...");
            lyt.setVaultAuthorization(OLD_VAULT_3, false);
            console.log("Old vault 3 deauthorized");
        } else {
            console.log("Old vault 3 already deauthorized");
        }
        
        if (oldVault4Auth) {
            console.log("Deauthorizing old vault 4...");
            lyt.setVaultAuthorization(OLD_VAULT_4, false);
            console.log("Old vault 4 deauthorized");
        } else {
            console.log("Old vault 4 already deauthorized");
        }
        
        if (oldVault5Auth) {
            console.log("Deauthorizing old vault 5...");
            lyt.setVaultAuthorization(OLD_VAULT_5, false);
            console.log("Old vault 5 deauthorized");
        } else {
            console.log("Old vault 5 already deauthorized");
        }
        
        // Ensure ultimate vault is authorized
        if (!ultimateVaultAuth) {
            console.log("Authorizing ultimate vault...");
            lyt.setVaultAuthorization(ULTIMATE_VAULT, true);
            console.log("Ultimate vault authorized");
        } else {
            console.log("Ultimate vault already authorized");
        }
        
        vm.stopBroadcast();
        
        // Check final status
        console.log("");
        console.log("--- Final Authorization Status ---");
        bool oldVault1AuthFinal = lyt.authorizedVaults(OLD_VAULT_1);
        bool oldVault2AuthFinal = lyt.authorizedVaults(OLD_VAULT_2);
        bool oldVault3AuthFinal = lyt.authorizedVaults(OLD_VAULT_3);
        bool oldVault4AuthFinal = lyt.authorizedVaults(OLD_VAULT_4);
        bool oldVault5AuthFinal = lyt.authorizedVaults(OLD_VAULT_5);
        bool ultimateVaultAuthFinal = lyt.authorizedVaults(ULTIMATE_VAULT);
        
        console.log("Old Vault 1 (0x6d5F...33): ", oldVault1AuthFinal);
        console.log("Old Vault 2 (0xb452...CE): ", oldVault2AuthFinal);
        console.log("Old Vault 3 (0x2fB0...43): ", oldVault3AuthFinal);
        console.log("Old Vault 4 (0x9Ff8...c6): ", oldVault4AuthFinal);
        console.log("Old Vault 5 (0x1238...84): ", oldVault5AuthFinal);
        console.log("Ultimate Vault (0x9833...06):", ultimateVaultAuthFinal);
        
        // Verification
        bool correctSetup = (
            !oldVault1AuthFinal && 
            !oldVault2AuthFinal && 
            !oldVault3AuthFinal &&
            !oldVault4AuthFinal &&
            !oldVault5AuthFinal &&
            ultimateVaultAuthFinal
        );
        
        console.log("");
        console.log("=== Security Check ===");
        console.log("Only ultimate vault authorized:", correctSetup);
        
        if (correctSetup) {
            console.log("SUCCESS: Vault authorizations are properly configured!");
            console.log("Only the ultimate vault can mint/burn LYT tokens");
        } else {
            console.log("WARNING: Authorization setup needs attention!");
            if (oldVault1AuthFinal) console.log("- Old vault 1 still authorized");
            if (oldVault2AuthFinal) console.log("- Old vault 2 still authorized");
            if (oldVault3AuthFinal) console.log("- Old vault 3 still authorized");
            if (oldVault4AuthFinal) console.log("- Old vault 4 still authorized");
            if (oldVault5AuthFinal) console.log("- Old vault 5 still authorized");
            if (!ultimateVaultAuthFinal) console.log("- Ultimate vault not authorized");
        }
    }
}