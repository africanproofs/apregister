// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * Single-method registry interface for "is `who` a registered provider
 * identity on this chain?". MockIdentityRegistry implements this directly
 * (Coston2). On Flare, FlareIdentityAdapter wraps
 * FlareContractRegistry / VoterRegistry / FlareSystemsManager behind the
 * same shape.
 *
 * apregister depends only on this interface — no chainid branches, no
 * external addresses hardcoded in the registry contract itself.
 */
interface IIdentityRegistry {
    function isRegisteredIdentity(address who) external view returns (bool);
}
