// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {ParticipantRegister} from "../src/ParticipantRegister.sol";

/// @notice Deploy the ParticipantRegister contract.
/// @dev Usage:
///   forge script script/Deploy.s.sol --rpc-url $SONGBIRD_RPC --broadcast --private-key $PRIVATE_KEY
///   forge script script/Deploy.s.sol --rpc-url $FLARE_RPC --broadcast --private-key $PRIVATE_KEY
contract DeployParticipantRegister is Script {
    function run() external {
        vm.startBroadcast();
        ParticipantRegister register = new ParticipantRegister();
        vm.stopBroadcast();

        console.log("ParticipantRegister deployed at:", address(register));
    }
}
