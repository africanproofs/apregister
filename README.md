# apregister — Flare Participant Register

A permissionless on-chain registry for Flare and Songbird infrastructure participants. Data providers, validators, and FDC operators register with metadata (name, description, logo, website) and a URL to a standardized JSON file describing their offerings.

**No admin. No ownership. No gatekeepers. Fully permissionless.**

### Why?

The current canonical source for FTSO provider metadata is a centralized GitHub repo maintained by a single entity (TowoLabs). Every ecosystem tool (flaremetrics.io, flare.builders, Bifrost Wallet) depends on it. Providers who don't submit a PR are displayed as raw hex addresses. The maintainer is also a competing provider.

This contract moves provider identity on-chain, where it belongs. Any participant can register and update their metadata at any time without approval from anyone.

## Contract

### Write Functions

| Function | Access | Description |
|----------|--------|-------------|
| `register(delegation, name, description, url, logoURI, infoURI)` | Participant | Register or update. Sets `active = true`. |
| `unregister()` | Participant | Deactivate. Data retained, marked inactive. |

### Read Functions

| Function | Description |
|----------|-------------|
| `getParticipant(address)` | Look up by voter/identity address. |
| `getByDelegationAddress(address)` | Look up by delegation address. |
| `getAllParticipants()` | All registered addresses (active + inactive). |
| `getActiveParticipants()` | Only active addresses. |
| `getParticipants(offset, limit)` | Paginated retrieval of full metadata. |
| `isRegistered(address)` | Check if an address has ever registered. |
| `participantCount()` | Total registered count. |

### Events

- `ParticipantRegistered(owner, delegation, index, name, url, logoURI)`
- `ParticipantUnregistered(owner, index)`

### On-Chain Metadata

Each participant stores:

| Field | Required | Description |
|-------|----------|-------------|
| `delegation` | No | Delegation address (for toolmaker reverse lookup) |
| `name` | Yes | Display name (max 32 chars recommended) |
| `description` | No | Short description (max 350 chars recommended) |
| `url` | Yes | Website URL |
| `logoURI` | No | Direct URL to logo image (128-256px PNG) |
| `infoURI` | No | URL to full standardized JSON metadata file |
| `registeredAt` | Auto | Block number of first registration |
| `updatedAt` | Auto | Block number of last update |

The registry is append-only: unregistering sets `active = false` but never removes the record. Re-registering reactivates the entry with updated data.

## Participant Metadata File

For extended metadata beyond what's stored on-chain, participants host a standardized JSON file at their `infoURI`. See [`assets/participant.template.json`](assets/participant.template.json) for the template.

**The participant decides what they publish. No authority.**

Fields include:
- **chains** — Chain IDs and associated addresses
- **organisation** — Branding (logos), location, contact (website, email, Discord, Telegram, Twitter, Git)
- **infrastructure** — Per-chain details: location, RPC endpoint, WebSocket endpoint

### Registration Instructions

1. Copy the [template](assets/participant.template.json) and host it at a public URL
2. Call `register()` on the deployed contract with your metadata
3. Update anytime by calling `register()` again

## For Toolmakers

The contract is designed for easy integration by ecosystem dashboards and wallets.

**Bulk fetch** all providers with pagination:
```solidity
// Get first 50 participants
Participant[] memory page = register.getParticipants(0, 50);
```

**Delegation lookup** (how wallets find provider metadata):
```solidity
// User delegates to 0x1234... — look up who that is
Participant memory p = register.getByDelegationAddress(delegationAddress);
// p.name, p.logoURI, p.description are ready to display
```

**Active-only filtering**:
```solidity
address[] memory active = register.getActiveParticipants();
```

**Events for indexers** — `ParticipantRegistered` emits indexed `owner` and `delegation` for efficient subgraph queries.

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

| Document | Description |
|---|---|
| [01-architecture.md](research/01-architecture.md) | Contract architecture, storage design, relationship to EntityManager |
| [02-competitive-positioning.md](research/02-competitive-positioning.md) | TowoLabs incumbent analysis, why AP register wins, competitive response risk |
| [03-security-analysis.md](research/03-security-analysis.md) | Minimised attack surface review, 5 griefing vectors, recommended fixes |
| [04-adoption-strategy.md](research/04-adoption-strategy.md) | Target providers, outreach timeline, messaging by audience, success metrics |
| [05-launch-plan.md](research/05-launch-plan.md) | Technical plan (security fixes → tests → testnet → mainnet), resource plan, timeline |

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
