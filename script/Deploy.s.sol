// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {ParticipantRegister} from "../src/ParticipantRegister.sol";

/// @notice Deploy the ParticipantRegister contract.
/// @dev Usage:
///   IDENTITY_REGISTRY=<addr> forge script script/Deploy.s.sol \
///     --rpc-url $FLARE_RPC --broadcast --private-key $PRIVATE_KEY
///
/// IDENTITY_REGISTRY is required. Set to the MockIdentityRegistry address on
/// Coston2, or the FlareIdentityAdapter address on Flare/Songbird mainnet.
contract DeployParticipantRegister is Script {
    function run() external {
        address registry = vm.envAddress("IDENTITY_REGISTRY");
        vm.startBroadcast();
        ParticipantRegister register = new ParticipantRegister(registry);
        vm.stopBroadcast();

        console.log("ParticipantRegister deployed at:", address(register));
    }
}
