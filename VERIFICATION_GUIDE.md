# Contract Verification Guide for Sei Network (Seitrace)

This guide provides step-by-step instructions for verifying smart contracts on Sei Network using Seitrace (Blockscout).

## Prerequisites

- Deployed contract address
- Source code and compiler settings
- Constructor parameters
- API key from Seitrace
- Forge/Foundry installed

## API Endpoints

Seitrace provides different API endpoints for each network:

- **Pacific-1 (Mainnet):** `https://seitrace.com/pacific-1/api`
- **Atlantic-2 (Testnet):** `https://seitrace.com/atlantic-2/api`
- **Arctic-1 (Devnet):** `https://seitrace.com/arctic-1/api`

## Getting API Key

1. Visit [Seitrace](https://seitrace.com)
2. Navigate to your account settings
3. Generate or copy your API key
4. Format: `0f3eea4b-ad42-42dd-a48d-76cf6d14955b` (example)

## Verification Methods

### Method 1: Using Forge (Recommended)

```bash
forge verify-contract [CONTRACT_ADDRESS] \
  [CONTRACT_PATH]:[CONTRACT_NAME] \
  --verifier blockscout \
  --verifier-url https://seitrace.com/pacific-1/api \
  --etherscan-api-key [YOUR_API_KEY] \
  --constructor-args [CONSTRUCTOR_ARGS_HEX] \
  --rpc-url https://evm-rpc.sei-apis.com
```

#### Example for LiquidYakaVault:

```bash
forge verify-contract 0x25184f590aaf61d41677ea3cd6df009deaebbb13 \
  src/LiquidYakaVault.sol:LiquidYakaVault \
  --verifier blockscout \
  --verifier-url https://seitrace.com/pacific-1/api \
  --etherscan-api-key 0f3eea4b-ad42-42dd-a48d-76cf6d14955b \
  --constructor-args 0x00000000000000000000000051121bcae92e302f19d06c193c95e1f7b81a444b00000000000000000000000086a247ef0fc244565bcab93936e867407ac8158000000000000000000000000036068f15f257896e03fb7edba3d18898d0ade809000000000000000000000000ac76b04f87ccbfb4ba01f76f34b9f1b770839ebe000000000000000000000000feec14a2e30999a84ff4d5750ffb6d3aec681e790000000000000000000000003af1789536d88d3dcf2e200ab0ff1b48f8012e41 \
  --rpc-url https://evm-rpc.sei-apis.com
```

### Method 2: Direct API Call

```bash
curl -X POST "https://seitrace.com/pacific-1/api?module=contract&action=verifysourcecode" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: [YOUR_API_KEY]" \
  -d '{
    "contractaddress": "[CONTRACT_ADDRESS]",
    "sourceCode": "[FLATTENED_SOURCE_CODE]",
    "contractname": "[CONTRACT_NAME]",
    "compilerversion": "[COMPILER_VERSION]",
    "constructorArguements": "[CONSTRUCTOR_ARGS_HEX]"
  }'
```

## Getting Constructor Arguments

### From Deployment Broadcast:

1. Navigate to `broadcast/[ScriptName].s.sol/[ChainId]/`
2. Open the latest `run-*.json` file
3. Find the CREATE transaction for your contract
4. Copy the `arguments` array values
5. Encode them using cast:

```bash
cast abi-encode "constructor(address,address,address,address,address,address)" \
  0x51121BCAE92E302f19D06C193C95E1f7b81a444b \
  0x86a247Ef0Fc244565BCab93936E867407ac81580 \
  0x36068f15f257896E03fb7EdbA3D18898d0ade809 \
  0xaC76B04F87ccbfb4ba01f76F34B9f1B770839ebe \
  0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79 \
  0x3af1789536d88D3dCf2e200aB0fF1B48F8012E41
```

### From Contract Creation Transaction:

1. Find the contract creation transaction hash
2. View transaction details on Seitrace
3. Extract constructor arguments from input data (after contract bytecode)

## Common Issues and Solutions

### Issue 1: "Page Not Found" Error
- **Cause:** Wrong API endpoint
- **Solution:** Use correct endpoint format: `https://seitrace.com/[network]/api`

### Issue 2: "Module and Action Required"
- **Cause:** Missing URL parameters
- **Solution:** Add `?module=contract&action=verifysourcecode` to URL

### Issue 3: Constructor Arguments Mismatch
- **Cause:** Incorrect argument encoding
- **Solution:** Double-check argument order and types, use `cast abi-encode`

### Issue 4: Compiler Version Mismatch
- **Cause:** Wrong compiler version specified
- **Solution:** Check `foundry.toml` for exact version, format: `v0.8.30+commit.5a9fecd4`

## Verification Checklist

- [ ] Contract is deployed and confirmed
- [ ] API key is valid and active
- [ ] Constructor arguments are correctly encoded
- [ ] Compiler version matches deployment
- [ ] Source code is accessible (no missing imports)
- [ ] Optimization settings match (if used)
- [ ] Network endpoint is correct

## Successful Verification Response

```json
{
  "status": "OK",
  "message": "Contract verification submitted",
  "result": {
    "guid": "[VERIFICATION_GUID]",
    "url": "https://seitrace.com/address/[CONTRACT_ADDRESS]"
  }
}
```

## Verification Status Check

After submission, verification can take 1-5 minutes. Check status at:
`https://seitrace.com/address/[CONTRACT_ADDRESS]`

## Example Contract Info

**LiquidYakaVault Deployment:**
- **Address:** `0x25184f590aaf61d41677ea3cd6df009deaebbb13`
- **Network:** Sei Pacific-1
- **Compiler:** v0.8.30+commit.5a9fecd4
- **Optimization:** Enabled (200 runs)
- **Verification GUID:** `25184f590aaf61d41677ea3cd6df009deaebbb1368a14d7c`

## Troubleshooting Tips

1. **Always use the full API endpoint** including `/api`
2. **Verify constructor arguments** match exactly with deployment
3. **Check compiler version** in foundry.toml
4. **Ensure source code has no missing dependencies**
5. **Use blockscout verifier** for Seitrace, not etherscan
6. **Wait for verification to complete** before retrying

## Additional Resources

- [Seitrace Documentation](https://docs.seitrace.com)
- [Foundry Verification Docs](https://book.getfoundry.sh/reference/forge/forge-verify-contract)
- [Blockscout API Docs](https://docs.blockscout.com/for-users/api)