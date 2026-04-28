# FAQ

## Will registering as Provider get me FTSO rewards?

No. The contract treats every participant type identically. Provider rewards are governed by Flare's `FlareSystemsManager` and `RewardManager` — registering here doesn't change your reward eligibility. The `Provider` type is metadata only; downstream tools may filter by it.

## What if I lose access to my registered wallet?

Your record is locked to that wallet — only `msg.sender` can call `unregister()` or update with `register()` again. There is no admin override and no recovery path. If you lose the key, the record stays as-is forever.

To migrate to a new wallet: register a fresh entry from the new address, then call `unregister()` from the old address (if you still hold the key). Both records remain in the index — only `active=true` records appear in `getActiveParticipants()`.

## How do I migrate from the TowoLabs FTSO directory?

The portal autofills your name, logo, and description from the TowoLabs catalog when it recognizes your Flare identity address (Scenario 1). Connect from the same identity wallet you use in the TowoLabs entry, and the form pre-populates. Review the values, edit if needed, and sign.

## Can I update my listing without paying gas?

Yes — only the on-chain `(participantType, infoURI)` tuple lives in the contract. Everything else (name, logo, social links) lives in the JSON file at your `infoURI`. Edit the JSON and consumers re-fetch on next render. No transaction needed unless you change the type or the URL itself.

## Who runs this?

[African Proofs](https://proofs.africa) — an FTSO data provider on Flare/Songbird. The contract is permissionless and admin-free; no AP control over your record once registered.
