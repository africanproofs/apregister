#!/bin/sh
# Phase 5c — net-zero: deactivate all N staging Provider registrations
# (project convention: only msg.sender can unregister; record retained,
# active=false). Verifies activeCount returns to 0. Secrets never echoed.
set -eu
PR="0x7BC5d4162AE3387AcaD5C8Ce931afB04Dfb6e402"
KEYFILE="/work/apregister-web/docs/testing/songbird-identities.local.md"
N="${N:-5}"
. /work/apregister/.env
RPC="${SONGBIRD_RPC:-https://songbird-api.flare.network/ext/C/rpc}"
eval "$(grep -E '^ID[0-9]+_(ADDR|PK)=0x' "$KEYFILE")"

echo "=== net-zero: deactivate $N ==="
i=1
while [ "$i" -le "$N" ]; do
  eval "ida=\$ID${i}_ADDR idk=\$ID${i}_PK"
  act="$(cast call "$PR" 'getParticipant(address)((address,uint8,string,bool,uint256,uint256,uint256))' "$ida" --rpc-url "$RPC" | awk -F', ' '{print $4}')"
  if [ "$act" = "true" ]; then
    th="$(cast send --private-key "$idk" --rpc-url "$RPC" "$PR" 'unregister()' --json | sed -n 's/.*"transactionHash":"\([^"]*\)".*/\1/p')"
    echo "[$i] $ida unregister() $th"
  else
    echo "[$i] $ida already inactive — skip"
  fi
  i=$((i+1))
done
pc="$(cast call "$PR" 'participantCount()(uint256)' --rpc-url "$RPC")"
ac="$(cast call "$PR" 'activeCount()(uint256)' --rpc-url "$RPC")"
echo "final participantCount=$pc activeCount=$ac"
[ "$ac" = "0" ] || { echo "FATAL: activeCount=$ac (expected 0 net-zero)"; exit 2; }
echo "=== net-zero restored: $pc records retained, 0 active ==="
