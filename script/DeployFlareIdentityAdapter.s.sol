// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import {FlareIdentityAdapter} from "../src/FlareIdentityAdapter.sol";

/// @notice Deploy FlareIdentityAdapter for Flare mainnet.
/// @dev Usage:
///   FCR_ADDRESS=0x... forge script script/DeployFlareIdentityAdapter.s.sol \
///     --rpc-url $FLARE_RPC --broadcast --private-key $PRIVATE_KEY
///
/// Defaults FCR_ADDRESS to the Flare mainnet FlareContractRegistry.
/// After deploy, pass the adapter address as IDENTITY_REGISTRY to Deploy.s.sol.
contract DeployFlareIdentityAdapter is Script {
    function run() external {
        address fcr = vm.envOr("FCR_ADDRESS", address(0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019));
        vm.startBroadcast();
        FlareIdentityAdapter adapter = new FlareIdentityAdapter(fcr);
        vm.stopBroadcast();
        console.log("FlareIdentityAdapter deployed at:", address(adapter));
    }
}
