#!/usr/bin/env python3

import requests
import json

# Configuration
API_KEY = "0f3eea4b-ad42-42dd-a48d-76cf6d14955b"
API_URL = "https://seitrace.com/pacific-1/api"

def read_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def verify_contract(contract_address, source_code, contract_name, constructor_args):
    data = {
        'module': 'contract',
        'action': 'verifysourcecode',
        'apikey': API_KEY,
        'contractaddress': contract_address,
        'sourceCode': source_code,
        'contractname': contract_name,
        'compilerversion': 'v0.8.30+commit.d5aba93b',
        'optimizationUsed': '1',
        'runs': '200',
        'constructorArguements': constructor_args,
        'evmversion': 'paris'
    }
    
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
    }
    
    print(f"Verifying {contract_name} at {contract_address}...")
    
    try:
        response = requests.post(API_URL, data=data, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        return response.json() if response.headers.get('content-type', '').startswith('application/json') else response.text
    except Exception as e:
        print(f"Error: {e}")
        return None

def main():
    print("=== Sei Contract Verification via API ===\n")
    
    # Verify LiquidYakaToken
    print("1. Verifying LiquidYakaToken...")
    token_source = read_file('flattened/LiquidYakaToken_flattened.sol')
    token_result = verify_contract(
        contract_address='0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79',
        source_code=token_source,
        contract_name='LiquidYakaToken',
        constructor_args='0000000000000000000000000000071763daa95626125986d95f7c7748a1bfe3'
    )
    
    print(f"Token verification result: {token_result}\n")
    
    # Verify LiquidYakaVault
    print("2. Verifying LiquidYakaVault...")
    vault_source = read_file('flattened/LiquidYakaVault_flattened.sol')
    vault_result = verify_contract(
        contract_address='0x2fB0DA76902E13810460A80045C3FC5170776543',
        source_code=vault_source,
        contract_name='LiquidYakaVault',
        constructor_args='00000000000000000000000051121bcae92e302f19d06c193c95e1f7b81a444b00000000000000000000000086a247ef0fc244565bcab93936e867407ac8158000000000000000000000000036068f15f257896e03fb7edba3d18898d0ade809000000000000000000000000feec14a2e30999a84ff4d5750ffb6d3aec681e79'
    )
    
    print(f"Vault verification result: {vault_result}\n")
    
    print("=== Verification Complete ===")

if __name__ == "__main__":
    main()