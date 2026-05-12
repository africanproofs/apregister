## Summary

<!-- What this PR changes, in one sentence. -->

## Motivation

<!-- Why this change is needed. Link to the issue if there is one. -->

## Scope

<!-- One of:
     - Docs / metadata only (no contract change)
     - Tests only
     - Contract source (REQUIRES discussion in an issue first; see CONTRIBUTING.md)
     - Deployment scripts / Foundry setup
     - Other (specify)
-->

## Testing

- [ ] `forge test` — all tests pass locally
- [ ] If contract source changed: `forge test --gas-report` — no surprise gas regression
- [ ] If contract source changed: added new tests covering the change
- [ ] If schema (`assets/participant.schema.json`) changed: regenerated `types/participant.d.ts` and `abi/*.json` via `bash scripts/check-drift.sh`; both committed

## Backward compatibility

<!-- Does this break existing on-chain registrations? Existing consumers reading the ABI? Existing JSON-LD files? -->

## Checklist

- [ ] Read and followed `CONTRIBUTING.md`
- [ ] No `Co-Authored-By` lines in commits (per project authorship policy)
- [ ] No secrets / private keys in changed files
- [ ] Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)
- [ ] CI `drift` job passes (types/ + abi/ match canonical sources)

---

**Security-sensitive?** Do not open this PR publicly. DM @khosimorafo on Telegram (https://t.me/khosimorafo) first.
