// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IIdentityRegistry } from "./IIdentityRegistry.sol";
import { IFlareContractRegistry } from "./IFlareContractRegistry.sol";
import { IVoterRegistry } from "./IVoterRegistry.sol";
import { IFlareSystemsManager } from "./IFlareSystemsManager.sol";

/**
 * Flare-mainnet adapter that exposes FCR -> VoterRegistry -> FSM behind the
 * IIdentityRegistry shape. ParticipantRegister sees only the interface;
 * this contract owns the chain-specific resolution.
 *
 * Identity check semantics: `who` is treated as a registered FSP identity iff
 * `VoterRegistry.isVoterRegistered(who, currentRewardEpochId)` returns true.
 * That is the canonical "voter set" maintained by Flare's FSP.
 *
 * EntityManager.getDelegationAddressOfAt(addr, epoch) was the original
 * candidate but echoes its input when no delegation is set, so a non-zero
 * check trivially passes for any address. VoterRegistry membership is the
 * correct oracle. Earlier revisions of this adapter scanned the full voter
 * array via `getRegisteredVoters`; the direct `isVoterRegistered` lookup
 * is O(1) and decouples adapter cost from Flare's `maxVoters` parameter.
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
        try fcr.getContractAddressByName("VoterRegistry") returns (address vr) {
            if (vr == address(0)) return false;
            try fcr.getContractAddressByName("FlareSystemsManager") returns (address fsm) {
                if (fsm == address(0)) return false;
                try IFlareSystemsManager(fsm).getCurrentRewardEpochId() returns (uint24 epoch) {
                    try IVoterRegistry(vr).isVoterRegistered(who, uint256(epoch)) returns (bool isRegistered) {
                        return isRegistered;
                    } catch { return false; }
                } catch { return false; }
            } catch { return false; }
        } catch { return false; }
    }
}
