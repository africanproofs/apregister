// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {IParticipantRegister} from "../src/IParticipantRegister.sol";

/// @notice Register African Proofs as a participant on an existing contract.
/// @dev Usage:
///   forge script script/Register.s.sol --rpc-url $COSTON2_RPC --broadcast --private-key $PRIVATE_KEY
contract RegisterAP is Script {
    function run() external {
        address register = vm.envAddress("REGISTER_ADDRESS");
        string memory infoURI = vm.envString("INFO_URI");

        vm.startBroadcast();
        IParticipantRegister(register).register(
            IParticipantRegister.ParticipantType.Provider,
            infoURI
        );
        vm.stopBroadcast();

        console.log("Registered at:", register);
        console.log("infoURI:", infoURI);
    }
}
