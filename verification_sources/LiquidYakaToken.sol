// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LiquidYakaToken
 * @dev Liquid YAKA token that represents staked YAKA in the vault
 * Features:
 * - ERC20 with burn functionality
 * - ERC1363 for enhanced token interactions
 * - ERC20Permit for gasless approvals
 * - Vault authorization system for minting/burning
 */
contract LiquidYakaToken is ERC20, ERC20Burnable, ERC20Permit, ERC1363, Ownable {
    
    // Mapping to track authorized vaults that can mint/burn tokens
    mapping(address => bool) public authorizedVaults;
    
    event VaultAuthorized(address indexed vault, bool authorized);
    
    modifier onlyAuthorizedVault() {
        require(authorizedVaults[msg.sender], "Not authorized vault");
        _;
    }
    
    constructor(address initialOwner) 
        ERC20("Liquid YAKA", "LYT") 
        ERC20Permit("Liquid YAKA")
        Ownable(initialOwner)
    {}
    
    /**
     * @dev Set authorization status for a vault
     * @param vault Address of the vault
     * @param authorized Whether the vault is authorized
     */
    function setVaultAuthorization(address vault, bool authorized) external onlyOwner {
        authorizedVaults[vault] = authorized;
        emit VaultAuthorized(vault, authorized);
    }
    
    /**
     * @dev Mint tokens - only callable by authorized vaults
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyAuthorizedVault {
        _mint(to, amount);
    }
    
    /**
     * @dev Burn tokens from an address - only callable by authorized vaults
     * @param from Address to burn tokens from
     * @param amount Amount to burn
     */
    function burnFrom(address from, uint256 amount) public override onlyAuthorizedVault {
        super.burnFrom(from, amount);
    }
}