// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC1363} from "@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidYakaToken is ERC20, ERC20Burnable, Ownable, ERC1363, ERC20Permit {
    mapping(address => bool) public authorizedVaults;
    
    event VaultAuthorized(address indexed vault, bool authorized);
    
    modifier onlyVault() {
        require(authorizedVaults[msg.sender], "Not authorized vault");
        _;
    }
    
    constructor(address initialOwner)
        ERC20("Liquid YAKA", "LYT")
        Ownable(initialOwner)
        ERC20Permit("Liquid YAKA")
    {
    }
    
    function setVaultAuthorization(address vault, bool authorized) external onlyOwner {
        authorizedVaults[vault] = authorized;
        emit VaultAuthorized(vault, authorized);
    }
    
    function mint(address to, uint256 amount) public onlyVault {
        _mint(to, amount);
    }
    
    function burnFrom(address from, uint256 amount) public override onlyVault {
        _burn(from, amount);
    }
}