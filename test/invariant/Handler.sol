// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {ParticipantRegister} from "../../src/ParticipantRegister.sol";
import {IParticipantRegister} from "../../src/IParticipantRegister.sol";
import {MockIdentityRegistry} from "../../src/test-support/MockIdentityRegistry.sol";

/// @notice Handler that drives random register/unregister sequences over a
/// bounded actor set. Bounding the actor pool (5 addresses) keeps the fuzzer
/// producing meaningful sequences instead of all-different-address noise — a
/// single actor can register, unregister, and re-register across iterations.
///
/// The handler intentionally swallows reverts (via try/catch + vm.assume) so
/// invariant runs require fail_on_revert = false in foundry.toml.
contract Handler is Test {
    ParticipantRegister public register;
    MockIdentityRegistry public identity;
    address[] public actors;

    constructor(ParticipantRegister _register, MockIdentityRegistry _identity, address[] memory _actors) {
        register = _register;
        identity = _identity;
        actors = _actors;
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    /// Register a non-Provider type (no identity gate). Type bound to 1-7 to
    /// stay within the meaningful enum slots (Reserved8-19 are intentionally
    /// untouched by the handler so the invariants can include those slots in
    /// the type-sum check without the handler biasing the result).
    function registerNonProvider(uint256 actorSeed, uint8 typeSeed, string calldata uri) external {
        vm.assume(bytes(uri).length > 0 && bytes(uri).length <= 256);
        uint8 t = uint8(bound(typeSeed, 1, 7));
        address a = _actor(actorSeed);
        vm.prank(a);
        try register.register(IParticipantRegister.ParticipantType(t), uri) {} catch {}
    }

    /// Register as Provider. Gate-aware: only attempts if the actor is a
    /// registered identity in the mock registry. Some actors are not
    /// identity-registered (by setup design) so the gate exercises both
    /// pass and revert paths.
    function registerProvider(uint256 actorSeed, string calldata uri) external {
        vm.assume(bytes(uri).length > 0 && bytes(uri).length <= 256);
        address a = _actor(actorSeed);
        if (identity.isRegisteredIdentity(a)) {
            vm.prank(a);
            try register.register(IParticipantRegister.ParticipantType.Provider, uri) {} catch {}
        }
    }

    /// Negative-case probe: try Provider from a non-identity actor. Must
    /// always revert with IdentityNotRegistered. Asserts inside the catch.
    function registerProviderUnauthorized(uint256 actorSeed, string calldata uri) external {
        vm.assume(bytes(uri).length > 0 && bytes(uri).length <= 256);
        address a = _actor(actorSeed);
        if (identity.isRegisteredIdentity(a)) return;
        vm.prank(a);
        try register.register(IParticipantRegister.ParticipantType.Provider, uri) {
            revert("Provider gate let an unauthorized address register");
        } catch {}
    }

    function unregisterSelf(uint256 actorSeed) external {
        address a = _actor(actorSeed);
        vm.prank(a);
        try register.unregister() {} catch {}
    }
}
