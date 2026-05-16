#!/bin/sh
# Phase 5a — Provider walk (register + on-chain verify) for the 5 Songbird
# staging identities. Real registered identity -> real FlareIdentityAdapter
# gate -> real ParticipantRegister.register(Provider). This is the R1
# de-risker for the Flare go-call: proves the corrected EntityManager gate
# ADMITS a real registered identity and (negative static probe) REJECTS a
# non-identity with IdentityNotRegistered(). No mocks. Net-zero is restored
# by the finalize script. Secrets never echoed.
set -eu

PR="0x7BC5d4162AE3387AcaD5C8Ce931afB04Dfb6e402"        # Songbird ParticipantRegister (corrected)
ADAPTER="0x4740ABbce1EE16075fD407CA0b44974545c5B1A4"
FUNDER="0xF6ca6bAEf426DfD38Aab69Fbad6CA3AfE4b6e29B"    # known non-identity (gate must reject)
KEYFILE="/work/apregister-web/docs/testing/songbird-identities.local.md"
BASEURI="https://apregister-web-songbird-stage.netlify.app/test/songbird"
N="${N:-5}"
. /work/apregister/.env
RPC="${SONGBIRD_RPC:-https://songbird-api.flare.network/ext/C/rpc}"
eval "$(grep -E '^(ID|SP)[0-9]+_(ADDR|PK)=0x' "$KEYFILE")"

echo "=== negative probe: non-identity must revert IdentityNotRegistered ==="
if cast call "$PR" 'register(uint8,string)' 0 "x" --from "$FUNDER" --rpc-url "$RPC" >/dev/null 2>&1; then
  echo "FATAL: non-identity register(Provider) did NOT revert — gate is OPEN"; exit 1
else
  echo "OK: register(Provider) from non-identity $FUNDER reverts (gate closed)"
fi

echo "baseline participantCount=$(cast call "$PR" 'participantCount()(uint256)' --rpc-url "$RPC") activeCount=$(cast call "$PR" 'activeCount()(uint256)' --rpc-url "$RPC")"

echo "=== Provider walk: register $N real identities ==="
i=1
while [ "$i" -le "$N" ]; do
  eval "ida=\$ID${i}_ADDR idk=\$ID${i}_PK"
  uri="$BASEURI/identity-$i.json"
  if [ "$(cast call "$PR" 'isRegistered(address)(bool)' "$ida" --rpc-url "$RPC")" = "true" ]; then
    echo "[$i] $ida already a participant — skip register"
  else
    th="$(cast send --private-key "$idk" --rpc-url "$RPC" "$PR" 'register(uint8,string)' 0 "$uri" --json | sed -n 's/.*"transactionHash":"\([^"]*\)".*/\1/p')"
    echo "[$i] $ida register(Provider) $th"
  fi
  # on-chain assertions
  p="$(cast call "$PR" 'getParticipant(address)((address,uint8,string,bool,uint256,uint256,uint256))' "$ida" --rpc-url "$RPC")"
  reg="$(cast call "$PR" 'isRegistered(address)(bool)' "$ida" --rpc-url "$RPC")"
  gate="$(cast call "$ADAPTER" 'isRegisteredIdentity(address)(bool)' "$ida" --rpc-url "$RPC")"
  echo "    isRegistered=$reg adapterGate=$gate participant=$p"
  case "$p" in
    *", 0, "*", true, "*) : ;;   # type 0 (Provider), active true
    *) echo "FATAL: identity $i not active Provider on-chain"; exit 2 ;;
  esac
  i=$((i+1))
done
echo "post-register participantCount=$(cast call "$PR" 'participantCount()(uint256)' --rpc-url "$RPC") activeCount=$(cast call "$PR" 'activeCount()(uint256)' --rpc-url "$RPC")"
echo "=== all $N registered as active Providers; profiles are LIVE for host render-check ==="
