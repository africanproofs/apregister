# Changelog

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
