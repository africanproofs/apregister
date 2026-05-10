// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import { IFlareContractRegistry } from "../src/IFlareContractRegistry.sol";
import { IVoterRegistry } from "../src/IVoterRegistry.sol";
import { IFlareSystemsManager } from "../src/IFlareSystemsManager.sol";

/// @notice Pre-deploy probe — verifies the Flare contract surface the
///         FlareIdentityAdapter depends on is alive and reachable BEFORE
///         broadcasting any deploy transactions.
///
/// @dev Usage:
///   FCR_ADDRESS=0x... forge script script/PreDeployProbe.s.sol \
///     --rpc-url $FLARE_RPC
///
///   No --broadcast. Read-only.
///
///   Reverts if any check fails. A clean run prints the resolved addresses
///   and the current reward-epoch ID, plus whether the deployer's expected
///   identity (PROBE_IDENTITY env) is in the registered voter set.
///
///   Wire this as the first step of the deploy ritual:
///     1. forge script PreDeployProbe (this)        — must pass
///     2. forge script DeployFlareIdentityAdapter   — broadcast
///     3. forge script Deploy.s.sol                 — broadcast
contract PreDeployProbe is Script {
    error VoterRegistryNotResolved();
    error FlareSystemsManagerNotResolved();
    error IdentityNotInVoterSet(address probeIdentity, uint256 epoch);
    error EmptyVoterSet(uint256 epoch);

    function run() external view {
        address fcrAddr = vm.envOr("FCR_ADDRESS", address(0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019));
        IFlareContractRegistry fcr = IFlareContractRegistry(fcrAddr);

        console.log("=== Pre-deploy probe ===");
        console.log("FCR address:", fcrAddr);

        address vr = fcr.getContractAddressByName("VoterRegistry");
        if (vr == address(0)) revert VoterRegistryNotResolved();
        console.log("VoterRegistry:", vr);

        address fsm = fcr.getContractAddressByName("FlareSystemsManager");
        if (fsm == address(0)) revert FlareSystemsManagerNotResolved();
        console.log("FlareSystemsManager:", fsm);

        uint24 epoch = IFlareSystemsManager(fsm).getCurrentRewardEpochId();
        console.log("Current reward epoch:", uint256(epoch));

        address[] memory voters = IVoterRegistry(vr).getRegisteredVoters(uint256(epoch));
        console.log("Registered voters:", voters.length);
        if (voters.length == 0) revert EmptyVoterSet(uint256(epoch));

        // Optional: verify a known identity is in the voter set. Set
        // PROBE_IDENTITY to AP's canonical Flare identity to confirm AP can
        // register as Provider after deploy. Skipped if unset.
        address probe = vm.envOr("PROBE_IDENTITY", address(0));
        if (probe != address(0)) {
            bool found = false;
            for (uint256 i = 0; i < voters.length; ++i) {
                if (voters[i] == probe) { found = true; break; }
            }
            if (!found) revert IdentityNotInVoterSet(probe, uint256(epoch));
            console.log("PROBE_IDENTITY in voter set:", probe);
        }

        console.log("=== Probe OK ===");
    }
}
