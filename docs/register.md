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

**Provider note:** `register()` with type `0` reverts with `IdentityNotRegistered()` unless the signing wallet is a registered FSP identity. Connect from your identity wallet, not your delegation or signing wallet. See [Errors](./errors.md) for details.

The contract treats every type identically except Provider. Provider-status verification (FSP registry membership, reward eligibility) happens off-chain — registering as type `0` doesn't auto-grant rewards or special access.

## 2. Host your participant.json

Put a JSON file with at least `name` and `url` at a public URL. Schema and hosting options: [Your participant.json](./participant-json.md).

```json
{
  "name": "Your Project",
  "url": "https://your-site.com"
}
```

## 3. Send the transaction

### Via the portal

[registerc2.proofs.africa/new](https://registerc2.proofs.africa/new) — connect, fill, sign.

### Via CLI

Coston2 example:

```bash
cast send 0xF9fDB222FCa62B50a0d94C1F31650a4034b60B12 \
  "register(uint8,string)" 0 "https://yoursite.com/participant.json" \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

Replace contract address, RPC, type, and infoURI for your network and project. `msg.sender` becomes your on-chain identity.

## Verify

```bash
cast call 0xF9fDB222FCa62B50a0d94C1F31650a4034b60B12 \
  "getParticipant(address)((address,uint8,string,bool,uint256,uint256,uint256))" \
  $YOUR_ADDRESS \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc
```

Or visit `https://registerc2.proofs.africa/<your-address>` for the rendered profile.

## Cost

| Action | Gas |
|---|---|
| First register | ~199k (≈ $0.01 on Flare mainnet) |
| Update | 40–80k |
| Deactivate | 40k |
| Read | free |
