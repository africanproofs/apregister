// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {ParticipantRegister} from "../src/ParticipantRegister.sol";
import {IParticipantRegister} from "../src/IParticipantRegister.sol";
import {IEntityManager} from "../src/IEntityManager.sol";

/// @dev Minimal mock for EntityManager.
contract MockEntityManager {
    mapping(address => address) private _delegations;

    function setDelegation(address voter, address delegation) external {
        _delegations[voter] = delegation;
    }

    function getDelegationAddressOf(address _voter) external view returns (address) {
        return _delegations[_voter];
    }

    function getDelegationAddressOfAt(address, uint256) external pure returns (address) { return address(0); }
    function getNodeIdsOf(address) external pure returns (bytes20[] memory) { return new bytes20[](0); }
    function getNodeIdsOfAt(address, uint256) external pure returns (bytes20[] memory) { return new bytes20[](0); }
    function getPublicKeyOf(address) external pure returns (bytes32, bytes32) { return (bytes32(0), bytes32(0)); }
    function getPublicKeyOfAt(address, uint256) external pure returns (bytes32, bytes32) { return (bytes32(0), bytes32(0)); }
}

contract ParticipantRegisterTest is Test {
    ParticipantRegister private register;
    MockEntityManager private mockEntityManager;

    event ParticipantRegistered(
        address indexed owner,
        address indexed delegation,
        uint256 index,
        string infoURI
    );
    event ParticipantUnregistered(address indexed owner, uint256 index);

    address private alice = makeAddr("alice");           // provider with delegation
    address private aliceDelegation = makeAddr("aliceDelegation");
    address private bob = makeAddr("bob");               // provider with delegation
    address private bobDelegation = makeAddr("bobDelegation");
    address private protocol = makeAddr("protocol");     // protocol without delegation
    address private attacker = makeAddr("attacker");

    string private constant INFO_AP = "https://proofs.africa/participant.json";
    string private constant INFO_BOB = "https://bob.example.com/participant.json";
    string private constant INFO_PROTOCOL = "https://kinetic.market/participant.json";

    function setUp() public {
        mockEntityManager = new MockEntityManager();
        mockEntityManager.setDelegation(alice, aliceDelegation);
        mockEntityManager.setDelegation(bob, bobDelegation);
        register = new ParticipantRegister(IEntityManager(address(mockEntityManager)));
    }

    function _registerAlice() internal {
        vm.prank(alice);
        register.register(INFO_AP);
    }

    function _registerBob() internal {
        vm.prank(bob);
        register.register(INFO_BOB);
    }

    // ---------------------------------------------------------------
    // Registration
    // ---------------------------------------------------------------

    function test_register() public {
        vm.roll(100);
        _registerAlice();

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.owner, alice);
        assertEq(p.delegation, aliceDelegation);
        assertEq(p.infoURI, INFO_AP);
        assertTrue(p.active);
        assertEq(p.index, 0);
        assertEq(p.registeredAt, 100);
        assertEq(p.updatedAt, 100);
    }

    function test_register_emitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit ParticipantRegistered(alice, aliceDelegation, 0, INFO_AP);

        vm.prank(alice);
        register.register(INFO_AP);
    }

    function test_register_update() public {
        vm.roll(100);
        _registerAlice();

        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        vm.roll(200);
        vm.prank(alice);
        register.register("https://proofs.africa/v2/participant.json");

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.infoURI, "https://proofs.africa/v2/participant.json");
        assertEq(p.delegation, newDelegation);
        assertTrue(p.active);
        assertEq(p.registeredAt, 100);
        assertEq(p.updatedAt, 200);
    }

    function test_register_revertsOnEmptyURI() public {
        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.EmptyInfoURI.selector);
        register.register("");
    }

    function test_register_revertsOnUriTooLong() public {
        bytes memory longUri = new bytes(257);
        for (uint i = 0; i < 257; i++) longUri[i] = "A";

        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.UriTooLong.selector);
        register.register(string(longUri));
    }

    function test_register_exactlyAtMaxLength() public {
        bytes memory uri256 = new bytes(256);
        for (uint i = 0; i < 256; i++) uri256[i] = "A";

        vm.prank(alice);
        register.register(string(uri256));

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(bytes(p.infoURI).length, 256);
    }

    function test_register_multipleParticipants() public {
        _registerAlice();
        _registerBob();

        assertEq(register.participantCount(), 2);
        assertEq(register.getParticipant(alice).index, 0);
        assertEq(register.getParticipant(bob).index, 1);
    }

    // ---------------------------------------------------------------
    // Protocols (no EntityManager delegation)
    // ---------------------------------------------------------------

    function test_register_protocolWithoutDelegation() public {
        vm.prank(protocol);
        register.register(INFO_PROTOCOL);

        IParticipantRegister.Participant memory p = register.getParticipant(protocol);
        assertEq(p.owner, protocol);
        assertEq(p.delegation, address(0));
        assertEq(p.infoURI, INFO_PROTOCOL);
        assertTrue(p.active);
    }

    // ---------------------------------------------------------------
    // EntityManager integration
    // ---------------------------------------------------------------

    function test_delegationReadFromEntityManager() public {
        _registerAlice();
        assertEq(register.getParticipant(alice).delegation, aliceDelegation);
    }

    function test_delegationHijackingImpossible() public {
        _registerAlice();

        vm.prank(attacker);
        register.register("https://evil.com/participant.json");

        // Alice's delegation lookup still returns Alice
        IParticipantRegister.Participant memory p = register.getByDelegationAddress(aliceDelegation);
        assertEq(p.owner, alice);

        // Attacker has no delegation
        assertEq(register.getParticipant(attacker).delegation, address(0));
    }

    function test_entityManagerAddress() public view {
        assertEq(address(register.entityManager()), address(mockEntityManager));
    }

    // ---------------------------------------------------------------
    // refreshDelegation
    // ---------------------------------------------------------------

    function test_refreshDelegation() public {
        _registerAlice();

        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        vm.prank(bob);
        register.refreshDelegation(alice);

        assertEq(register.getParticipant(alice).delegation, newDelegation);
    }

    function test_refreshDelegation_updatesReverseIndex() public {
        _registerAlice();

        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        register.refreshDelegation(alice);

        // Old delegation cleared
        assertEq(register.getByDelegationAddress(aliceDelegation).owner, address(0));
        // New delegation works
        assertEq(register.getByDelegationAddress(newDelegation).owner, alice);
    }

    function test_refreshDelegation_noChange() public {
        vm.roll(100);
        _registerAlice();

        vm.roll(200);
        register.refreshDelegation(alice);

        assertEq(register.getParticipant(alice).updatedAt, 100); // unchanged
    }

    function test_refreshDelegation_revertsIfNotRegistered() public {
        vm.expectRevert(IParticipantRegister.NotRegistered.selector);
        register.refreshDelegation(protocol);
    }

    // ---------------------------------------------------------------
    // Delegation lookup
    // ---------------------------------------------------------------

    function test_getByDelegationAddress() public {
        _registerAlice();
        assertEq(register.getByDelegationAddress(aliceDelegation).owner, alice);
    }

    function test_getByDelegationAddress_afterDelegationChange() public {
        _registerAlice();

        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        vm.prank(alice);
        register.register(INFO_AP);

        assertEq(register.getByDelegationAddress(aliceDelegation).owner, address(0));
        assertEq(register.getByDelegationAddress(newDelegation).owner, alice);
    }

    function test_getByDelegationAddress_unknownReturnsEmpty() public view {
        assertEq(register.getByDelegationAddress(address(0xdead)).owner, address(0));
    }

    // ---------------------------------------------------------------
    // Unregistration
    // ---------------------------------------------------------------

    function test_unregister() public {
        vm.roll(100);
        _registerAlice();

        vm.roll(200);
        vm.prank(alice);
        register.unregister();

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertFalse(p.active);
        assertEq(p.infoURI, INFO_AP); // data retained
        assertEq(p.updatedAt, 200);
    }

    function test_unregister_emitsEvent() public {
        _registerAlice();

        vm.expectEmit(true, false, false, true);
        emit ParticipantUnregistered(alice, 0);

        vm.prank(alice);
        register.unregister();
    }

    function test_unregister_revertsIfNotRegistered() public {
        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.NotRegistered.selector);
        register.unregister();
    }

    function test_reregisterAfterUnregister() public {
        vm.roll(100);
        _registerAlice();

        vm.roll(150);
        vm.prank(alice);
        register.unregister();

        vm.roll(200);
        vm.prank(alice);
        register.register("https://proofs.africa/v2/participant.json");

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertTrue(p.active);
        assertEq(p.infoURI, "https://proofs.africa/v2/participant.json");
        assertEq(p.index, 0);
        assertEq(p.registeredAt, 100);
        assertEq(p.updatedAt, 200);
        assertEq(register.participantCount(), 1);
    }

    // ---------------------------------------------------------------
    // Active count
    // ---------------------------------------------------------------

    function test_activeCount_onRegister() public {
        assertEq(register.activeCount(), 0);
        _registerAlice();
        assertEq(register.activeCount(), 1);
        _registerBob();
        assertEq(register.activeCount(), 2);
    }

    function test_activeCount_onUnregister() public {
        _registerAlice();
        _registerBob();

        vm.prank(alice);
        register.unregister();
        assertEq(register.activeCount(), 1);
    }

    function test_activeCount_onReregister() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();
        assertEq(register.activeCount(), 0);

        vm.prank(alice);
        register.register(INFO_AP);
        assertEq(register.activeCount(), 1);
    }

    function test_activeCount_noDoubleCount() public {
        _registerAlice();
        assertEq(register.activeCount(), 1);

        vm.prank(alice);
        register.register("https://proofs.africa/v2/participant.json");
        assertEq(register.activeCount(), 1);
    }

    function test_activeCount_doubleUnregister() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();
        assertEq(register.activeCount(), 0);

        vm.prank(alice);
        register.unregister();
        assertEq(register.activeCount(), 0);
    }

    // ---------------------------------------------------------------
    // Read access
    // ---------------------------------------------------------------

    function test_getParticipant_anyoneCanRead() public {
        _registerAlice();

        vm.prank(bob);
        assertEq(register.getParticipant(alice).infoURI, INFO_AP);
    }

    function test_getParticipant_unregisteredReturnsEmpty() public view {
        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.owner, address(0));
        assertEq(bytes(p.infoURI).length, 0);
    }

    function test_getAllParticipants() public {
        _registerAlice();
        _registerBob();

        address[] memory all = register.getAllParticipants();
        assertEq(all.length, 2);
        assertEq(all[0], alice);
        assertEq(all[1], bob);
    }

    function test_getAllParticipants_empty() public view {
        assertEq(register.getAllParticipants().length, 0);
    }

    // ---------------------------------------------------------------
    // Active participants
    // ---------------------------------------------------------------

    function test_getActiveParticipants() public {
        _registerAlice();
        _registerBob();

        vm.prank(alice);
        register.unregister();

        address[] memory active = register.getActiveParticipants();
        assertEq(active.length, 1);
        assertEq(active[0], bob);
    }

    function test_getActiveParticipants_allActive() public {
        _registerAlice();
        _registerBob();
        assertEq(register.getActiveParticipants().length, 2);
    }

    function test_getActiveParticipants_noneActive() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();
        assertEq(register.getActiveParticipants().length, 0);
    }

    function test_getActiveParticipants_empty() public view {
        assertEq(register.getActiveParticipants().length, 0);
    }

    // ---------------------------------------------------------------
    // Pagination
    // ---------------------------------------------------------------

    function test_getParticipants_fullPage() public {
        _registerAlice();
        _registerBob();

        IParticipantRegister.Participant[] memory page = register.getParticipants(0, 10);
        assertEq(page.length, 2);
        assertEq(page[0].infoURI, INFO_AP);
        assertEq(page[1].infoURI, INFO_BOB);
    }

    function test_getParticipants_partialPage() public {
        _registerAlice();
        _registerBob();

        IParticipantRegister.Participant[] memory page = register.getParticipants(0, 1);
        assertEq(page.length, 1);
        assertEq(page[0].owner, alice);
    }

    function test_getParticipants_offset() public {
        _registerAlice();
        _registerBob();

        IParticipantRegister.Participant[] memory page = register.getParticipants(1, 10);
        assertEq(page.length, 1);
        assertEq(page[0].owner, bob);
    }

    function test_getParticipants_emptyRegistry() public view {
        assertEq(register.getParticipants(0, 10).length, 0);
    }

    function test_getParticipants_offsetOutOfBounds() public {
        _registerAlice();
        vm.expectRevert(IParticipantRegister.OffsetOutOfBounds.selector);
        register.getParticipants(5, 10);
    }

    // ---------------------------------------------------------------
    // isRegistered / counts
    // ---------------------------------------------------------------

    function test_isRegistered() public {
        assertFalse(register.isRegistered(alice));
        _registerAlice();
        assertTrue(register.isRegistered(alice));
        assertFalse(register.isRegistered(bob));
    }

    function test_isRegistered_afterUnregister() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();
        assertTrue(register.isRegistered(alice));
    }

    function test_participantCount() public {
        assertEq(register.participantCount(), 0);
        _registerAlice();
        assertEq(register.participantCount(), 1);
        _registerBob();
        assertEq(register.participantCount(), 2);

        vm.prank(alice);
        register.unregister();
        assertEq(register.participantCount(), 2);
    }

    // ---------------------------------------------------------------
    // Bulk
    // ---------------------------------------------------------------

    function test_manyParticipants() public {
        for (uint256 i = 0; i < 20; i++) {
            address user = makeAddr(string(abi.encodePacked("user", vm.toString(i))));
            address del = makeAddr(string(abi.encodePacked("del", vm.toString(i))));
            mockEntityManager.setDelegation(user, del);
            vm.prank(user);
            register.register(
                string(abi.encodePacked("https://example.com/", vm.toString(i), "/participant.json"))
            );
        }

        assertEq(register.participantCount(), 20);
        assertEq(register.activeCount(), 20);

        IParticipantRegister.Participant[] memory page1 = register.getParticipants(0, 10);
        IParticipantRegister.Participant[] memory page2 = register.getParticipants(10, 10);
        assertEq(page1.length, 10);
        assertEq(page2.length, 10);
    }

    function test_manyParticipants_delegationLookup() public {
        _registerAlice();
        _registerBob();
        assertEq(register.getByDelegationAddress(aliceDelegation).owner, alice);
        assertEq(register.getByDelegationAddress(bobDelegation).owner, bob);
    }
}
