# Overview

A permissionless on-chain directory of Flare network participants. Register your address, point at a JSON file with your name and metadata, and downstream tools — explorers, dashboards, wallets, indexers — discover you automatically.

No admins, no PRs, no review process. The contract takes anyone's `(participantType, infoURI)` from `msg.sender`.

## What you'll need

- A wallet with C2FLR for testnet (free from the [Coston2 faucet](https://faucet.flare.network/coston2)) — registration costs ~$0.01 on mainnet.
- One JSON file you can host at a public URL.
- 5 minutes.

## Pick a path

**[Register via the portal](https://registerc2.proofs.africa/new)** — most participants. Connect your wallet, fill the form, sign. Autofills from existing FTSO catalog data when available.

**[Register via CLI](./register.md)** — power users, scripted deploys. One `cast send`.

Both paths target the same contract.

> **Currently on Coston2 testnet.** Flare mainnet deployment is pending. The portal at `registerc2.proofs.africa` lets you try the full flow risk-free. The `register.proofs.africa` domain will replace it at mainnet flip.

## Networks

| Network | Chain ID | Contract |
|---|---|---|
| Flare | 14 | TBD |
| Songbird | 19 | TBD |
| Coston2 (testnet) | 114 | `0xF9fDB222FCa62B50a0d94C1F31650a4034b60B12` |

> **Provider registrations are identity-gated.** Registering as type `0` (Provider) requires connecting from your FSP identity wallet. All other types (including the new AgenticAI type `7`) are open to any wallet. See [Errors](./errors.md).

## Then what

Your registration is live the moment the transaction confirms. Edit your JSON file to update metadata — no second transaction needed. See [Manage your listing](./manage.md) for changes and deactivation.
