# Overview

A permissionless on-chain directory of Flare network participants. Register your address, point at a JSON file with your name and metadata, and downstream tools — explorers, dashboards, wallets, indexers — discover you automatically.

No admins, no PRs, no review process. The contract takes anyone's `(participantType, infoURI)` from `msg.sender`.

## What you'll need

- A wallet with FLR on Flare mainnet — registration costs ~$0.01. (To test first, use C2FLR on Coston2 testnet, free from the [faucet](https://faucet.flare.network/coston2).)
- One JSON file you can host at a public URL.
- 5 minutes.

## Pick a path

**[Register via the portal](https://register.proofs.africa/new)** — most participants. Connect your wallet, fill the form, sign. Autofills from existing FTSO catalog data when available.

**[Register via CLI](./register.md)** — power users, scripted deploys. One `cast send`.

Both paths target the same contract.

> **Live on Flare mainnet** at `register.proofs.africa`. The contract is immutable, no admin, no funds held — see [SECURITY.md](https://github.com/africanproofs/apregister/blob/main/SECURITY.md) for the security posture.

## Networks

| Network | Chain ID | Contract |
|---|---|---|
| Flare | 14 | `0x29BA5B29C5451e7db5885A8CFE4c73Ae1A2eABe5` |
| Songbird | 19 | n/a (out of v1 scope) |
| Coston2 (testnet) | 114 | `0x09f15b14D16BA645661c576348E4d4C201242bF2` |

> **Provider registrations are identity-gated.** Registering as type `0` (Provider) requires connecting from your FSP identity wallet. All other types (including the new AgenticAI type `7`) are open to any wallet. See [Errors](./errors.md).

## Then what

Your registration is live the moment the transaction confirms. Edit your JSON file to update metadata — no second transaction needed. See [Manage your listing](./manage.md) for changes and deactivation.
