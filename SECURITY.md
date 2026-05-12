# Security Policy

## Reporting a Vulnerability

If you find a vulnerability in this contract, please report it privately via Telegram DM to **@khosimorafo** (https://t.me/khosimorafo).

Do not open a public issue or pull request for security-sensitive findings.

We aim to acknowledge a report within 48 hours and to provide an initial assessment within 7 days. Coordinated disclosure window is **90 days** from acknowledgement; if a fix is non-trivial we may request an extension and will discuss publicly.

For sensitive PoC code or logs, attach them in-channel; request a Telegram Secret Chat (end-to-end encrypted) in your first message if needed.

## Scope

In scope:

- `src/ParticipantRegister.sol` — the deployed contract
- `src/FlareIdentityAdapter.sol` — the identity-gate adapter (Flare mainnet)
- `src/IIdentityRegistry.sol` + interface contracts
- The deployment scripts under `script/`

Out of scope:

- `src/test-support/MockIdentityRegistry.sol` — testnet-only; never deployed to mainnet
- Issues with the off-chain JSON-LD schema at `assets/participant.schema.json` (not security-critical; open a regular issue)
- Issues with the frontend portal at [register.proofs.africa](https://register.proofs.africa) — the reference UI is closed-source by design. Report frontend bugs (UX, rendering, browser compatibility) via the same Telegram channel; we'll triage them privately.
- Reports against Flare's own core contracts (EntityManager, FlareContractRegistry, etc.) — please report to the Flare Foundation

## Audit Status

This contract has **not** received a third-party security audit. The current security posture is:

- Internal review by AP's automated audit tooling (64 tests: 55 unit/fuzz + 4 fork against Flare mainnet `isRegisteredIdentity` reads + 5 invariant)
- Zero Critical / High / Medium findings from internal review
- No admin surface, no upgrade path, no funds held by the contract
- Constructor-pinned identity registry — immutable after deployment

A third-party audit is on the roadmap before significant ecosystem reliance on the registry. Until then: **treat this contract as a discovery layer, not a trust anchor**. Off-chain consumers should always re-validate (fetch the JSON at `infoURI`, verify identity via independent means).

## Threat Model

The contract holds zero funds and has no admin. The realistic threats are:

1. **Bogus Provider registration** — gated by `IIdentityRegistry` (constructor-pinned). On Flare mainnet, only addresses in `VoterRegistry` can register as `participantType == 0`.
2. **Squatting on canonical addresses** — anyone can register any non-Provider type for any wallet they control. This is by design (permissionless). Consumers must not assume a registration implies authorization beyond what `msg.sender` proves.
3. **JSON spoofing at `infoURI`** — the contract cannot validate off-chain content. Consumers verify out-of-band (DNS, GitHub, IPFS provenance).
4. **Re-registration attack** — `register()` from the same `msg.sender` updates the existing entry. This is the intended upsert behaviour.
5. **Stale Provider status** — Provider eligibility is checked at `register()` only; the contract does NOT re-validate `VoterRegistry` membership on reads. A Provider who later loses FSP standing (leaves `VoterRegistry`) remains listed in the registry as `type 0 = Provider` until they unregister or someone calls them out. Consumers building current-FSP assertions should call the adapter (`FlareIdentityAdapter.isRegisteredIdentity`) at read time, not trust the registry's static type slot.

If you find a threat outside this list, that's a real finding — please report.

## Disclosure Examples

We will publicly credit reporters who request it. We will also publish post-mortems for any confirmed Critical or High finding once a fix is deployed.
