# Register directly — no frontend

`ParticipantRegister` is a 170-line Solidity contract with no admin, no fees, and no portal dependency. If you already hold a wallet, can host a file, and have a few cents of FLR, you can register with one `cast send`. The [`register.proofs.africa`](https://register.proofs.africa) portal is a convenience layer on top — this doc is the bare-metal path for operators, scripters, and anyone who'd rather not click through a form.

## Contract

| Network | Address | Chain ID |
|---|---|---|
| Coston2 (testnet) | `0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE` | 114 |
| Songbird | TBD | 19 |
| Flare | TBD | 14 |

Source of truth: [`src/ParticipantRegister.sol`](../src/ParticipantRegister.sol). Interface: [`src/IParticipantRegister.sol`](../src/IParticipantRegister.sol).

## The whole thing in one command

```bash
# 1. Host participant.json somewhere with CORS open (see § Hosting).
# 2. Register — Coston2 example:
cast send 0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE \
  "register(uint8,string)" 0 "https://yoursite.com/participant.json" \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

That's it. `msg.sender` becomes your on-chain identity. The contract stores `(participantType, infoURI)` keyed on your address; everything else is metadata at the URL. To update metadata later, edit the file hosted at `infoURI` — no contract call needed unless you change the type or the URL itself.

## Participant types

First argument to `register()`:

| Value | Label | Expected category |
|---|---|---|
| `0` | `Provider` | FTSO data providers, validators, FDC operators |
| `1` | `DeFi` | Lending, DEX, yield, staking protocols |
| `2` | `Wallet` | Wallet applications |
| `3` | `Tool` | Explorers, analytics, dev tools |
| `4` | `FAssetsAgent` | FAssets minting agents |
| `5` | `Exchange` | CEX/DEX with Flare listings |
| `6` | `App` | Games, NFT projects, general dApps |
| `7–19` | — | Reserved for future enum expansion |

The contract treats every type identically. Value `0` carries no special on-chain privilege; it's a consumer-level convention. Downstream tools (indexers, directories, reward systems) may additionally verify claim-of-Provider against Flare's `EntityManager` / `VoterRegistry`, but the registry itself doesn't.

## participant.json — minimal

At whatever URL you use for `infoURI`:

```json
{
  "name": "Your Project",
  "url": "https://your-site.com"
}
```

That's the only hard requirement for downstream renderers. Everything below is optional and additive.

## participant.json — full shape

```json
{
  "@context": {
    "@vocab": "https://schema.org/",
    "flare": "https://proofs.africa/ns/participant#"
  },
  "@type": "Organization",
  "name": "Kopano Oracle",
  "url": "https://kopano.africa",
  "description": "Southern-African FTSO provider.",
  "logo": "https://kopano.africa/brand/logo.svg",
  "flare:brand": {
    "icon": "https://kopano.africa/brand/icon.svg",
    "light": "https://kopano.africa/brand/logo-light.svg",
    "dark": "https://kopano.africa/brand/logo-dark.svg"
  },
  "flare:social": {
    "twitter": "https://twitter.com/kopanoOracle",
    "telegram": "https://t.me/kopano_oracle",
    "github": "https://github.com/kopano-oracle"
  },
  "flare:location": { "country": "ZA" },
  "flare:services": ["ftso", "fast-updates"],
  "flare:nodes": [
    { "network": "flare", "role": "ftso-v2", "country": "ZA" }
  ],
  "flare:rpc": [
    { "network": "flare", "url": "https://flare-rpc.kopano.africa/ext/C/rpc" }
  ]
}
```

Schema: [`assets/participant.schema.json`](../assets/participant.schema.json). Template: [`assets/participant.template.json`](../assets/participant.template.json). Minimal: [`assets/participant.minimal.json`](../assets/participant.minimal.json).

## Hosting

The contract treats `infoURI` as an opaque ≤256-byte string; the only on-chain validation is non-empty + length. The browser fetches it, so three real constraints apply:

1. **HTTPS.** Frontends are served over HTTPS; mixed-content policy blocks `http://`.
2. **Open CORS.** Response must include `Access-Control-Allow-Origin: *` (or the fetching origin). **Default nginx, Apache, and Caddy configs do NOT set this.** Silent browser fetch failures from self-hosted infoURIs are almost always CORS.
3. **Valid JSON.** `JSON.parse(body)` must succeed. HTML error pages served with 200 status break downstream.

Verify from anywhere:

```bash
curl -I -H "Origin: https://register.proofs.africa" https://yoursite.com/participant.json | grep -i access-control
```

No `access-control-allow-origin:` header = browsers will silently refuse.

### Hosting options ranked

| Option | CORS default | Immutable | Notes |
|---|---|---|---|
| GitHub Pages (`<user>.github.io/<repo>/participant.json`) | ✅ | No (tied to repo state) | Best default. Push + it serves. |
| GitHub raw (`raw.githubusercontent.com/<user>/<repo>/main/...`) | ✅ | No (mutable per commit) | Served as `text/plain`; `JSON.parse` works fine |
| IPFS gateway (`ipfs.io/ipfs/<CID>`) | ✅ | ✅ (content-addressed) | Requires pinning to stay resolvable |
| Arweave (`arweave.net/<txId>`) | ✅ | ✅ (permanent) | Pay-once AR fee; ~minutes TX finality |
| S3 / R2 / GCS public object | ⚠️ (configure once) | No | One CORS rule on the bucket |
| Self-hosted (own domain) | ❌ must configure | No | Full control, easy to misconfigure — see gotcha above |

Fix CORS on the common web servers:

- **nginx**: `add_header Access-Control-Allow-Origin *;` inside the server or location block
- **apache**: `Header set Access-Control-Allow-Origin "*"` in `.htaccess` or vhost
- **caddy**: `header Access-Control-Allow-Origin *`
- **Cloudflare in front**: disable orange-cloud proxy for the JSON path or add a Page Rule

## Reading via `cast`

```bash
RPC=https://coston2-api.flare.network/ext/C/rpc
REG=0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE

# One address:
cast call $REG \
  "getParticipant(address)((address,uint8,string,bool,uint256,uint256,uint256))" \
  0xYOUR_ADDRESS --rpc-url $RPC

# Every registered address (active + inactive):
cast call $REG "getAllParticipants()(address[])" --rpc-url $RPC

# Only active:
cast call $REG "getActiveParticipants()(address[])" --rpc-url $RPC

# Paginated — safe for on-chain / subgraph consumers:
cast call $REG \
  "getParticipants(uint256,uint256)((address,uint8,string,bool,uint256,uint256,uint256)[])" \
  0 50 --rpc-url $RPC

# Filter by type (0 = Provider, 1 = DeFi, …):
cast call $REG "getParticipantsByType(uint8)(address[])" 0 --rpc-url $RPC

# Counts:
cast call $REG "participantCount()(uint256)" --rpc-url $RPC
cast call $REG "activeCount()(uint256)" --rpc-url $RPC
cast call $REG "typeCount(uint8)(uint256)" 0 --rpc-url $RPC
```

## Reading via viem

```typescript
import { createPublicClient, http, defineChain, parseAbi } from "viem";

const coston2 = defineChain({
  id: 114,
  name: "Coston2",
  nativeCurrency: { name: "Coston2 Flare", symbol: "C2FLR", decimals: 18 },
  rpcUrls: { default: { http: ["https://coston2-api.flare.network/ext/C/rpc"] } },
});

const pub = createPublicClient({ chain: coston2, transport: http() });
const abi = parseAbi([
  "function getParticipant(address addr) view returns ((address owner, uint8 participantType, string infoURI, bool active, uint256 index, uint256 registeredAt, uint256 updatedAt))",
]);

const p = await pub.readContract({
  address: "0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE",
  abi,
  functionName: "getParticipant",
  args: ["0xYourAddress"],
});
```

## Writing via viem

```typescript
import { createWalletClient, http, parseAbi } from "viem";
import { privateKeyToAccount } from "viem/accounts";

const abi = parseAbi([
  "function register(uint8 participantType, string infoURI)",
  "function unregister()",
]);

const wallet = createWalletClient({
  chain: coston2,
  transport: http(),
  account: privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`),
});

await wallet.writeContract({
  address: "0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE",
  abi,
  functionName: "register",
  args: [0, "https://yoursite.com/participant.json"],
});
```

## Updating your metadata

You don't touch the contract. Edit the JSON at your `infoURI`; browsers re-fetch on next render. The on-chain tuple `(participantType, infoURI, active)` is unchanged.

Only call `register()` again when:

- You want to change your `participantType`, or
- You want to point at a different `infoURI`, or
- You're reactivating after `unregister()`.

In all three cases it's the same call with the new values. The contract updates in place: same array index, same `registeredAt`, bumped `updatedAt`.

## Deactivating

```bash
cast send 0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE \
  "unregister()" \
  --rpc-url https://coston2-api.flare.network/ext/C/rpc \
  --private-key $PRIVATE_KEY
```

Flips `active = false`. Your row stays in the append-only index. You disappear from `getActiveParticipants()` and `getParticipantsByType()`. Reactivate by calling `register(...)` again with any params (keeps the same `registeredAt`, bumps `updatedAt`).

## Events

Indexers:

```solidity
event ParticipantRegistered(address indexed owner, uint8 indexed participantType, uint256 index, string infoURI);
event ParticipantUnregistered(address indexed owner, uint256 index);
```

`ParticipantRegistered` fires on both first registration and updates. Cross-reference the event's block against the stored `registeredAt` to distinguish: equal → new, greater → update.

## Gas

| Action | Typical |
|---|---|
| `register()` first time (256-byte URI, cold slots) | ~199k — worst case ~411k |
| `register()` update (in place) | ~40–80k |
| `unregister()` | ~40k |
| View calls (`getParticipant`, etc.) | free — `eth_call` |

At Flare mainnet gas prices, initial registration is a small fraction of a cent.

## Invariants

- **No admin, no owner, no upgradeability.** `register()` and `unregister()` are the only write entry points; both operate on `msg.sender` only.
- **No funds held.** `receive()` reverts on any FLR transfer.
- **`msg.sender` is the sole identity authority.** The contract does not verify that the wallet signing `register()` actually represents the project claimed in the JSON. If you register under the name "Bifrost Wallet" from an address the real Bifrost doesn't control, the contract stores that claim faithfully. Consumers who care about provenance cross-check against external identity primitives (EntityManager, TowoLabs mirror, signature challenges).
- **`register()` is idempotent for msg.sender.** Calling it twice from the same address updates in place rather than reverting.
- **Append-only index.** `unregister()` flips `active`; it never removes the record, so `_index` positions are stable across all registrations.

## Why permissionless

The incumbent canonical provider catalog — TowoLabs's [ftso-signal-providers](https://github.com/TowoLabs/ftso-signal-providers) — is curator-gated. Providers not in that list render as raw hex addresses across the ecosystem until a PR is merged; the maintainer is also a competing provider. This contract exists so the identity layer doesn't need any such intermediary.

The cost of permissionlessness is that arbitrary addresses can claim arbitrary brand names. That's a consumer-side problem to solve with downstream verification (FSP registry membership, signed statements at the infoURI, reputation layers), not a registry-side gate. Clients who want gate-kept views can filter by on-chain FSP status; clients who want the full permissionless set can ingest everyone.

## Related

- Frontend: [register.proofs.africa](https://register.proofs.africa) — the form-based UI over this contract, with autofill from the TowoLabs mirror, JSON preview, edit mode, and a chain-identity gate for Provider type.
- Deploy script: [`script/Deploy.s.sol`](../script/Deploy.s.sol).
- Self-register script template: [`script/Register.s.sol`](../script/Register.s.sol).
- Audit notes: CLAUDE.md § Audit Status.
