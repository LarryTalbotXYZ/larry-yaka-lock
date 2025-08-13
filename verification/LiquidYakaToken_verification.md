# LiquidYakaToken Contract Verification

## Contract Details
- **Address**: `0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79`
- **Network**: Sei Network (Chain ID: 1329)
- **Compiler**: Solidity 0.8.27
- **API Key**: 0f3eea4b-ad42-42dd-a48d-76cf6d14955b

## Constructor Arguments
- **Owner**: `0x0000071763DaA95626125986d95F7C7748A1BfE3`

## Contract Source Code
The contract source is located at: `src/LiquidYakaToken.sol`

## Verification Instructions

Since automated verification failed, manual verification steps:

1. **Visit Sei Block Explorer**: https://seitrace.com/
2. **Navigate to**: Contract verification section
3. **Contract Address**: 0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79
4. **Upload source code from**: `src/LiquidYakaToken.sol`
5. **Include dependencies**:
   - OpenZeppelin ERC20 extensions
   - All imported contracts

## Compilation Settings
```json
{
  "optimizer": true,
  "optimizerRuns": 200,
  "viaIR": true,
  "solidity": "0.8.27"
}
```

## Contract ABI
The ABI can be generated using: `forge inspect LiquidYakaToken abi`