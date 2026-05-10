# Emergency cutover playbook

Recovery procedure for a broken `ParticipantRegister` deployment on Flare mainnet. Read this before running it; the contract is **immutable**, so the only fix to a wrong-on-chain state is "redeploy and migrate."

## When to invoke

Run this playbook if any of the following is true on Flare mainnet:

1. **Provider gate misbehaves.** Wallets that should pass `isRegisteredIdentity` are rejected, or wallets that should not are admitted. Verify with the live-Flare fork test (`forge test --match-contract FlareIdentityAdapterForkTest --fork-url $FLARE_RPC`) before declaring a cutover. False alarms have happened — don't redeploy unless reproduced.
2. **`FlareContractRegistry` resolution is broken.** FCR returns `address(0)` for `VoterRegistry` or `FlareSystemsManager`, or returns a wrong address that resolves to a non-VoterRegistry contract. This would only happen on a Flare protocol-level upgrade that breaks the names; check Flare's release notes first.
3. **Critical security finding** in the deployed `ParticipantRegister.sol` itself (not the adapter). Cutover is the only path because the contract has no admin, no pause, no upgrade.
4. **Wrong identity registry address pinned in the constructor.** E.g., the deployer accidentally passed the wrong `IDENTITY_REGISTRY` env var and the contract is now wired to a stale or wrong adapter.

## What this playbook does NOT cover

- **Frontend bugs.** The portal at `register.proofs.africa` is in `apregister-web/` and deploys via Netlify CLI. Roll back via `netlify rollback` or `npm run deploy` from a known-good commit. The contract stays live.
- **infoURI host outages.** A provider's metadata host going down is a provider-level concern, not a registry-level one. The on-chain record is fine; their JSON is unreachable.
- **Supabase mirror drift.** Re-run `npm run reconcile:check` from `apregister-web/` and the day-1 backfill script. Contract is fine; mirror just resyncs.

## Roles

- **Owner.** Khosi Morafo (`khosimorafo@yahoo.com`). Single point of decision.
- **Deployer wallet.** AP master key. Funded with FLR. Same key that deployed Coston2.
- **Comms.** AP X/Twitter (`@africanproofs` via `apsocial/`). GitLab issue + GitHub issue. Email blast to known FSP integrators if the registry has > ~5 active providers.

## Pre-flight (before any redeploy)

Reproduce the failure deterministically. Cutover SHA on the deploy log will be what's printed by Foundry; record it.

```bash
cd apregister
git status -uno                                # confirm clean tree
git log --oneline -5                           # confirm HEAD matches what you intend to deploy
./forge.sh test                                # 55 + 4 fork tests must pass
forge test --match-contract FlareIdentityAdapterForkTest --fork-url $FLARE_RPC -vvv
                                               # explicitly re-run fork tests; capture output
```

If fork tests fail, that is the failure. Capture the output. Decide whether the issue is in the adapter (rewrite + retest) or in Flare's protocol contracts (file with Flare; do not redeploy until upstream fixed).

## Step 1 — Snapshot live state

Before deploying anything new, snapshot the current registry's contents so we can replay them on the new contract.

```bash
# From a Flare RPC-enabled shell. Save the participant array.
cast call <CURRENT_REGISTER> "getActiveParticipants()(address[])" --rpc-url $FLARE_RPC \
  > /tmp/snapshot-active.txt

# For each, fetch the full struct.
for addr in $(cast call <CURRENT_REGISTER> "getActiveParticipants()(address[])" --rpc-url $FLARE_RPC | tr -d '[]' | tr ',' '\n'); do
  cast call <CURRENT_REGISTER> "getParticipant(address)" "$addr" --rpc-url $FLARE_RPC
done > /tmp/snapshot-records.txt
```

Also pull the events log via Flare's block explorer (or `cast logs`) for `ParticipantRegistered` and `ParticipantUnregistered` from the deploy block to current. This is the audit trail.

## Step 2 — Deploy the fix

If the bug was in `FlareIdentityAdapter`:

```bash
cd apregister
# Fix code, write tests covering the failure mode, run forge test + fork tests.
# Then deploy a new adapter:
FCR_ADDRESS=0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019 \
  ./forge.sh script script/DeployFlareIdentityAdapter.s.sol \
    --rpc-url $FLARE_RPC --broadcast --private-key $PRIVATE_KEY
# Capture the new adapter address.
```

If the bug was in `ParticipantRegister.sol` itself, the new ParticipantRegister deploy follows. Either way, you need a new `ParticipantRegister`:

```bash
IDENTITY_REGISTRY=<new-or-existing-adapter-address> \
  ./forge.sh script script/Deploy.s.sol \
    --rpc-url $FLARE_RPC --broadcast --private-key $PRIVATE_KEY
# Capture the new ParticipantRegister address. Note: gas ~0.005 FLR.
```

Verify post-deploy:

```bash
cast call <NEW_REGISTER> "identityRegistry()(address)" --rpc-url $FLARE_RPC
# Expect the new adapter address (or unchanged adapter if only ParticipantRegister was redeployed).
cast call <NEW_REGISTER> "participantCount()(uint256)" --rpc-url $FLARE_RPC
# Expect 0 — fresh contract.
```

## Step 3 — Cutover the frontend

1. Update Netlify env in production context:
   ```bash
   netlify env:set NEXT_PUBLIC_REGISTER_FLARE <NEW_REGISTER> --context production --site bdb19272-2d5a-49d3-9bfa-b2310f00d003
   ```
2. Trigger redeploy from `apregister-web/`:
   ```bash
   cd apregister-web
   npm run deploy
   ```
3. Smoke test: open `https://register.proofs.africa/lookup`. Expect empty list (new contract). Connect AP identity wallet, navigate to `/new`, confirm Provider radio is enabled (gate works against new contract).

## Step 4 — Re-publish records

For every active participant from the snapshot, contact them (or self-register on AP's behalf for AP-controlled records) to re-register on the new contract.

Self-registrations AP can do without coordination:
- AP master identity → register as Provider with the AP `participant.json` URL.
- AgenticAI / Wallet / Tool slots controlled by AP can be re-registered from the same wallets.

For third-party records, send a templated message:
```
Subject: [African Proofs] apregister redeploy — please re-register

Hi <provider>,

We redeployed apregister to Flare mainnet at <NEW_REGISTER> on <DATE>
following <reason>. The previous contract at <OLD_REGISTER> is now
deprecated; its records are stale.

Please re-register at https://register.proofs.africa using the same
identity wallet you used originally. Your participant.json at <infoURI>
does not need to change.

Reply to this email if you'd like AP to register on your behalf using a
prior signed authorization.

— AP team
```

## Step 5 — Document & comms

1. Add a CHANGELOG entry to `apregister/CHANGELOG.md` with date, root cause, new addresses.
2. Update `README.md` Deployments table with the new Flare address (replace the old).
3. Update `docs/integrate.md` Contract table.
4. Update root `proofs.africa/CLAUDE.md` Constants table (the Flare ParticipantRegister row, when it exists).
5. Update `apregister-web/CLAUDE.md` (the contract address row).
6. Tag a new release (`v1.x.0` or `v1.0.x` depending on severity) and push to GitHub.
7. Announce via:
   - X/Twitter post via `apsocial/` MCP tools.
   - GitHub issue (post-mortem, public).
   - Direct email to known integrators.

## Step 6 — Mark old records inactive (optional)

The old ParticipantRegister still exists on-chain forever. Anyone who calls `unregister()` from their identity wallet on the old contract can mark themselves inactive — but most people will simply not interact with it again. AP cannot bulk-unregister others' records (no admin). Indexers should switch to reading the new address.

The old contract's `getActiveParticipants()` will continue to show stale-but-active records. Document this in the post-mortem and rely on integrators to follow the new address.

## Decision tree summary

```
Reproduce bug via fork test
├── Bug confirmed in adapter
│   └── Fix adapter → new tests → audit → deploy new adapter → optional new ParticipantRegister
├── Bug confirmed in ParticipantRegister
│   └── Fix → tests → audit → deploy new ParticipantRegister (reuse adapter if intact)
├── Bug in Flare protocol contracts
│   └── File upstream; do NOT redeploy; wait for Flare fix
└── False alarm (not reproducible)
    └── Document the report; do not redeploy
```

## SLAs

- **Reproduce + decide path**: within 4 hours of report.
- **Audit re-run on changed contracts**: same-day if change ≤ 50 LOC, otherwise next-day.
- **Deploy + frontend cutover**: within 24 hours of audit greenlight.
- **Comms**: within 1 hour of cutover.
- **Re-registration window for third parties**: 14 days; old contract treated as decommissioned after.

## Why this is intentionally heavy

The contract is immutable and trustless. That's a feature — no admin can rug, no upgrade can introduce a backdoor. The cost is that recovery requires this playbook. Every step here exists because the alternatives (an upgrade proxy, an admin pause, a migration function) would compromise the trustless posture more than they would help with the rare cutover case.

## Appendix — Contact

- AP master identity (Flare): `0x26534aC74153E3257dDD3471f96faA33D5D3B575`
- Security disclosure: `security@proofs.africa`
- Public issue tracker: `github.com/africanproofs/apregister/issues`
