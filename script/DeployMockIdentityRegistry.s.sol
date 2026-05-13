// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {MockIdentityRegistry} from "../src/test-support/MockIdentityRegistry.sol";

/// @notice Deploy MockIdentityRegistry to Coston2.
///
/// Usage:
///   PRIVATE_KEY=... forge.sh script script/DeployMockIdentityRegistry.s.sol \
///     --rpc-url $COSTON2_RPC --broadcast
///
/// Populate the deployed contract with the 8 mock identities separately via
/// an off-chain seeding script (operator-internal, uses viem + the admin key
/// to batch-add via addIdentities).
contract DeployMockIdentityRegistry is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(pk);

        vm.startBroadcast(pk);
        MockIdentityRegistry registry = new MockIdentityRegistry(admin);
        vm.stopBroadcast();

        console.log("MockIdentityRegistry deployed at:", address(registry));
        console.log("Admin:", admin);
    }
}
