# Changelog

## [Unreleased]
- ABI artifact published at `abi/ParticipantRegister.abi.json`
- TypeScript types for `participant.json` at `types/participant.d.ts`
- Integration guide at `docs/integrate.md`

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
