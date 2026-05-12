# Register with `cast`

Power-user path: skip the portal, register directly from the command line with one `cast send`. Twenty seconds of work assuming you already have Foundry + a funded wallet.

## Step 1 — host your `participant.json`

The contract stores only a URL pointing at your JSON. You host the JSON. A starter is in this folder: [`participant.json`](./participant.json) — a `Wallet`-type (2) example. **Edit every field** before publishing.

Where to host:

- **GitHub Pages** — push the JSON to a `gh-pages` branch or a `/docs` folder on `main`; serves with permissive CORS by default. Recommended.
- **IPFS / Arweave** — content-addressed; no CORS issues. Slight UX friction for human readers.
- **Your own server** — works, but you MUST set the `Access-Control-Allow-Origin: *` header (or restrict appropriately). Default nginx / Caddy / Apache configs don't, and the AP portal will silently fail to fetch.

See [`../../docs/participant-json.md`](../../docs/participant-json.md) for hosting + CORS notes.

## Step 2 — pick a participant type

| Value | Type | Notes |
|---|---|---|
| 0 | Provider | Identity-gated on-chain; only FSP identity wallets can register. |
| 1 | DeFi | Open. |
| 2 | Wallet | Open. (This example.) |
| 3 | Tool | Open. |
| 4 | FAssetsAgent | Open. |
| 5 | Exchange | Open. |
| 6 | App | Open. |
| 7 | AgenticAI | Open. |

## Step 3 — send the transaction

**Flare mainnet:**

```bash
cast send 0xd523159981a545dA5C53Ddbba327A5E6438A171C \
  "register(uint8,string)" 2 "https://your-domain.example.com/participant.json" \
  --rpc-url https://flare-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

Replace the `2` with your chosen type, the URL with your hosted JSON, and `$PRIVATE_KEY` with the env var holding your registering wallet's key. Costs ~1.4 μFLR (well under $0.01).

**Test on Coston2 first** (free C2FLR from the [faucet](https://faucet.flare.network/coston2)):

```bash
cast send 0x09f15b14D16BA645661c576348E4d4C201242bF2 \
  "register(uint8,string)" 2 "https://your-domain.example.com/participant.json" \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

`msg.sender` becomes your on-chain identity.

## Step 4 — verify

```bash
cast call 0xd523159981a545dA5C53Ddbba327A5E6438A171C \
  "getParticipant(address)((address,uint8,string,bool,uint256,uint256,uint256))" \
  $YOUR_ADDRESS \
  --rpc-url https://flare-api.flare.network/ext/C/rpc
```

Or visit `https://register.proofs.africa/<your-address>` for a rendered profile page.

## Updates

Run `register(type, infoURI)` again with the same address. The contract upserts in place — same `registeredAt`, bumped `updatedAt`.

## Deactivate

```bash
cast send 0xd523159981a545dA5C53Ddbba327A5E6438A171C \
  "unregister()" \
  --rpc-url https://flare-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

You disappear from `getActiveParticipants()` and `getParticipantsByType()`. Your record stays in the index (append-only).
