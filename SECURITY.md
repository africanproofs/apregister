# Security Policy

## Reporting a Vulnerability

If you find a vulnerability in this contract, please report it privately to **security@proofs.africa**.

Do not open a public issue or merge request for security-sensitive findings.

We aim to acknowledge a report within 48 hours and to provide an initial assessment within 7 days. Coordinated disclosure window is **90 days** from acknowledgement; if a fix is non-trivial we may request an extension and will discuss publicly.

If you prefer encrypted email, request our GPG key fingerprint in your first message.

## Scope

In scope:

- `src/ParticipantRegister.sol` — the deployed contract
- `src/FlareIdentityAdapter.sol` — the identity-gate adapter (Flare mainnet)
- `src/IIdentityRegistry.sol` + interface contracts
- The deployment scripts under `script/`

Out of scope:

- `src/test-support/MockIdentityRegistry.sol` — testnet-only; never deployed to mainnet
- Issues with the off-chain JSON-LD schema at `assets/participant.schema.json` (not security-critical; open a regular issue)
- Issues with the frontend portal — those belong in [apregister-web](https://github.com/africanproofs/apregister-web)
- Reports against Flare's own core contracts (EntityManager, FlareContractRegistry, etc.) — please report to the Flare Foundation

## Audit Status

This contract has **not** received a third-party security audit. The current security posture is:

- Internal review by AP's automated audit tooling (55 unit + fuzz tests + 4 fork tests against Flare mainnet `isRegisteredIdentity` reads)
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

If you find a threat outside this list, that's a real finding — please report.

## Disclosure Examples

We will publicly credit reporters who request it. We will also publish post-mortems for any confirmed Critical or High finding once a fix is deployed.
