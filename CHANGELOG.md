# Changelog

## 2026-05-12 PM — v1.2.1 trust-anchor sync (CTO v4 HIGH fixes)

CTO v4 assessment surfaced three stale trust-vector strings that the rapid v1.2.0 patches outpaced. All three are single-string edits — no source, ABI, or schema changes.

- **`SECURITY.md`** — removed broken `github.com/africanproofs/apregister-web` link (the frontend is closed-source by operator decision). Frontend issues now route to the same Telegram channel.
- **`docs/integrate.md`** — Flare gate description now matches the verified adapter source. Was `VoterRegistry.getRegisteredVoters(currentRewardEpochId)` (the pre-Prior-#2 implementation); now `VoterRegistry.isVoterRegistered(msg.sender, currentRewardEpochId)` (O(1) direct lookup, post-2026-05-12 redeploy). Links to the verified adapter source for cross-check.
- **`README.md`** — Optional Fields table moved off the deprecated `flare:services` (flat) + `flare:rpc[]` rows. Now lists `flare:tools[]`, `flare:networks[]`, `flare:participant-type` + label as the canonical fields, with the deprecated pair called out below.

No code changes. No contract redeploy. No test count change (still 64). Tag: `v1.2.1`.

## 2026-05-12 PM — invariant test suite

- New `test/invariant/Handler.sol` — bounded-actor handler that drives random `register`/`unregister` sequences over a 5-actor pool. 2 actors are identity-registered (Provider path reachable); 3 are not (gate-revert path covered). Four call surfaces: `registerNonProvider`, `registerProvider`, `registerProviderUnauthorized` (negative case — asserts the gate always reverts), `unregisterSelf`.
- New `test/invariant/ParticipantRegister.invariant.t.sol` — 5 invariants:
  - `activeCount <= participantCount` (no underflow/overflow)
  - `getActiveParticipants().length == activeCount()` (active-array iteration matches counter)
  - Sum of `getParticipantsByType(t)` lengths across all 20 enum slots equals `activeCount` (catches type-counter drift on re-register)
  - `identityRegistry` immutable (no codepath mutates it)
  - Every address in `getActiveParticipants()` reports `active = true` (no stale enumeration)
- `foundry.toml` adds `[invariant]` profile (256 runs × 64 depth × 4 selectors = 16,384 calls per invariant).
- Total: **64 tests** passing (55 unit/fuzz + 4 fork against live Flare + 5 invariant). README + CONTRIBUTING test count updated.

Closes the CTO v3 "no invariant tests" finding. Standard trust signal for an unaudited permissionless contract.

## 2026-05-12 PM — README verification callout symmetric + cast glibc note

- `README.md` adds a "Verified on Coston2 testnet" callout next to the existing Flare-mainnet one, linking both Coston2 contracts on the explorer. Notes that Sourcify does not currently support chain 114.
- `CONTRIBUTING.md` § Testing adds a `cast` workaround section: `cast` requires `glibc ≥ 2.33` and the `./forge.sh` wrapper does not proxy it. Operators on older hosts can hand-encode address constructor args as zero-padded 32-byte hex.

## 2026-05-12 PM — docs document `flare:tools[]`

- `docs/participant-json.md` adds a new "`flare:tools[]` — public ecosystem services" section between "Why `flare:participant-type`" and "Where to host". Documents the 12-value `category` enum, the 5 per-entry fields (`name`, `url`, `category` required; `networks`, `description` optional), and the migration path from the deprecated `flare:rpc[]`.
- The "Full" example block now uses `flare:tools[]` instead of `flare:rpc[]`. Operational `flare:nodes[]` line kept (different concept: hardware you run vs URLs you publish).

Closes the gap where the Phase F schema ship (commit `99086c2`) added `flare:tools[]` but the canonical reader-facing doc still only mentioned the legacy `flare:rpc[]`.

## 2026-05-12 PM — Coston2 contracts verified

- `ParticipantRegister` (`0x09f15b14D16BA645661c576348E4d4C201242bF2`) verified on Coston2 Routescan via the Etherscan-compatible endpoint. Constructor arg: `IDENTITY_REGISTRY = 0xf77C24aFAC992CE17fFe2a01b642d1CE5d025D9e`.
- `MockIdentityRegistry` (`0xf77C24aFAC992CE17fFe2a01b642d1CE5d025D9e`) verified the same way. Constructor arg: `initialAdmin = 0xF6ca6bAEf426DfD38Aab69Fbad6CA3AfE4b6e29B` (AP master).
- Verification settings: `solc 0.8.20`, optimizer 200 runs, EVM target `london`. Same settings as the deploy script.
- Sourcify not used — chain 114 (Coston2) is not in Sourcify's supported-chains list. Routescan is the canonical Coston2 source-code surface.

Closes the Flare/Coston2 asymmetry: integrators following the documented "test on Coston2 first" path now see verified source on both networks.

## 2026-05-12 PM — CI on GitHub Actions

- New `.github/workflows/ci.yml` — five jobs (`build`, `test`, `fork-test`, `gas-report`, `drift`) replacing the GitLab CI that ran nowhere on the GitHub-canonical repo. `test` splits unit/fuzz from `fork-test` (RPC-dependent) so the green-CI signal stays honest when public RPC flakes.
- Deleted `.gitlab-ci.yml` — dead code; the canonical repo is GitHub.
- README adds a CI status badge pointing at `actions/workflows/ci.yml`.

Closes the CTO v3 "CI runs nowhere" finding — the Phase 2 drift gate now actually blocks merges.

## 2026-05-12 PM — onboarding polish (Phase 2)

- New `examples/` directory with three minimal integrations:
  - [`examples/read-with-viem/`](examples/read-with-viem) — Node ≥ 20 + viem v2, ~80 lines.
  - [`examples/read-with-ethers/`](examples/read-with-ethers) — Node ≥ 20 + ethers v6, same shape.
  - [`examples/register-with-cast/`](examples/register-with-cast) — Foundry power-user path with a starter `participant.json`.
- New `scripts/check-drift.sh` — regenerates `types/participant.d.ts` from `assets/participant.schema.json` and both ABI files from their `.sol` sources, then fails if `git diff` shows the committed files are out of sync. Auto-selects `./forge.sh` when bare `forge` doesn't run on the host's glibc.
- New `drift` CI job in `.gitlab-ci.yml` — runs the same script on every push; blocks merges when committed types/ABIs drift from canonical sources.
- `CONTRIBUTING.md` adds a "Schema extensions" workflow (5-step process) and two new rows to the "What NOT to change without coordinated discussion" table (schema field renames; schema `$id` URL must remain canonical-source-resolvable). Test-count line corrected from 55 to 59.

## 2026-05-12 PM — Flare mainnet contracts verified

- `ParticipantRegister` (`0xd523159981a545dA5C53Ddbba327A5E6438A171C`) verified on Flarescan via Routescan's Etherscan-compatible endpoint AND on Sourcify with `exact_match` on both creation and runtime bytecode.
- `FlareIdentityAdapter` (`0xF2F2BF535A14b908d599845968C150abE3987F3a`) verified identically on both surfaces.
- Verification settings used: `solc 0.8.20`, optimizer enabled (200 runs), EVM target `london`. Same settings as the deploy script.
- README updated with a "Verified" callout linking to both surfaces.

External integrators no longer need to trust AP's commit history — bytecode-to-source provenance is independently checkable.

## 2026-05-12 PM — trust-anchor fixes for OSS readiness

- `abi/FlareIdentityAdapter.abi.json` published (alongside the existing `ParticipantRegister.abi.json`). Integrators inspecting the identity gate now have the adapter ABI without needing to recompile from source.
- `README.md` reframed to drop the broken `apregister-web` source links (the GitHub URL never existed and the GitLab repo is private by design). New framing: the contract is the public API; the AP frontend at `register.proofs.africa` is a closed-source reference UI, and external developers are free to build their own.
- Schema `$id` switched from `https://proofs.africa/ns/participant/schema-2026-05-13.json` (which 404'd) to `https://raw.githubusercontent.com/africanproofs/apregister/main/assets/participant.schema.json` (HTTP 200, the canonical source). JSON-Schema `$id`-based reference resolution now works for tooling that follows the spec.

Pending (Phase 1 still in flight): `forge verify-contract` for `0xd523…A171C` (ParticipantRegister) and `0xF2F2BF…87F3a` (FlareIdentityAdapter) on Flarescan/Routescan and Sourcify. Until verified, the deployed bytecode-to-source mapping rests on AP's commit history.

## 2026-05-12 PM — `flare:tools[]` schema + Flare-mainnet docs sweep
- `assets/participant.schema.json` — added `flare:tools[]` for public ecosystem services (RPCs, dashboards, explorers, faucets, bridges, subgraphs, analytics, dev tools, educational sites). 12-value category enum. `$id` bumped to `schema-2026-05-13.json`.
- `flare:rpc[]` array marked DEPRECATED (still validates; new JSONs should use `flare:tools[]` with `category: "rpc"`).
- `assets/participant.template.json` — adds two illustrative `flare:tools[]` entries; drops the legacy `flare:rpc[]` block.
- `types/participant.d.ts` regenerated from current schema (adds `flare:tools[]`, `flare:networks[]`, `flare:participant-type`, `flare:participant-type-label`; marks `flare:rpc[]` + `flare:services` deprecated).
- `docs/register.md`, `docs/manage.md`, `docs/index.md`, `docs/integrate.md` — CLI snippets and contract tables now lead with Flare mainnet examples; Coston2 retained as "test first" call-out.
- 59 tests passing (unchanged — schema is data, not contract logic).

## 2026-05-12 — Flare mainnet clean-slate redeploy + audit Prior #2 fix
- **`FlareIdentityAdapter` patched.** `isRegisteredIdentity` switched from O(n) linear scan over `IVoterRegistry.getRegisteredVoters(epoch)` to direct O(1) `IVoterRegistry.isVoterRegistered(addr, epoch)` lookup. Decouples adapter cost from Flare's `maxVoters` governance parameter. Same fail-closed semantics. Audit Prior #2 finding addressed (contract-auditor pass, 2026-05-12).
- `IVoterRegistry.sol` — adds `isVoterRegistered(address,uint256)` interface declaration. `getRegisteredVoters` kept for backward compatibility (`script/PreDeployProbe.s.sol` still uses it).
- Adapter runtime size: 1,385 → 1,253 bytes (loop body deleted).
- **Flare mainnet redeployed.** New `ParticipantRegister` at `0xd523159981a545dA5C53Ddbba327A5E6438A171C`, new `FlareIdentityAdapter` at `0xF2F2BF535A14b908d599845968C150abE3987F3a`. Starts with **zero registrations** — no AP self-registration on the new contract; directory is genuinely empty. Replaces `0x8d083e…` (orphaned with 8 AP self-validation records pre-announce).
- 59 tests passing (55 unit/fuzz + 4 fork against live Flare via patched adapter).

## 2026-05-10 — FlareIdentityAdapter P0 fix (pre-mainnet)
- **Critical fix.** `FlareIdentityAdapter.isRegisteredIdentity` previously called `EntityManager.getDelegationAddressOfAt(who, currentEpoch)` and treated a non-zero return as proof of identity. Verified live: `EntityManager.getDelegationAddressOfAt` echoes its input when no separate delegation is registered, so the gate would have admitted **any non-zero address** to register as Provider on Flare mainnet.
- Adapter rewritten to call `VoterRegistry.getRegisteredVoters(currentRewardEpochId)` and check membership for `who`. The voter set is the canonical Flare-FSP identity oracle.
- New interface `src/IVoterRegistry.sol`. Removed `src/IEntityManager.sol` (no longer referenced).
- New fork test `test/FlareIdentityAdapter.fork.t.sol` — runs against live Flare RPC; verifies AP identity passes, `0xdead` / FCR address / zero all reject.
- Gas: ~300k per Provider gate check (vs ~90k for the broken version). Acceptable — Provider registration is a one-shot per identity per JSON change.
- 59 tests passing (55 unit/fuzz + 4 fork). Audit re-run on the rewritten adapter required before mainnet deploy.

## 2026-05-07 — Identity gate + AgenticAI type
- `ParticipantRegister` now reverts `IdentityNotRegistered()` when registering as `Provider` (`participantType == 0`) from a wallet not in the configured `IIdentityRegistry`. All other types remain open.
- Constructor now takes `address _identityRegistry`, stored as immutable. Coston2 deploy passes `MockIdentityRegistry`; Flare deploy will pass a new `FlareIdentityAdapter` that wraps `FlareContractRegistry → EntityManager → FlareSystemsManager`.
- `ParticipantType` slot 7 renamed `Reserved7` → `AgenticAI`. AI agents in the Flare ecosystem are a first-class category; not identity-gated.
- New `IIdentityRegistry`, `IFlareContractRegistry`, `IEntityManager`, `IFlareSystemsManager` interfaces. New `FlareIdentityAdapter` contract.
- 55 tests passing (47 unit + 4 fuzz + 4 new gate/AgenticAI). `contract-auditor` agent: 0 Critical / 0 High / 0 Medium.
- Coston2 redeployed at `0x09f15b14D16BA645661c576348E4d4C201242bF2`. Old `0xF9fDB222...` orphaned.

## 2026-04-28 — Coston2 clean-slate redeployment
- Redeployed `ParticipantRegister` to Coston2 at `0xF9fDB222FCa62B50a0d94C1F31650a4034b60B12`
- Redeployed `MockIdentityRegistry` to Coston2 at `0xf77C24aFAC992CE17fFe2a01b642d1CE5d025D9e`
- Re-seeded mock registry with 11 identities (10 HD-derived + AP master)
- Same Solidity bytecode as the prior deploy — ABI/types unchanged
- Old contracts (`0xfD4C0144…`, `0xd1f8a7c3…`) remain on-chain but are deprecated; ignore for all purposes

## 2026-04 — Coston2 testnet deployment (deprecated)
- Deployed `ParticipantRegister` to Coston2 at `0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE`
- 48 tests passing (44 unit + 4 fuzz)
- AP registered as participant #1
- Internal review: zero Critical/High/Medium findings

## Schema

- 2026-04: `flare:brand` nested object replaces flat `logoLight`/`logoDark`/`icon` fields
