---
name: Feature request
about: Propose a new feature, doc, or integration improvement
title: ''
labels: enhancement
assignees: ''
---

## Problem

<!-- What's missing? Who is affected? Why does this matter now? -->

## Proposed solution

<!-- What would solve the problem. -->

## Alternatives considered

<!-- What else did you think about, and why is the proposal better? -->

## Impact on existing users

<!-- Will this require a contract redeploy? A schema bump? Breaking change to the JSON-LD shape? -->

## Compatibility

<!-- Does this require coordinated changes in downstream consumers (indexers, wallets, the reference portal)? -->

## Out of scope

<!-- What this proposal explicitly does NOT cover. -->

---

The contract is **immutable** — once deployed, the bytecode cannot change. New features either require a redeploy (with all that entails — migration of records, new address, new ecosystem advertising) or must be implementable as an off-chain convention layered on top of the existing `(participantType, infoURI)` tuple. Flag which mode you're proposing.
