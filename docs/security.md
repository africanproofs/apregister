# Security Posture

apregister is designed to minimise what you have to trust. This page states
what the contract guarantees, what it deliberately does **not** guarantee,
how to consume the registry safely, and the limits of the review it has had.
It is intentionally about properties you can verify yourself — not assurances
you have to take on faith.

## What the contract guarantees (independently verifiable)

- **Immutable.** No admin, no owner, no upgrade path, no pause. The
  identity-registry dependency is constructor-pinned and `immutable`.
  Changing anything requires a brand-new deployment, announced in the open.
- **Holds no value.** The contract rejects native transfers; it cannot
  custody or move funds.
- **Minimal trust surface.** No proxy, no `delegatecall`. The only external
  call is a single `view` lookup to the constructor-pinned identity adapter,
  and it **fails closed** — any error or resolution failure denies the
  Provider gate, never grants it.
- **Source-verified.** Deployed bytecode is `exact_match` (creation **and**
  runtime) on Sourcify, with verified source also on Flarescan and the Flare
  block explorer, for both `ParticipantRegister` and its pinned
  `FlareIdentityAdapter`. Confirm the addresses in
  [README → Deployments](../README.md#deployments) yourself.
- **Permissionless & self-custodial.** You register and update your own
  record from your own address; no one can register, alter, or remove it for
  you. Deactivation never deletes data.

These properties were reviewed against the standard smart-contract
vulnerability catalogue (reentrancy, access control, arithmetic,
upgrade/initialisation, signatures/replay, economic/MEV, storage). The
contract's mutable bookkeeping is covered by a property-based invariant
suite in this repository.

## What the gate does NOT prove — read this

The Provider type (slot 0) is gated by **Flare EntityManager identity
registration**. Passing the gate proves the registering address completed
Flare's EntityManager entity / signing-policy registration. It does **not**,
on its own, prove:

- that the entity is a reward-eligible, active, or community-recognised
  FTSO provider;
- that the off-chain `participant.json` is accurate, or controlled by whom
  it claims;
- continued identity status — the gate is evaluated at the moment
  `register()` is called, not continuously.

**Treat the registry as identity-gated discovery, not vetting or
endorsement.** If you build on it:

- re-verify identity **live against the chain**; do not trust a stored type
  as a current assertion;
- treat each provider's `participant.json` as **untrusted,
  provider-controlled** content fetched from a third-party host;
- read via pagination (`getParticipants(offset, limit)`) rather than relying
  on unbounded enumeration as the registry grows;
- treat the on-chain contract as the source of truth; treat any portal,
  mirror, or index as a convenience over it.

## Review status & limitations

The contract and the wider system have had **adversarial internal review**
by African Proofs. There has been **no third-party human audit**; an
external audit is on the roadmap before significant value or reliance flows
through the registry. Internal review is not a substitute for an independent
audit.

The contract's guarantees above **do not extend to any off-chain surface** —
the reference portal, hosting, infrastructure, or provider-hosted metadata
each carry operational risk that is independent of the contract and subject
to ongoing hardening. This is precisely why the power-user path exists: the
contract is the API, and you can register and read with one transaction and
one self-hosted JSON file, trusting no intermediary.

Because the contract is immutable there is **no fix-forward**. A discovered
flaw is addressed by deploying a corrected contract and announcing the new
address — never by a silent change. A change of address is the trust model
working as intended, not a regression.

## Responsible disclosure

Report security issues privately via Telegram DM to `@khosimorafo`
(<https://t.me/khosimorafo>). Please do not open public issues for
security-sensitive findings. Coordinated disclosure is appreciated and
credited.
