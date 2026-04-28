# Changelog

## [Unreleased]
- ABI artifact published at `abi/ParticipantRegister.abi.json`
- TypeScript types for `participant.json` at `types/participant.d.ts`
- Integration guide at `docs/integrate.md`

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
