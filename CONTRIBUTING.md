# Contributing

## Registering as a participant

You don't need a PR. The contract is permissionless — register directly via the [portal](https://registerc2.proofs.africa/new) or [CLI](docs/register.md). No approval, no review.

## Code contributions

- Open an issue first for any non-trivial change. The contract is audit-clean and changes carry security risk.
- The Solidity source (`src/`) is frozen ahead of mainnet deployment. Bug reports welcome; speculative refactors will be declined.
- Documentation improvements (`docs/`, `README.md`, `assets/*.json`): PR directly.
- Run `forge test` (or `./forge.sh test` on glibc < 2.33) before submitting.

## Security

Report vulnerabilities to `security@proofs.africa`. Please do not open public issues for security-sensitive findings.
