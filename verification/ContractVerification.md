# Contract Verification Information

## Contract Addresses (Sei Network - Chain ID: 1329)

### LiquidYakaToken (LYT)
- **Address**: `0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79`
- **Flattened Source**: `flattened/LiquidYakaToken_flattened.sol`
- **Constructor Args**: `0x0000071763DaA95626125986d95F7C7748A1BfE3` (owner)

### LiquidYakaVault 
- **Address**: `0x2fB0DA76902E13810460A80045C3FC5170776543`
- **Flattened Source**: `flattened/LiquidYakaVault_flattened.sol`
- **Constructor Args**: 
  - YAKA Token: `0x51121BCAE92E302f19D06C193C95E1f7b81a444b`
  - veYAKA (VotingEscrow): `0x86a247Ef0Fc244565BCab93936E867407ac81580`
  - VoterV3: `0x36068f15f257896E03fb7EdbA3D18898d0ade809`
  - LiquidToken: `0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79`

## Compilation Settings

```json
{
  "language": "Solidity",
  "sources": {
    "src/LiquidYakaToken.sol": {
      "keccak256": "...",
      "urls": ["..."]
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": ["*"]
      }
    },
    "viaIR": true,
    "evmVersion": "paris"
  }
}
```

## Verification Commands

### Using Foundry
```bash
# Verify LiquidYakaToken
forge verify-contract \
  --chain-id 1329 \
  --constructor-args 0x0000000000000000000000000000071763daa95626125986d95f7c7748a1bfe3 \
  --compiler-version 0.8.30 \
  0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79 \
  flattened/LiquidYakaToken_flattened.sol:LiquidYakaToken

# Verify LiquidYakaVault  
forge verify-contract \
  --chain-id 1329 \
  --constructor-args $(cast abi-encode "constructor(address,address,address,address)" 0x51121BCAE92E302f19D06C193C95E1f7b81a444b 0x86a247Ef0Fc244565BCab93936E867407ac81580 0x36068f15f257896E03fb7EdbA3D18898d0ade809 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79) \
  --compiler-version 0.8.30 \
  0x2fB0DA76902E13810460A80045C3FC5170776543 \
  flattened/LiquidYakaVault_flattened.sol:LiquidYakaVault
```

## Manual Verification Steps

1. **Go to Sei Block Explorer**: https://seitrace.com/
2. **Navigate to contract verification section**
3. **Upload flattened source files**
4. **Set compiler version**: 0.8.30
5. **Enable optimization**: 200 runs
6. **Set constructor arguments** as shown above

## Contract Features

### LiquidYakaToken Features:
- ERC20 with extensions (ERC1363, ERC20Burnable, ERC20Permit)
- Vault authorization system
- Ownable for access control
- Total supply managed by authorized vaults

### LiquidYakaVault Features:
- Liquid staking for YAKA tokens
- veNFT management with auto-consolidation
- Manual compound functionality
- Withdrawal via NFT splitting
- Voting and reward claiming
- Price calculation based on locked YAKA
- Emergency functions and migration support

## Current State
- **Total LYT Supply**: 9.6 LYT
- **Total Locked YAKA**: 12 YAKA  
- **Current Price**: 1.25 YAKA per LYT
- **Main NFT**: #2425 with 12 YAKA locked
- **Lock Duration**: 2 years (maximum voting power)

## Key Contract Interactions Tested:
✅ YAKA deposits → LYT minting
✅ LYT withdrawals → veNFT splitting
✅ NFT deposits → LYT minting with consolidation
✅ Manual compound → Price increase
✅ Voting functionality
✅ Emergency controls