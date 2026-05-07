// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IIdentityRegistry } from "./IIdentityRegistry.sol";
import { IFlareContractRegistry } from "./IFlareContractRegistry.sol";
import { IEntityManager } from "./IEntityManager.sol";
import { IFlareSystemsManager } from "./IFlareSystemsManager.sol";

/**
 * Flare-mainnet adapter that exposes FCR → EntityManager → FSM behind the
 * IIdentityRegistry shape. ParticipantRegister sees only the interface;
 * this contract owns the chain-specific resolution.
 *
 * Fails closed: any RPC error / missing contract / zero return = false.
 */
contract FlareIdentityAdapter is IIdentityRegistry {
    IFlareContractRegistry public immutable fcr;

    error ZeroFCR();

    constructor(address _fcr) {
        if (_fcr == address(0)) revert ZeroFCR();
        fcr = IFlareContractRegistry(_fcr);
    }

    function isRegisteredIdentity(address who) external view returns (bool) {
        try fcr.getContractAddressByName("EntityManager") returns (address em) {
            if (em == address(0)) return false;
            try fcr.getContractAddressByName("FlareSystemsManager") returns (address fsm) {
                if (fsm == address(0)) return false;
                try IFlareSystemsManager(fsm).getCurrentRewardEpochId() returns (uint24 epoch) {
                    try IEntityManager(em).getDelegationAddressOfAt(who, uint256(epoch)) returns (address delegation) {
                        return delegation != address(0);
                    } catch { return false; }
                } catch { return false; }
            } catch { return false; }
        } catch { return false; }
    }
}
