// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IIdentityRegistry } from "./IIdentityRegistry.sol";
import { IFlareContractRegistry } from "./IFlareContractRegistry.sol";
import { IEntityManager } from "./IEntityManager.sol";

/**
 * Flare / Songbird adapter exposing FCR -> EntityManager behind the
 * IIdentityRegistry shape. ParticipantRegister sees only the interface;
 * this contract owns the chain-specific resolution.
 *
 * Identity semantics (corrected 2026-05-16): `who` is a registered FSP
 * identity iff it has a registered *signing policy address* in
 * EntityManager that is DISTINCT from `who` itself (and non-zero).
 *
 * Why distinct-from-self: EntityManager echoes the queried address on
 * miss — every address is implicitly its own entity, so an unregistered
 * `who` returns `who` in every field. "distinct & non-zero" is therefore
 * the sound registered/not signal; "non-zero" is meaningless (never
 * zero) and a delegation-address check is unsound (audit Prior #2:
 * getDelegationAddressOf also echoes input).
 *
 * Why signing-policy: this realigns the gate with apregister's
 * "Identity-as-signing-key (CRITICAL)" design intent — a Provider is an
 * identity that has registered its signing key, i.e. a real
 * identity-registered Flare/Songbird entity (the official
 * flare-systems-deployment REGISTRATION.md outcome). The previous
 * VoterRegistry.isVoterRegistered oracle additionally required active
 * per-reward-epoch *voter* registration (vote power / consensus
 * participation) — a stricter, divergent-purpose condition the registry
 * does not intend. Empirically verified on Songbird EntityManager
 * 0x46C417D0760198E94fee455CE0e223262a3D0049 (see IEntityManager).
 *
 * Fails closed: any RPC error / missing contract / failed read = false.
 */
contract FlareIdentityAdapter is IIdentityRegistry {
    IFlareContractRegistry public immutable fcr;

    error ZeroFCR();

    constructor(address _fcr) {
        if (_fcr == address(0)) revert ZeroFCR();
        fcr = IFlareContractRegistry(_fcr);
    }

    function isRegisteredIdentity(address who) external view returns (bool) {
        if (who == address(0)) return false;
        try fcr.getContractAddressByName("EntityManager") returns (address em) {
            if (em == address(0)) return false;
            try IEntityManager(em).getVoterAddresses(who) returns (
                IEntityManager.VoterAddresses memory v
            ) {
                address spa = v.signingPolicyAddress;
                return spa != who && spa != address(0);
            } catch {
                return false;
            }
        } catch {
            return false;
        }
    }
}
