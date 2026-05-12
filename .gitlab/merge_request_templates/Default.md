## Summary

<!-- What this MR changes, in one sentence. -->

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
- [ ] If schema (`assets/participant.schema.json`) changed: bumped `$id` AND updated consumer types in `types/participant.d.ts`

## Backward compatibility

<!-- Does this break existing on-chain registrations? Existing consumers reading the ABI? Existing JSON-LD files? -->

## Checklist

- [ ] Read and followed CONTRIBUTING.md
- [ ] No `Co-Authored-By` lines in commits (per project authorship policy)
- [ ] No secrets / private keys in changed files
- [ ] Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)

---

**Security-sensitive?** Do not open this MR publicly. Email security@proofs.africa first.
