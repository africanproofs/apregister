# Overview

A permissionless on-chain directory of Flare network participants. Register your address, point at a JSON file with your name and metadata, and downstream tools — explorers, dashboards, wallets, indexers — discover you automatically.

No admins, no PRs, no review process. The contract takes anyone's `(participantType, infoURI)` from `msg.sender`.

## What you'll need

- A wallet with FLR (or C2FLR for testnet). Registration costs ~$0.01.
- One JSON file you can host at a public URL.
- 5 minutes.

## Pick a path

**[Register via the portal](https://register.proofs.africa/new)** — most participants. Connect your wallet, fill the form, sign. Autofills from existing FTSO catalog data when available.

**[Register via CLI](./register.md)** — power users, scripted deploys. One `cast send`.

Both paths target the same contract.

## Networks

| Network | Chain ID | Contract |
|---|---|---|
| Flare | 14 | TBD |
| Songbird | 19 | TBD |
| Coston2 (testnet) | 114 | `0xfD4C0144f4F5E52e55b4E828aC904842C31b3BDE` |

## Then what

Your registration is live the moment the transaction confirms. Edit your JSON file to update metadata — no second transaction needed. See [Manage your listing](./manage.md) for changes and deactivation.
