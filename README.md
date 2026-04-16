# apregister — Flare Participant Register

A permissionless on-chain registry for Flare and Songbird ecosystem participants. Any address — providers, protocols, wallets, tools, agents, exchanges, apps — registers with a type and a URL pointing to a standardized JSON-LD metadata file.

**No admin. No ownership. No gatekeepers. Fully permissionless.**

### Why?

The current canonical source for FTSO provider metadata is a centralized GitHub repo maintained by a single entity (TowoLabs). Every ecosystem tool (flaremetrics.io, flare.builders, Bifrost Wallet) depends on it. Providers who don't submit a PR are displayed as raw hex addresses. The maintainer is also a competing provider.

This contract moves participant identity on-chain, where it belongs. Any entity can register and update their metadata at any time without approval from anyone.

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
| 7-19 | `Reserved` | Future use — assign meaning via off-chain convention without redeploying |

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
| `flare:social` | object | Usernames: `twitter`, `telegram`, `discord`, `github` |
| `flare:location` | object | Organization domicile: `country` (ISO 3166-1 alpha-2) |
| `flare:services` | string[] | What the entity runs: `ftso`, `fdc`, `fast-updates`, `validator`, `fassets-agent`, `lending`, `dex`, `staking` |
| `flare:nodes` | object[] | Node declarations: `network` + `role` + `country`. Physical infrastructure location |
| `flare:rpc` | object[] | Public RPC endpoints: `network` + `url` |

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
forge script script/Deploy.s.sol --rpc-url $SONGBIRD_RPC --broadcast --private-key $PRIVATE_KEY
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
| Songbird | TBD | 19 |
| Flare | TBD | 14 |

## Research & Planning

| Document | Description | Status |
|---|---|---|
| [01-architecture.md](research/01-architecture.md) | Contract architecture, storage design, relationship to EntityManager | Partially stale — describes pre-simplification design |
| [02-competitive-positioning.md](research/02-competitive-positioning.md) | TowoLabs incumbent analysis, why AP register wins, competitive response risk | Current |
| [03-security-analysis.md](research/03-security-analysis.md) | Minimised attack surface review, griefing vectors, recommended fixes | Partially stale — some findings relate to removed features |
| [04-adoption-strategy.md](research/04-adoption-strategy.md) | Target providers, outreach timeline, messaging by audience, success metrics | Current |
| [05-launch-plan.md](research/05-launch-plan.md) | Technical plan (security fixes, tests, testnet, mainnet), resource plan, timeline | Partially stale — references removed features |

## Related Projects

| Project | Relationship |
|---|---|
| **apdao** | Bond Pool contract. Register demonstrates AP's smart contract capability before asking community to trust the Bond Pool |
| **apsocial** | Register deployment is apsocial content. Growth milestones are posts |
| **proofs.africa** | Integration guide published on proofs.africa. Register listed as AP project |
| **flaremetrics.io** | Target integration — Tim Rowley reads from contract instead of TowoLabs JSON |
| **flare.builders** | Target integration — NeilD reads from contract instead of TowoLabs JSON |

## License

MIT
