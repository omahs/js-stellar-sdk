#!/bin/bash

# read .env file, but prefer explicitly set environment variables
IFS=$'\n'
for l in $(cat .env); do
    IFS='=' read -ra VARVAL <<< "$l"
    # If variable with such name already exists, preserves its value
    eval "export ${VARVAL[0]}=\${${VARVAL[0]}:-${VARVAL[1]}}"
done
unset IFS

# a good-enough implementation of __dirname from https://blog.daveeddy.com/2015/04/13/dirname-case-study-for-bash-and-node/
dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "###################### Initializing e2e tests ########################"

soroban="$dirname/../../target/bin/soroban"
if [[ -f "$soroban" ]]; then
  echo "Using soroban binary from ./target/bin"
else
  echo "Building pinned soroban binary"
  (cd "$dirname/../.." && cargo install_soroban)
fi

NETWORK_STATUS=$(curl -s -X POST "$SOROBAN_RPC_URL" -H "Content-Type: application/json" -d '{ "jsonrpc": "2.0", "id": 8675309, "method": "getHealth" }' | sed 's/.*"status":"\(.*\)".*/\1/')

echo Network
echo "  RPC:        $SOROBAN_RPC_URL"
echo "  Passphrase: \"$SOROBAN_NETWORK_PASSPHRASE\""
echo "  Status:     $NETWORK_STATUS"

if [[ "$NETWORK_STATUS" != "healthy" ]]; then
  echo "Network is not healthy (not running?), exiting"
  exit 1
fi

$soroban keys generate $SOROBAN_ACCOUNT
