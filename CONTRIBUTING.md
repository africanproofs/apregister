# Contributing

Thanks for the interest. `apregister` is the on-chain participant registry contract for the Flare ecosystem. The contract is **live on Flare mainnet and immutable** — there is no admin, no upgrade path, no funds at risk. Changes here are documentation, tests, deployment scripts, and (rarely) a coordinated redeploy.

## Registering as a participant

You don't need a merge request. The contract is permissionless — register directly via the [portal](https://register.proofs.africa/new) (Flare mainnet) / [testnet portal](https://registerc2.proofs.africa/new) (Coston2), or by calling the contract from your tool of choice. See [`docs/register.md`](docs/register.md) for the CLI path.

## Code contributions

### Open an issue first

For anything beyond a typo, please open an issue describing what you want to change and why. The contract source is **frozen** ahead of additional mainnet usage — speculative refactors will be declined; specific bug reports are welcome.

What does **not** require an issue first:

- Typos and clarifications in `docs/`, `README.md`, `assets/*.json` annotations
- Test additions that cover existing behaviour at a finer grain
- New `docs/` pages that fill obvious gaps (e.g. a new integrator guide)
- New examples under `examples/` (TBD as the repo matures)

What **does** require an issue first:

- Any change to `src/*.sol` (the contract is live; this implies a redeploy)
- Any change to `assets/participant.schema.json` (schema versioning — bump `$id`)
- Any change to deploy scripts under `script/`
- Any change to the JSON-LD `flare:` namespace conventions

### Testing

Before submitting:

```bash
forge test -vvv             # 55 unit + fuzz tests
forge test --gas-report     # surface any gas regression
./forge.sh test             # Docker wrapper if your host has glibc < 2.33
```

For a change to deploy scripts, include the output of a Coston2 dry-run.

### What NOT to change without coordinated discussion

These are load-bearing decisions, each with a rationale captured in code comments or in commit history:

| Item | Where | Why |
|---|---|---|
| Constructor-pinned identity registry | `src/ParticipantRegister.sol` | Immutable for security. Changing the gate requires a full redeploy. |
| `IIdentityRegistry` interface shape | `src/IIdentityRegistry.sol` | Adapters depend on this single-method shape. Adding methods breaks adapters silently. |
| `MockIdentityRegistry` lives under `src/test-support/` | filesystem | Marks it as testnet-only. Never deploy this to mainnet. |
| `participantType` enum values 0–7 | `src/IParticipantRegister.sol` | On-chain values are baked into deployed bytecode + indexed in events. New types append at index 8+; never re-order. |
| `MAX_URI` length cap | `src/ParticipantRegister.sol` | Off-chain consumers assume the URL fits. Loosening requires schema bump. |
| Permissionless registration for non-Provider types | `src/ParticipantRegister.sol` | Adding gates to non-Provider types breaks the "no gatekeepers" promise. |

If a change requires touching one of these, open an issue first and we'll discuss whether a redeploy is justified.

## Branching

- `main` is the canonical source of truth. The deployed contracts on Coston2 and Flare are pinned to specific commits referenced in `README.md` § Deployments.
- Feature branches: `feat/<short-name>`. Open MRs against `main`. Squash-merge once tests pass.

## Commit messages

- Lowercase, present tense, no trailing period.
- Conventional Commits prefix appreciated: `feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`.
- Reference issues with `#<number>` when applicable.
- **No `Co-Authored-By` lines.** Authorship history is single-contributor by policy.

## Code style

- Solidity: NatSpec on every external function. Follow the existing style in `src/ParticipantRegister.sol`.
- Foundry tests: one file per feature, named `<Feature>.t.sol`.
- No `console.log` left in committed test code.

## Security

Report vulnerabilities privately to **security@proofs.africa**. See [`SECURITY.md`](SECURITY.md) for the full disclosure policy.

The contract is immutable — a confirmed vulnerability is "redeploy or live with it." We treat security reports with the corresponding seriousness.

## License

MIT. By contributing you agree to license your contribution under the same.
