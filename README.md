# apregister — Flare Participant Registry

[![CI](https://github.com/africanproofs/apregister/actions/workflows/ci.yml/badge.svg)](https://github.com/africanproofs/apregister/actions/workflows/ci.yml)

A permissionless on-chain registry for the Flare ecosystem. Any address — providers, protocols, wallets, tools, agents, exchanges, apps — registers with a type and a URL pointing to a standardized JSON-LD metadata file.

**No admin. No ownership. No gatekeepers. Fully permissionless.**

> **Power-user path:** the contract is the API. One `cast send`, one JSON file you host yourself. See [`docs/register.md`](docs/register.md).

## How it works

In a permissionless manner, the contract facilitates a decentralized method to:

1. notify the ecosystem about chain infrastructure offerings, and
2. allow for an exchange of meta-information among and about chain providers, developers, validators, wallets, exchanges, dApps, and AI agents.

### From the participant side

The contract exposes two state-altering functions: `register` and `unregister`.

A call to `register(participantType, infoURI)` takes two parameters:

1. `participantType` — a numeric enum slot from 0 to 19. Slots 0-7 are named (`Provider`, `DeFi`, `Wallet`, `Tool`, `FAssetsAgent`, `Exchange`, `App`, `AgenticAI`); slots 8-19 are reserved for future use without a contract redeploy.
2. `infoURI` — an HTTPS URL (max 256 bytes) pointing to a JSON-LD file you host yourself. That file carries everything that isn't on-chain: name, logo, description, services, social handles, infrastructure declarations.

The new record defaults to `active = true`. It is the signer's address (`msg.sender`) that is used as the index key for the record.

A call to `unregister()` takes no parameters and sets `active` to `false`. No data is removed. A subsequent call to `register` will set `active` back to `true`.

An update to the record is triggered when the sender submits another `register` call with new parameters. Same-address re-register is an upsert.

The participant must sign the `register` and `unregister` transactions. Provider type (slot 0) is the only type with an on-chain identity gate: on Flare mainnet, the signing wallet must be a registered identity in Flare's `VoterRegistry`. All other types are open to any wallet.

### From the data-consumer side

Once registered, other stakeholders — dApp developers, indexers, wallets, registries — use the information as a reference and a starting point in sourcing data about deployed chain infrastructure. Interaction happens through several read functions:

- `getAllParticipants()` returns every registered address, active or inactive.
- `getActiveParticipants()` returns only addresses with `active = true`.
- `getParticipantsByType(participantType)` filters the active set by type slot.
- `getParticipant(address)` returns the full record as a struct: `(owner, participantType, infoURI, active, index, registeredAt, updatedAt)`.
- `getParticipants(offset, limit)` paginates for on-chain consumers that cannot afford the O(n) iteration of the first three calls.
- `participantCount()`, `activeCount()`, `typeCount(participantType)` return counts.

Off-chain consumers fetch the JSON-LD at each `infoURI` for rich metadata. See [`docs/participant-json.md`](docs/participant-json.md) for the schema and hosting guidance.

The contract has no admin facility. The identity registry address is pinned at deploy time and is `immutable`. No upgrade path, no privileged role, no funds held.

## Contract

### Write Functions

| Function | Access | Description |
|----------|--------|-------------|
| `register(ParticipantType, infoURI)` | `msg.sender` | Register or update. Sets `active = true`. Type is on-chain filterable; rich metadata lives at `infoURI`. |
| `unregister()` | `msg.sender` | Deactivate. Data retained, marked inactive. |

### Read Functions

| Function | Description |
|----------|-------------|
| `getParticipant(address)` | Look up by entity address. Returns full `Participant` struct. |
| `getAllParticipants()` | All registered addresses (active + inactive). |
| `getActiveParticipants()` | Only active addresses. Off-chain use only (O(n) iteration). |
| `getParticipantsByType(ParticipantType)` | Active participants filtered by type. Off-chain use only (O(n) iteration). |
| `getParticipants(offset, limit)` | Paginated retrieval of full `Participant` structs. Safe for on-chain consumers. |
| `isRegistered(address)` | Check if an address has ever registered (active or inactive). |
| `participantCount()` | Total registered count (active + inactive). |
| `activeCount()` | Active participant count. |
| `typeCount(ParticipantType)` | Active count for a specific type. |

### Participant Types

| Value | Type | Description |
|-------|------|-------------|
| 0 | `Provider` | FTSO data providers, validators, FDC operators |
| 1 | `DeFi` | Lending, DEX, yield, staking protocols |
| 2 | `Wallet` | Wallet applications |
| 3 | `Tool` | Explorers, analytics, dev tools |
| 4 | `FAssetsAgent` | FAssets minting agents |
| 5 | `Exchange` | CEX/DEX with Flare listings |
| 6 | `App` | Games, NFT projects, general dApps |
| 7 | `AgenticAI` | Autonomous AI agents operating in the Flare ecosystem |
| 8-19 | `Reserved` | Future use — assign meaning via off-chain convention without redeploying |

### Events

- `ParticipantRegistered(address indexed owner, ParticipantType indexed participantType, uint256 index, string infoURI)`
- `ParticipantUnregistered(address indexed owner, uint256 index)`

### On-Chain Data

Each participant stores:

| Field | Description |
|-------|-------------|
| `owner` | Entity address (`msg.sender` on registration) |
| `participantType` | On-chain filterable type (Provider, DeFi, Wallet, etc.) |
| `infoURI` | URL to JSON-LD metadata file (max 256 bytes) |
| `active` | Whether the registration is active |
| `index` | Position in the participant index |
| `registeredAt` | Block number of first registration |
| `updatedAt` | Block number of last update |

The registry is append-only: unregistering sets `active = false` but never removes the record. Re-registering reactivates the entry with updated data.

## participant.json Schema

The contract stores only a type and a pointer (`infoURI`). All rich metadata lives in the JSON-LD file at that URL.

**Design principle**: No duplication. Addresses, nodes, and keys are on-chain in EntityManager. participant.json contains only what ISN'T on-chain — name, logo, contact, services, infrastructure location.

### Required Fields

| Field | Type | Description |
|---|---|---|
| `name` | string (max 64) | Display name |
| `url` | string (max 256) | Website URL |

### Recommended Fields

| Field | Type | Description |
|---|---|---|
| `description` | string (max 350) | Short description |
| `logo` | string (URL) | Square logo image (PNG, min 128px) |

### Optional Fields

| Field | Type | Description |
|---|---|---|
| `flare:participant-type` | integer (0-19) | Echoes the on-chain `participantType` enum slot (e.g. `0` = Provider). Lets consumers verify JSON-vs-chain match without an extra RPC. |
| `flare:participant-type-label` | string | Human-readable mirror of the type (e.g. `"Provider"`). |
| `flare:social` | object | Usernames: `twitter`, `telegram`, `discord`, `github` |
| `flare:location` | object | Organization domicile: `country` (ISO 3166-1 alpha-2) |
| `flare:networks` | object[] | Per-chain service breakdown: `id` + `services[]`. Supersedes the deprecated flat `flare:services`. |
| `flare:nodes` | object[] | Operational hardware declarations: `network` + `role` + `country`. Where you physically run nodes. |
| `flare:tools` | object[] | Public ecosystem services you publish: `category` + `name` + `url` (+ optional `networks[]`, `description`). 12-category enum — see [`docs/participant-json.md`](docs/participant-json.md#flaretools--public-ecosystem-services). |

Deprecated (still validates for legacy JSONs): `flare:services` (flat array — use `flare:networks` instead) and `flare:rpc[]` (use `flare:tools[]` with `category: "rpc"`).

`flare:location.country` = where the organization is domiciled.  
`flare:nodes[].country` = where each node physically runs. Different things.

### Examples

**Full provider** — see [`assets/participant.template.json`](assets/participant.template.json)

**Minimum valid file** — see [`assets/participant.minimal.json`](assets/participant.minimal.json):
```json
{
  "@context": { "@vocab": "https://schema.org/", "flare": "https://proofs.africa/ns/participant#" },
  "@type": "Organization",
  "name": "My Provider",
  "url": "https://example.com"
}
```

**Validation schema** — [`assets/participant.schema.json`](assets/participant.schema.json)

### Why JSON-LD?

The `@context` makes the file self-describing. Any JSON-LD parser — including AI agents — understands Schema.org fields (`name`, `url`, `logo`, `description`) without prior knowledge of this spec. Flare-specific fields use the `flare:` namespace prefix.

### Registration

1. Host your `participant.json` at a public URL
2. Call `register(ParticipantType.Provider, "https://yoursite.com/participant.json")` with your entity address
3. Update anytime by calling `register()` again with a new type or URI

Step-by-step CLI walkthrough: [`docs/register.md`](https://github.com/africanproofs/apregister/blob/main/docs/register.md).

## For Toolmakers

The contract is designed for easy integration by ecosystem dashboards and wallets.

**Bulk fetch** all participants with pagination:
```solidity
// Get first 50 participants
Participant[] memory page = register.getParticipants(0, 50);
// Each has: owner, participantType, infoURI, active, index, registeredAt, updatedAt
```

**Filter by type** (FTSO providers only):
```solidity
// Get all active providers
address[] memory providers = register.getParticipantsByType(ParticipantType.Provider);
// Fetch each provider's participant.json from their infoURI for name, logo, etc.
```

**Active-only listing**:
```solidity
address[] memory active = register.getActiveParticipants();
```

**Type counts** (for dashboards):
```solidity
uint256 providers = register.typeCount(ParticipantType.Provider);
uint256 defi = register.typeCount(ParticipantType.DeFi);
uint256 total = register.activeCount();
```

**Events for indexers** — `ParticipantRegistered` emits indexed `owner` and `participantType` for efficient subgraph queries.

## Development

Built with [Foundry](https://getfoundry.sh/). Solidity 0.8.20, EVM London.

```bash
forge build
forge test -vvv
forge test --gas-report
```

### Deploy

```bash
# Coston2 (testnet)
IDENTITY_REGISTRY=0xf77C24aFAC992CE17fFe2a01b642d1CE5d025D9e \
  forge script script/Deploy.s.sol --rpc-url $COSTON2_RPC --broadcast --private-key $PRIVATE_KEY

# Flare mainnet (after FlareIdentityAdapter deployed)
IDENTITY_REGISTRY=<adapter-address> \
  forge script script/Deploy.s.sol --rpc-url $FLARE_RPC --broadcast --private-key $PRIVATE_KEY
```

### Docker

A `forge.sh` wrapper is provided for systems where the native Foundry binary requires a newer glibc:

```bash
./forge.sh build
./forge.sh test -vvv
```

## Deployments

| Network | Address | Chain ID |
|---------|---------|----------|
| Flare | `0xd523159981a545dA5C53Ddbba327A5E6438A171C` | 14 |
| Songbird | n/a (out of v1 scope) | 19 |
| Coston2 (testnet) | `0x09f15b14D16BA645661c576348E4d4C201242bF2` | 114 |

**Verified on Flare mainnet** — source matches deployed bytecode on both [Flarescan](https://flare-explorer.flare.network/address/0xd523159981a545dA5C53Ddbba327A5E6438A171C#code) and [Sourcify](https://sourcify.dev/#/lookup/0xd523159981a545dA5C53Ddbba327A5E6438A171C) (Sourcify `exact_match` on creation + runtime bytecode). The [FlareIdentityAdapter](https://flare-explorer.flare.network/address/0xF2F2BF535A14b908d599845968C150abE3987F3a#code) at `0xF2F2BF535A14b908d599845968C150abE3987F3a` is verified the same way.

**Verified on Coston2 testnet** — [ParticipantRegister](https://coston2-explorer.flare.network/address/0x09f15b14D16BA645661c576348E4d4C201242bF2) and [MockIdentityRegistry](https://coston2-explorer.flare.network/address/0xf77C24aFAC992CE17fFe2a01b642d1CE5d025D9e) verified on Routescan with the same compiler settings (`solc 0.8.20`, optimizer 200 runs, EVM `london`). Sourcify does not currently support chain 114 — Routescan is the canonical Coston2 source-code surface.

## Integrate

Building a directory, wallet, or indexer on top of this registry?

- ABIs: [`abi/ParticipantRegister.abi.json`](abi/ParticipantRegister.abi.json), [`abi/FlareIdentityAdapter.abi.json`](abi/FlareIdentityAdapter.abi.json)
- TypeScript types for `participant.json`: [`types/participant.d.ts`](types/participant.d.ts)
- Integration guide: [`docs/integrate.md`](docs/integrate.md)
- Reference portal (Flare mainnet): [register.proofs.africa](https://register.proofs.africa) — African Proofs' frontend, closed-source. The contract above is the public API; build your own UI freely.

## Security

This contract has been **internally reviewed** by African Proofs' automated audit tooling — 64 tests (55 unit/fuzz + 4 fork against live Flare + 5 invariant), zero Critical/High/Medium findings, no admin surface, no funds held. **No third-party human audit has been performed yet.** A full external audit is on the roadmap before significant value flows through the registry.

Provider registrations (`participantType == 0`) revert at the contract level unless `msg.sender` is a registered identity in the configured `IIdentityRegistry`. See `CLAUDE.md` § Identity-as-signing-key for the architectural rationale.

**Trust signals:**

- 64 tests passing (55 unit/fuzz + 4 fork against live Flare + 5 invariant)
- No admin, no owner, no upgradeability
- Bytecode 5,742 bytes (well under EIP-170 24KB limit)
- Constructor-pinned identity registry (immutable, no admin override)
- Open-source, MIT-licensed

**Security disclosure:** report vulnerabilities via Telegram DM to `@khosimorafo` (https://t.me/khosimorafo). Please do not open public issues for security-sensitive findings.

## License

MIT
