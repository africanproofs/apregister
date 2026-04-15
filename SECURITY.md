# Security Analysis — Minimised Attack Surface

Applying the same design-by-removal framework used for the AP Bond Pool contract.

---

## What This Contract Does (5 Core Functions)

1. Register a participant with metadata (msg.sender only)
2. Update a registration (re-calling register())
3. Unregister (set active = false, data retained)
4. Read participant data (by voter address, by delegation address, paginated)
5. Check registration status and count

**No financial operations. No tokens. No balances. No external calls.**

---

## What's Already Eliminated by Design

| Attack Vector | Status | Why |
|---|---|---|
| Reentrancy | **Eliminated** | Zero external calls. No ETH transfers. No token transfers. Only storage reads/writes |
| Flash loans | **Eliminated** | No financial operations. No tokens. No balances to manipulate |
| Oracle manipulation | **Eliminated** | No oracle dependency |
| Approval exploits | **Eliminated** | No ERC-20. No approval mechanism |
| Integer overflow | **Eliminated** | Solidity 0.8.20 built-in checks. Only arithmetic: index increment, offset/limit |
| Access control bypass | **Eliminated** | Only `msg.sender` can register/unregister themselves. No admin. No roles. No ownership |
| Upgrade attacks | **Eliminated** | No proxy. Immutable contract |
| External call exploits | **Eliminated** | Zero external calls |
| Front-running | **Not applicable** | Registration is msg.sender-bound. Can't register AS someone else |
| Donation attacks | **Eliminated** | No balance tracking. No tokens |
| Fund locking | **Eliminated** | No funds held. No payable functions. No receive/fallback |

**11 of 11 standard financial attack vectors are eliminated.** This contract holds zero value.

---

## Griefing Vectors (Non-Financial Attacks)

This contract doesn't hold money — it holds identity metadata. The attack surface is **reputational/operational griefing**, not financial theft.

### GRIEFING-1: Delegation Address Hijacking (CRITICAL)

**The vulnerability:**

The `_delegationToVoter` reverse index maps one delegation address to one voter. If two providers register with the same delegation address, the second overwrites the first:

```
1. Provider A registers with delegation = 0xAAAA (their real delegation address)
2. Attacker registers with delegation = 0xAAAA (claims A's delegation address)
3. getByDelegationAddress(0xAAAA) now returns the attacker's record
4. Tools using delegation-based lookup show wrong provider name/logo for 0xAAAA
```

**Impact:** Tools like flaremetrics.io or Bifrost Wallet that look up providers by delegation address would display the attacker's name/logo instead of the real provider's. Provider A appears to have been replaced.

**Why it exists:** The contract doesn't validate that msg.sender actually controls the delegation address. It's a self-reported claim.

**Mitigations (choose one):**

| Option | Approach | Trade-off |
|---|---|---|
| **A: Cross-reference EntityManager** | Call `EntityManager.getDelegationAddressOfAt()` to verify the delegation address belongs to msg.sender | Adds external call dependency. EntityManager address must be hardcoded or configurable. Breaks permissionless purity |
| **B: Require signature from delegation address** | Require a signed message from the delegation address proving consent | Complex UX (provider must sign with two keys). But fully on-chain verification |
| **C: Only allow delegation == msg.sender or delegation == address(0)** | Simplest. Provider registers with their own address or no delegation | Breaks the use case — delegation address IS different from voter address by design |
| **D: Document and accept** | Tools should cross-reference delegation claims against EntityManager independently | Weakest. Relies on every tool doing validation |
| **E: First-claim priority** | Once a delegation address is claimed, no other address can claim it until the current claimant releases it | Simple. Prevents hijacking. But legitimate delegation transfers become harder |

**Recommendation: Option E (first-claim priority) + document for tools to cross-reference.** Add a check:

```solidity
if (delegation != address(0)) {
    address existingClaim = _delegationToVoter[delegation];
    if (existingClaim != address(0) && existingClaim != msg.sender) {
        revert DelegationAlreadyClaimed();
    }
    _delegationToVoter[delegation] = msg.sender;
}
```

This prevents hijacking while maintaining the permissionless design. If a delegation address changes hands (EntityManager update), the old claimant must unregister or update first.

---

### GRIEFING-2: Spam Registration (MODERATE)

**The vulnerability:**

Anyone can register. No cost beyond gas (~50K-100K gas per registration). An attacker could register hundreds of fake providers, polluting the `_index` array:

- `getAllParticipants()` returns mostly garbage
- `getActiveParticipants()` iterates over garbage entries
- `getParticipants()` pagination returns fake entries alongside real ones
- Tools consuming the registry must filter noise

**Impact:** Data quality degradation. Registry becomes unreliable without additional filtering.

**Mitigations:**

| Option | Approach | Trade-off |
|---|---|---|
| **A: Registration fee** | Require a small FLR deposit (1-10 FLR) refunded on unregister | Adds payable + balance tracking. Increases complexity. But effective spam filter |
| **B: Minimum gas price** | No — this doesn't help. Spam is cheap at any gas price on Flare |
| **C: Rate limiting** | Limit registrations per block/epoch. Complex. Gaming-prone |
| **D: Accept and filter off-chain** | Tools filter by cross-referencing with EntityManager (only show providers registered in EntityManager). Registry is permissionless; filtering is the tool's job |

**Recommendation: Option D (accept and filter off-chain).** The registry is a permissionless data layer. Tools should cross-reference with EntityManager to filter legitimate providers. Adding a fee or rate limit compromises the permissionless design for a griefing attack that tools can handle independently.

**Document this explicitly:** tools consuming this registry MUST cross-reference with EntityManager or other on-chain sources to filter legitimate participants.

---

### GRIEFING-3: Name Squatting (LOW)

**The vulnerability:**

An attacker registers as "African Proofs" or "Flare Foundation" before the real entity does. No name uniqueness check. No dispute mechanism.

**Impact:** Brand confusion. Tools display the attacker's record under a stolen name.

**Mitigations:**

| Option | Approach | Trade-off |
|---|---|---|
| **A: Name uniqueness** | Reject duplicate names | What about legitimate name changes? Case sensitivity? Unicode tricks? Complex |
| **B: Accept and rely on cross-reference** | Tools should match voter address against EntityManager, not trust the name field | Simple. Already needed for GRIEFING-2 filtering |

**Recommendation: Option B.** Names are display strings, not identifiers. The voter address is the identifier. Tools should always show the voter address alongside the name, and cross-reference with EntityManager. Name squatting is annoying but not actionable without the correct voter address.

---

### GRIEFING-4: Gas DoS on getActiveParticipants() (MODERATE)

**The vulnerability:**

`getActiveParticipants()` iterates the entire `_index` array twice (count pass + collect pass). With 500+ entries (including spam), this could exceed block gas limits for on-chain callers.

`getAllParticipants()` returns the full array — same issue at scale.

**Impact:** These functions become uncallable from on-chain contracts at scale. Off-chain callers (ethers.js, web3.py) are unaffected (they use `eth_call` which doesn't have block gas limits in the same way).

**Mitigations:**

| Option | Approach | Trade-off |
|---|---|---|
| **A: Remove getActiveParticipants()** | Only provide paginated access via `getParticipants()`. Active filtering done off-chain | Breaks on-chain consumers that need the active list. But: are there any on-chain consumers? Probably not — this is a metadata registry for tools |
| **B: Add paginated getActiveParticipants(offset, limit)** | Same two-pass logic but bounded by offset/limit | More complex. The two-pass still iterates to find the offset-th active entry |
| **C: Maintain a separate active count** | Track `activeCount` in storage. Updated on register/unregister | Adds gas to every registration but makes counting O(1) |
| **D: Accept the limitation** | Document that `getActiveParticipants()` and `getAllParticipants()` are designed for off-chain consumption only. On-chain consumers use pagination |

**Recommendation: Option D + Option C.** Accept that full-list functions are off-chain only. Add `activeCount` storage variable (cheap to maintain, useful for tools).

---

### GRIEFING-5: Unbounded String Storage (LOW)

**The vulnerability:**

`name`, `description`, `url`, `logoURI`, `infoURI` have no maximum length. A malicious registrant could store megabytes in these fields, making `getParticipants()` return extremely large responses.

**Impact:** Gas cost to read grows. Marginal — the attacker pays the storage gas on write, and reads are only expensive for the caller copying large return data.

**Mitigations:**

| Option | Approach | Trade-off |
|---|---|---|
| **A: Enforce max lengths** | `require(bytes(name).length <= 64)` etc. | Adds validation code. Which lengths? Arbitrary but defensible |
| **B: Move long fields to infoURI** | Only store `name` and `delegation` on-chain. Everything else via `infoURI` JSON | Reduces on-chain storage dramatically. But tools need HTTP fetch for full metadata |
| **C: Accept** | Attacker pays storage gas. Reads are off-chain. Low impact |

**Recommendation: Option A — add reasonable max lengths.** Low implementation cost, prevents the most egregious abuse:

```solidity
uint256 private constant MAX_NAME = 64;
uint256 private constant MAX_DESCRIPTION = 512;
uint256 private constant MAX_URL = 256;
uint256 private constant MAX_LOGO_URI = 256;
uint256 private constant MAX_INFO_URI = 256;
```

---

## Summary of Recommendations

| Issue | Severity | Action | Status |
|---|---|---|---|
| GRIEFING-1: Delegation hijacking | **Critical** | Implement first-claim priority | **TODO** |
| GRIEFING-2: Spam registration | Moderate | Accept + document for tools to cross-reference | Document |
| GRIEFING-3: Name squatting | Low | Accept + tools cross-reference voter address | Document |
| GRIEFING-4: Gas DoS on full-list reads | Moderate | Add `activeCount` storage + document as off-chain only | **TODO** |
| GRIEFING-5: Unbounded strings | Low | Add max length checks | **TODO** |

### Priority Implementation Order

1. **GRIEFING-1 fix** (delegation hijacking) — must fix before deployment. This is exploitable from day one
2. **GRIEFING-5 fix** (max string lengths) — low effort, good hygiene
3. **GRIEFING-4 partial fix** (activeCount) — nice to have, helps tools
4. Document GRIEFING-2 and GRIEFING-3 in README for tool integrators

---

## Comparison: ParticipantRegister vs AP Bond Pool

| Dimension | ParticipantRegister | AP Bond Pool |
|---|---|---|
| Holds value | **No** (metadata only) | **Yes** (FLR deposits) |
| Financial attack surface | **Zero** | Reentrancy, implicit accounting, fund locking |
| Primary risk | Griefing (wrong data shown) | Theft (funds stolen) |
| External calls | Zero | Native FLR transfers only |
| Complexity | 176 lines, 1 file | ~120 lines, 1 file |
| Needs professional audit? | **No** — griefing risk only. Community review sufficient | **Yes** — at F₅/F₆ when holding $64K+ |
| Deployment urgency | Can deploy now (fixes above are enhancements, not blockers except GRIEFING-1) | June 2026 (Bond Pool launch) |

---

## Tests to Add

| Test | Covers |
|---|---|
| `test_delegationHijacking_reverts` | GRIEFING-1: second registrant can't claim existing delegation |
| `test_delegationRelease_thenReclaim` | GRIEFING-1: after unregister, delegation can be claimed by another |
| `test_maxNameLength_reverts` | GRIEFING-5: name exceeding MAX_NAME reverts |
| `test_maxDescriptionLength_reverts` | GRIEFING-5: description exceeding MAX_DESCRIPTION reverts |
| `test_maxUrlLength_reverts` | GRIEFING-5: url exceeding MAX_URL reverts |
| `test_activeCount_tracks` | GRIEFING-4: activeCount increments/decrements correctly |
| `test_manyParticipants_gasLimit` | GRIEFING-4: getActiveParticipants at 200+ entries (gas measurement) |
