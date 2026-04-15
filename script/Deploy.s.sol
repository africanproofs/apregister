// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {ParticipantRegister} from "../src/ParticipantRegister.sol";
import {IEntityManager} from "../src/IEntityManager.sol";

/// @notice Deploy the ParticipantRegister contract.
/// @dev Usage:
///   ENTITY_MANAGER=0x134b3311C6BdeD895556807a30C7f047D99DfdC2 \
///     forge script script/Deploy.s.sol --rpc-url $FLARE_RPC --broadcast --private-key $PRIVATE_KEY
///
///   ENTITY_MANAGER=0x46C417D0760198E94fee455CE0e223262a3D0049 \
///     forge script script/Deploy.s.sol --rpc-url $SONGBIRD_RPC --broadcast --private-key $PRIVATE_KEY
///
/// EntityManager addresses:
///   Flare:    0x134b3311C6BdeD895556807a30C7f047D99DfdC2
///   Songbird: 0x46C417D0760198E94fee455CE0e223262a3D0049
contract DeployParticipantRegister is Script {
    function run() external {
        address entityManagerAddr = vm.envAddress("ENTITY_MANAGER");

        vm.startBroadcast();
        ParticipantRegister register = new ParticipantRegister(
            IEntityManager(entityManagerAddr)
        );
        vm.stopBroadcast();

        console.log("ParticipantRegister deployed at:", address(register));
        console.log("EntityManager:", entityManagerAddr);
    }
}
