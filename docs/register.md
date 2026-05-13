# Register

Three steps: pick a type, host your JSON, send the transaction.

## 1. Pick your participant type

| Value | Type | Examples |
|---|---|---|
| 0 | Provider | FTSO data providers, validators, FDC operators |
| 1 | DeFi | Lending, DEX, yield, staking |
| 2 | Wallet | Wallet applications |
| 3 | Tool | Explorers, analytics, dev tools |
| 4 | FAssetsAgent | FAssets minting agents |
| 5 | Exchange | CEX/DEX with Flare listings |
| 6 | App | Games, NFT projects, dApps |
| 7 | AgenticAI | Autonomous AI agents |

**Provider note:** `register()` with type `0` reverts with `IdentityNotRegistered()` unless the signing wallet is a registered FSP identity. The CLI examples below use type `2` (Wallet) so any address can copy-paste them; if you're an FSP, jump to [§ Provider registration (FSPs only)](#provider-registration-fsps-only) below.

The contract treats every type identically except Provider. Provider-status verification (FSP registry membership, reward eligibility) happens off-chain — registering as type `0` doesn't auto-grant rewards or special access.

## 2. Host your participant.json

Put a JSON-LD file with at least `@context`, `@type`, `name`, and `url` at a public URL. Two starter files ship in the repo — pick whichever fits:

- [`assets/participant.minimal.json`](https://github.com/africanproofs/apregister/blob/main/assets/participant.minimal.json) — smallest schema-valid document (the four required fields, ~200 bytes). Edit `name` and `url`, host, done.
- [`assets/participant.template.json`](https://github.com/africanproofs/apregister/blob/main/assets/participant.template.json) — full reference with logo, brand, social handles, location, services, nodes, and tools. Use as a starting template; trim fields you don't need.

Schema, hosting options, and CORS notes: [Your participant.json](./participant-json.md). The schema itself is at [`assets/participant.schema.json`](https://github.com/africanproofs/apregister/blob/main/assets/participant.schema.json) — JSON Schema Draft 2020-12; the `$id` resolves to the same canonical GitHub raw URL.

Minimum valid document, mirroring `participant.minimal.json`:

```json
{
  "@context": {
    "@vocab": "https://schema.org/",
    "flare": "https://proofs.africa/ns/participant#"
  },
  "@type": "Organization",
  "name": "Your Project",
  "url": "https://your-site.com"
}
```

## 3. Send the transaction

### Via the portal

[register.proofs.africa/new](https://register.proofs.africa/new) — connect, fill, sign.

### Via CLI

Flare mainnet (type `2` = Wallet; substitute your type from the table above):

```bash
cast send 0xd523159981a545dA5C53Ddbba327A5E6438A171C \
  "register(uint8,string)" 2 "https://yoursite.com/participant.json" \
  --rpc-url https://flare-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

Test on Coston2 testnet first (free C2FLR from the [faucet](https://faucet.flare.network/coston2)):

```bash
cast send 0x09f15b14D16BA645661c576348E4d4C201242bF2 \
  "register(uint8,string)" 2 "https://yoursite.com/participant.json" \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

`msg.sender` becomes your on-chain identity.

### Provider registration (FSPs only)

Type `0` is identity-gated on-chain. On Flare mainnet the adapter calls `VoterRegistry.isVoterRegistered(msg.sender, currentRewardEpochId)` (O(1) direct lookup — see [`src/FlareIdentityAdapter.sol`](../src/FlareIdentityAdapter.sol)). Connect from your FSP **identity wallet**, not your delegation / submit / signing key:

```bash
cast send 0xd523159981a545dA5C53Ddbba327A5E6438A171C \
  "register(uint8,string)" 0 "https://yoursite.com/participant.json" \
  --rpc-url https://flare-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

On Coston2, Provider is gated by an admin-allowlisted `MockIdentityRegistry` ([`src/test-support/MockIdentityRegistry.sol`](../src/test-support/MockIdentityRegistry.sol)) seeded with AP's HD-derived addresses only. The Coston2 faucet won't get you past the gate — test non-Provider types on Coston2, then register as Provider directly on Flare. Trying type `0` from an unallowlisted Coston2 address reverts with `IdentityNotRegistered()`.

## Verify

```bash
cast call 0xd523159981a545dA5C53Ddbba327A5E6438A171C \
  "getParticipant(address)((address,uint8,string,bool,uint256,uint256,uint256))" \
  $YOUR_ADDRESS \
  --rpc-url https://flare-api.flare.network/ext/C/rpc
```

Or visit `https://register.proofs.africa/<your-address>` for the rendered profile.

## Cost

| Action | Gas |
|---|---|
| First register | ~199k (≈ $0.01 on Flare mainnet) |
| Update | 40–80k |
| Deactivate | 40k |
| Read | free |
