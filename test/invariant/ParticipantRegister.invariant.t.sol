// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {ParticipantRegister} from "../../src/ParticipantRegister.sol";
import {IParticipantRegister} from "../../src/IParticipantRegister.sol";
import {MockIdentityRegistry} from "../../src/test-support/MockIdentityRegistry.sol";
import {Handler} from "./Handler.sol";

/// @notice Invariants over arbitrary register/unregister sequences. Each
/// invariant catches a distinct class of bug:
///   - activeCount underflow / overflow
///   - getActiveParticipants() iteration vs activeCount drift
///   - typeCount sum drift (when a type-changing re-register fails to decrement)
///   - identityRegistry mutation (must be impossible — immutable)
///   - Stale entries in the active enumeration (active() = false but still returned)
contract ParticipantRegisterInvariantTest is Test {
    ParticipantRegister register;
    MockIdentityRegistry identity;
    Handler handler;
    address[] actors;
    address constant ADMIN = address(0xA11CE);

    function setUp() public {
        identity = new MockIdentityRegistry(ADMIN);

        // 5 actors total. 2 are identity-registered (Provider path reachable);
        // 3 are not (registerProviderUnauthorized exercises the gate-revert path).
        for (uint256 i = 0; i < 5; i++) {
            actors.push(address(uint160(0x1000 + i)));
        }
        vm.startPrank(ADMIN);
        identity.addIdentity(actors[0]);
        identity.addIdentity(actors[1]);
        vm.stopPrank();

        register = new ParticipantRegister(address(identity));
        handler = new Handler(register, identity, actors);

        targetContract(address(handler));
    }

    /// activeCount must never exceed total registrations ever made.
    function invariant_activeCount_le_participantCount() public view {
        assertLe(register.activeCount(), register.participantCount());
    }

    /// getActiveParticipants() length must equal activeCount().
    function invariant_activeArray_matches_activeCount() public view {
        assertEq(register.getActiveParticipants().length, register.activeCount());
    }

    /// Sum of getParticipantsByType(t) lengths across every enum slot must
    /// equal activeCount. Catches the bug class where a type-changing
    /// re-register decrements one type counter but skips the increment on
    /// the other (or vice versa).
    function invariant_typeIndex_sum_equals_activeCount() public view {
        uint256 sum = 0;
        // ParticipantType enum has 20 slots (0=Provider .. 19=Reserved19)
        for (uint8 t = 0; t < 20; t++) {
            sum += register.getParticipantsByType(IParticipantRegister.ParticipantType(t)).length;
        }
        assertEq(sum, register.activeCount());
    }

    /// identityRegistry is immutable — no codepath should ever mutate it.
    function invariant_identityRegistry_immutable() public view {
        assertEq(register.identityRegistry(), address(identity));
    }

    /// Every address returned by getActiveParticipants() must report
    /// active = true on getParticipant(). Catches stale-enumeration bugs.
    function invariant_getActive_only_returns_active() public view {
        address[] memory active = register.getActiveParticipants();
        for (uint256 i = 0; i < active.length; i++) {
            assertTrue(register.getParticipant(active[i]).active, "inactive address in active array");
        }
    }
}
