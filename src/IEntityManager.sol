// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * Minimal stub of Flare's EntityManager — only the surface apregister's
 * identity gate needs.
 *
 * `getVoterAddresses(identity)` returns the entity's registered child
 * addresses (submit / submitSignatures / signingPolicy).
 *
 * ECHO-ON-MISS (load-bearing): for an UNregistered address EntityManager
 * returns the queried address itself in every field — every address is
 * implicitly its own entity. A *registered* entity returns DISTINCT
 * addresses. Hence the sound "is registered" signal is
 *   signingPolicyAddress != identity   (and != 0)
 * NOT a non-zero check (never zero) and NOT a delegation-address check
 * (audit Prior #2: getDelegationAddressOf echoes input too).
 *
 * Empirically verified on Songbird EntityManager
 * 0x46C417D0760198E94fee455CE0e223262a3D0049 (2026-05-16):
 *   0xcf3A…B575 (AP identity, registered)  -> signingPolicy 0xfB02…7604  (distinct)
 *   0xF6ca…6e29B (non-entity)              -> signingPolicy 0xF6ca…6e29B (echo)
 */
interface IEntityManager {
    struct VoterAddresses {
        address submitAddress;
        address submitSignaturesAddress;
        address signingPolicyAddress;
    }

    function getVoterAddresses(address _voter)
        external view returns (VoterAddresses memory);
}
