# Changelog

## [Unreleased]
- ABI artifact published at `abi/ParticipantRegister.abi.json`
- TypeScript types for `participant.json` at `types/participant.d.ts`
- Integration guide at `docs/integrate.md`

## 2026-04 — Coston2 testnet deployment
- Deployed `ParticipantRegister` to Coston2 at `0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE`
- 48 tests passing (44 unit + 4 fuzz)
- AP registered as participant #1
- Internal review: zero Critical/High/Medium findings

## Schema

- 2026-04: `flare:brand` nested object replaces flat `logoLight`/`logoDark`/`icon` fields
