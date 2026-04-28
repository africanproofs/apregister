# Integrate the registry

Build a directory, indexer, or wallet integration on top of `ParticipantRegister`.

## Contract

| Network | Chain ID | Address |
|---|---|---|
| Coston2 (testnet) | 114 | `0xF9fDB222FCa62B50a0d94C1F31650a4034b60B12` |
| Flare | 14 | TBD |
| Songbird | 19 | TBD |

ABI: [`abi/ParticipantRegister.abi.json`](https://github.com/africanproofs/apregister/blob/main/abi/ParticipantRegister.abi.json)

TypeScript types for `participant.json`: [`types/participant.d.ts`](https://github.com/africanproofs/apregister/blob/main/types/participant.d.ts)

## Read the registry

```typescript
import { createPublicClient, http, defineChain, parseAbi } from "viem";

const coston2 = defineChain({
  id: 114,
  name: "Coston2",
  nativeCurrency: { name: "Coston2 Flare", symbol: "C2FLR", decimals: 18 },
  rpcUrls: { default: { http: ["https://coston2-api.flare.network/ext/C/rpc"] } },
});

const client = createPublicClient({ chain: coston2, transport: http() });
const abi = parseAbi([
  "function getActiveParticipants() view returns (address[])",
  "function getParticipants(uint256,uint256) view returns ((address,uint8,string,bool,uint256,uint256,uint256)[])",
  "function getParticipantsByType(uint8) view returns (address[])",
]);

const REG = "0xF9fDB222FCa62B50a0d94C1F31650a4034b60B12";
const all = await client.readContract({ address: REG, abi, functionName: "getActiveParticipants" });
```

## Index events

```solidity
event ParticipantRegistered(address indexed owner, uint8 indexed participantType, uint256 index, string infoURI);
event ParticipantUnregistered(address indexed owner, uint256 index);
```

`ParticipantRegistered` fires on both first registration and updates. To distinguish:

```typescript
// after fetching the receipt:
const p = await client.readContract({ address: REG, abi, functionName: "getParticipant", args: [event.args.owner] });
const isNew = p.registeredAt === BigInt(receipt.blockNumber);
```

## Pagination

For on-chain consumers (Solidity), use `getParticipants(offset, limit)`. Off-chain `eth_call` consumers can use the unbounded reads (`getAllParticipants`, `getActiveParticipants`, `getParticipantsByType`) but those become expensive past ~1000 participants.

## Resolve metadata

The on-chain record stores only `(participantType, infoURI)`. To get the full profile, fetch and parse the JSON at `infoURI`. Schema: [`assets/participant.schema.json`](https://github.com/africanproofs/apregister/blob/main/assets/participant.schema.json).

```typescript
const meta = await fetch(p.infoURI).then(r => r.json());
// meta.name, meta.url, meta.description, meta["flare:brand"]?.icon, etc.
```

CORS on the participant's `infoURI` is the most common integration failure. The contract doesn't validate it — your fetch will fail silently if the host hasn't set `Access-Control-Allow-Origin`. See [Your participant.json § CORS](./participant-json.md#cors--read-this-if-you-self-host).

## Test-support contracts (Coston2 only)

`MockIdentityRegistry` (`0xf77C24aFAC992CE17fFe2a01b642d1CE5d025D9e`) is an admin-managed allowlist that mirrors the EntityManager's "is this an FSP identity?" semantics on testnet, where the real EntityManager isn't populated. The portal uses it on Coston2 to gate the Provider participant type. **Do not rely on it from production code** — Flare mainnet uses the real `EntityManager` via `FlareContractRegistry`.
