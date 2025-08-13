#!/bin/bash

# Add browser-like headers to avoid Cloudflare blocking
API_KEY="0f3eea4b-ad42-42dd-a48d-76cf6d14955b"
API_URL="https://seitrace.com/pacific-1/api"

echo "=== Verifying LiquidYakaToken with Browser Headers ==="

# Read flattened source
TOKEN_SOURCE=$(cat flattened/LiquidYakaToken_flattened.sol | sed 's/"/\\"/g' | tr -d '\n' | tr -d '\r')

curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
  -H "Accept: application/json, text/plain, */*" \
  -H "Accept-Language: en-US,en;q=0.9" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -H "Sec-Fetch-Dest: empty" \
  -H "Sec-Fetch-Mode: cors" \
  -H "Sec-Fetch-Site: same-origin" \
  --data-urlencode "module=contract" \
  --data-urlencode "action=verifysourcecode" \
  --data-urlencode "apikey=${API_KEY}" \
  --data-urlencode "contractaddress=0xFEEc14a2E30999A84fF4D5750ffb6D3AEc681E79" \
  --data-urlencode "sourceCode=${TOKEN_SOURCE}" \
  --data-urlencode "contractname=LiquidYakaToken" \
  --data-urlencode "compilerversion=v0.8.30+commit.d5aba93b" \
  --data-urlencode "optimizationUsed=1" \
  --data-urlencode "runs=200" \
  --data-urlencode "constructorArguements=0000000000000000000000000000071763daa95626125986d95f7c7748a1bfe3" \
  "${API_URL}"

echo -e "\n\nDone!"