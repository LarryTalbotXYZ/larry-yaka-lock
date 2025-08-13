#!/bin/bash

# Sei Verification API Script
API_KEY="0f3eea4b-ad42-42dd-a48d-76cf6d14955b"
API_URL="https://seitrace.com/pacific-1/api"

echo "=== Verifying LiquidYakaToken ==="

# Get the flattened source code
TOKEN_SOURCE=$(cat flattened/LiquidYakaToken_flattened.sol)

curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "module=contract" \
  -d "action=verifysourcecode" \
  -d "apikey=${API_KEY}" \
  -d "contractaddress=0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79" \
  -d "sourceCode=${TOKEN_SOURCE}" \
  -d "contractname=LiquidYakaToken" \
  -d "compilerversion=v0.8.30+commit.d5aba93b" \
  -d "optimizationUsed=1" \
  -d "runs=200" \
  -d "constructorArguements=0000000000000000000000000000071763daa95626125986d95f7c7748a1bfe3" \
  "${API_URL}"

echo -e "\n\n=== Verifying LiquidYakaVault ==="

# Get the flattened source code for vault
VAULT_SOURCE=$(cat flattened/LiquidYakaVault_flattened.sol)

curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "module=contract" \
  -d "action=verifysourcecode" \
  -d "apikey=${API_KEY}" \
  -d "contractaddress=0x2fB0DA76902E13810460A80045C3FC5170776543" \
  -d "sourceCode=${VAULT_SOURCE}" \
  -d "contractname=LiquidYakaVault" \
  -d "compilerversion=v0.8.30+commit.d5aba93b" \
  -d "optimizationUsed=1" \
  -d "runs=200" \
  -d "constructorArguements=00000000000000000000000051121bcae92e302f19d06c193c95e1f7b81a444b00000000000000000000000086a247ef0fc244565bcab93936e867407ac8158000000000000000000000000036068f15f257896e03fb7edba3d18898d0ade809000000000000000000000000feec14a2e30999a84ff4d5750ffb6d3aec681e79" \
  "${API_URL}"

echo -e "\n\nVerification requests submitted!"