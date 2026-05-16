#!/bin/sh
# Phase 2 — register N minimal-real FSP identities on Songbird (chain 19).
#
# "Register the identity" on the real EntityManager == one
# proposeSigningPolicyAddress (from identity) + one
# confirmSigningPolicyAddressRegistration (from a distinct throwaway
# signing-policy key). That single pair is what makes an address a
# registered entity (echo-on-miss defeated) — exactly what makes
# 0xcf3A… registered. Nothing else: no submit / submit-sig /
# delegation / sortition / node / vote power. (apregister-web ADR-0006.)
#
# Runs INSIDE one ghcr.io/foundry-rs/foundry container (cast + sh).
# Idempotent/resumable: keys persist in a gitignored chmod-600 file;
# already-registered identities are detected on-chain and skipped.
# Secrets (funder key, generated keys) are NEVER echoed — only addresses,
# tx hashes, and registration booleans go to stdout.
set -eu

N="${N:-5}"
EM="0x46C417D0760198E94fee455CE0e223262a3D0049"          # Songbird EntityManager
ADAPTER="0x4740ABbce1EE16075fD407CA0b44974545c5B1A4"     # corrected FlareIdentityAdapter
EXPECT_FUNDER="0xF6ca6bAEf426DfD38Aab69Fbad6CA3AfE4b6e29B"
KEYFILE="/work/apregister-web/docs/testing/songbird-identities.local.md"
FUND_WEI="10000000000000000"   # 0.01 SGB float per address (gas is ~2 wei; vast headroom)
FUND_FLOOR="2000000000000000"  # top up only if balance < 0.002 SGB

# .env (mounted) provides PRIVATE_KEY (funder) + SONGBIRD_RPC. Never printed.
. /work/apregister/.env
RPC="${SONGBIRD_RPC:-https://songbird-api.flare.network/ext/C/rpc}"

cid="$(cast chain-id --rpc-url "$RPC")"
[ "$cid" = "19" ] || { echo "FATAL: chain-id $cid != 19 (Songbird)"; exit 1; }
funder="$(cast wallet address --private-key "$PRIVATE_KEY")"
[ "$funder" = "$EXPECT_FUNDER" ] || { echo "FATAL: funder $funder != $EXPECT_FUNDER"; exit 1; }
echo "chain=19 funder=$funder gasPrice=$(cast gas-price --rpc-url "$RPC")wei"

# --- keys: reuse if present, else generate N identity + N signing-policy ---
if [ -f "$KEYFILE" ] && grep -q '^ID1_ADDR=' "$KEYFILE"; then
  echo "keyfile present — reusing $N identities"
else
  echo "generating $N identity + $N signing-policy keypairs"
  : > "$KEYFILE"; chmod 600 "$KEYFILE"
  {
    echo "# Songbird staging identities — Phase 2 (ADR-0006). GITIGNORED, chmod 600."
    echo "# DO NOT COMMIT. Identity = the registered FSP identity for the walks;"
    echo "# SP = throwaway key used once to send the confirm tx (no operated role)."
    echo '```env'
  } >> "$KEYFILE"
  i=1
  while [ "$i" -le "$N" ]; do
    idn="$(cast wallet new)"; ida="$(echo "$idn" | sed -n 's/.*Address: *//p')"; idk="$(echo "$idn" | sed -n 's/.*Private key: *//p')"
    spn="$(cast wallet new)"; spa="$(echo "$spn" | sed -n 's/.*Address: *//p')"; spk="$(echo "$spn" | sed -n 's/.*Private key: *//p')"
    {
      echo "ID${i}_ADDR=$ida"; echo "ID${i}_PK=$idk"
      echo "SP${i}_ADDR=$spa"; echo "SP${i}_PK=$spk"
    } >> "$KEYFILE"
    i=$((i+1))
  done
  echo '```' >> "$KEYFILE"
fi

# load assignments (ID*_ADDR/PK, SP*_ADDR/PK) from the env block
eval "$(grep -E '^(ID|SP)[0-9]+_(ADDR|PK)=0x' "$KEYFILE")"

fund_if_low() {  # $1=addr
  bal="$(cast balance "$1" --rpc-url "$RPC")"
  if [ "$(echo "$bal < $FUND_FLOOR" | bc 2>/dev/null || awk -v a="$bal" -v b="$FUND_FLOOR" 'BEGIN{print (a<b)}')" = "1" ]; then
    cast send --private-key "$PRIVATE_KEY" --rpc-url "$RPC" --value "$FUND_WEI" "$1" >/dev/null
    echo "    funded $1 (+0.01 SGB)"
  fi
}

echo "=== registering $N identities ==="
i=1
while [ "$i" -le "$N" ]; do
  eval "ida=\$ID${i}_ADDR idk=\$ID${i}_PK spa=\$SP${i}_ADDR spk=\$SP${i}_PK"
  cur="$(cast call "$EM" 'getVoterAddresses(address)((address,address,address))' "$ida" --rpc-url "$RPC")"
  # 3rd tuple element = signingPolicyAddress
  spnow="$(echo "$cur" | tr -d '()' | awk -F', *' '{print $3}')"
  if [ "$(echo "$spnow" | tr 'A-F' 'a-f')" != "$(echo "$ida" | tr 'A-F' 'a-f')" ] && \
     [ "$spnow" != "0x0000000000000000000000000000000000000000" ]; then
    echo "[$i] $ida already registered (sp=$spnow) — skip"
  else
    echo "[$i] $ida -> sp $spa"
    fund_if_low "$ida"; fund_if_low "$spa"
    th1="$(cast send --private-key "$idk" --rpc-url "$RPC" "$EM" 'proposeSigningPolicyAddress(address)' "$spa" --json | sed -n 's/.*"transactionHash":"\([^"]*\)".*/\1/p')"
    echo "    propose  $th1"
    th2="$(cast send --private-key "$spk" --rpc-url "$RPC" "$EM" 'confirmSigningPolicyAddressRegistration(address)' "$ida" --json | sed -n 's/.*"transactionHash":"\([^"]*\)".*/\1/p')"
    echo "    confirm  $th2"
  fi
  i=$((i+1))
done

echo "=== verification (adapter.isRegisteredIdentity) ==="
ok=0
i=1
while [ "$i" -le "$N" ]; do
  eval "ida=\$ID${i}_ADDR"
  r="$(cast call "$ADAPTER" 'isRegisteredIdentity(address)(bool)' "$ida" --rpc-url "$RPC")"
  echo "[$i] $ida isRegisteredIdentity=$r"
  [ "$r" = "true" ] && ok=$((ok+1))
  i=$((i+1))
done
echo "=== $ok/$N identities registered & gate-verified ==="
[ "$ok" = "$N" ] || exit 2
