// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import { FlareIdentityAdapter } from "../src/FlareIdentityAdapter.sol";

/**
 * Fork tests for FlareIdentityAdapter against live Flare mainnet.
 *
 * Run: `forge test --match-contract FlareIdentityAdapterForkTest --fork-url $FLARE_RPC -vv`
 *      or with `forge test --fork-url flare` (resolves rpc_endpoints.flare in foundry.toml).
 *
 * Skipped silently when FLARE_RPC is unset, so the regular `forge test` run
 * stays offline.
 */
contract FlareIdentityAdapterForkTest is Test {
    address constant FLARE_FCR = 0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019;
    address constant AP_IDENTITY = 0x26534aC74153E3257dDD3471f96faA33D5D3B575;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    FlareIdentityAdapter adapter;

    function setUp() public {
        try vm.envString("FLARE_RPC") returns (string memory rpc) {
            if (bytes(rpc).length == 0) {
                vm.skip(true);
                return;
            }
            vm.createSelectFork(rpc);
            adapter = new FlareIdentityAdapter(FLARE_FCR);
        } catch {
            vm.skip(true);
        }
    }

    function test_apIdentityIsRegistered() public view {
        // AP is a registered Flare FSP entity: EntityManager returns a
        // signing-policy address distinct from the identity.
        assertTrue(adapter.isRegisteredIdentity(AP_IDENTITY), "AP identity should be a registered entity");
    }

    function test_deadAddressIsNotRegistered() public view {
        // Non-entity: EntityManager echoes the queried address, so
        // signingPolicyAddress == who -> not registered.
        assertFalse(adapter.isRegisteredIdentity(DEAD), "0xdead should not be a registered entity");
    }

    function test_zeroAddressIsNotRegistered() public view {
        assertFalse(adapter.isRegisteredIdentity(address(0)), "zero address must always be rejected");
    }

    function test_fcrAddressIsNotRegistered() public view {
        // Sanity: the FCR contract address itself is not a registered entity
        // (echo-on-miss -> distinct-from-self check fails).
        assertFalse(adapter.isRegisteredIdentity(FLARE_FCR), "FCR contract address must not pass the gate");
    }
}
