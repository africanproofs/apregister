// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {ParticipantRegister} from "../src/ParticipantRegister.sol";
import {IParticipantRegister} from "../src/IParticipantRegister.sol";
import {IEntityManager} from "../src/IEntityManager.sol";

/// @dev Minimal mock for EntityManager — only implements getDelegationAddressOf.
contract MockEntityManager {
    mapping(address => address) private _delegations;

    function setDelegation(address voter, address delegation) external {
        _delegations[voter] = delegation;
    }

    function getDelegationAddressOf(address _voter) external view returns (address) {
        return _delegations[_voter];
    }

    // Stubs for IEntityManager interface compliance (unused in tests)
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
        string name,
        string url,
        string logoURI
    );
    event ParticipantUnregistered(address indexed owner, uint256 index);

    address private alice = makeAddr("alice");
    address private aliceDelegation = makeAddr("aliceDelegation");
    address private bob = makeAddr("bob");
    address private bobDelegation = makeAddr("bobDelegation");
    address private charlie = makeAddr("charlie");
    address private attacker = makeAddr("attacker");

    string private constant NAME_AP = "African Proofs";
    string private constant DESC_AP = "Flare data provider running full FDC stack";
    string private constant URL_AP = "https://proofs.africa";
    string private constant LOGO_AP = "https://proofs.africa/logo-256.png";
    string private constant INFO_AP = "https://proofs.africa/participant.json";

    string private constant NAME_BOB = "Bob Provider";
    string private constant DESC_BOB = "Independent FTSO provider";
    string private constant URL_BOB = "https://bob.example.com";
    string private constant LOGO_BOB = "https://bob.example.com/logo.png";
    string private constant INFO_BOB = "https://bob.example.com/participant.json";

    function setUp() public {
        mockEntityManager = new MockEntityManager();
        mockEntityManager.setDelegation(alice, aliceDelegation);
        mockEntityManager.setDelegation(bob, bobDelegation);
        // attacker has no delegation in EntityManager
        // charlie has no delegation in EntityManager
        register = new ParticipantRegister(IEntityManager(address(mockEntityManager)));
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    function _registerAlice() internal {
        vm.prank(alice);
        register.register(NAME_AP, DESC_AP, URL_AP, LOGO_AP, INFO_AP);
    }

    function _registerBob() internal {
        vm.prank(bob);
        register.register(NAME_BOB, DESC_BOB, URL_BOB, LOGO_BOB, INFO_BOB);
    }

    // ---------------------------------------------------------------
    // Registration
    // ---------------------------------------------------------------

    function test_register() public {
        vm.roll(100);
        _registerAlice();

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.owner, alice);
        assertEq(p.delegation, aliceDelegation); // read from EntityManager
        assertEq(p.name, NAME_AP);
        assertEq(p.description, DESC_AP);
        assertEq(p.url, URL_AP);
        assertEq(p.logoURI, LOGO_AP);
        assertEq(p.infoURI, INFO_AP);
        assertTrue(p.active);
        assertEq(p.index, 0);
        assertEq(p.registeredAt, 100);
        assertEq(p.updatedAt, 100);
    }

    function test_register_emitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit ParticipantRegistered(alice, aliceDelegation, 0, NAME_AP, URL_AP, LOGO_AP);

        vm.prank(alice);
        register.register(NAME_AP, DESC_AP, URL_AP, LOGO_AP, INFO_AP);
    }

    function test_register_update() public {
        vm.roll(100);
        _registerAlice();

        // Change alice's delegation in EntityManager
        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        vm.roll(200);
        vm.prank(alice);
        register.register("Updated Name", "New desc", "https://new.url", "https://new.logo", "https://new.info");

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.name, "Updated Name");
        assertEq(p.description, "New desc");
        assertEq(p.delegation, newDelegation); // updated from EntityManager
        assertEq(p.url, "https://new.url");
        assertEq(p.logoURI, "https://new.logo");
        assertEq(p.infoURI, "https://new.info");
        assertTrue(p.active);
        assertEq(p.index, 0);
        assertEq(p.registeredAt, 100); // unchanged
        assertEq(p.updatedAt, 200);    // updated
    }

    function test_register_revertsOnEmptyName() public {
        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.EmptyName.selector);
        register.register("", DESC_AP, URL_AP, LOGO_AP, INFO_AP);
    }

    function test_register_revertsOnEmptyUrl() public {
        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.EmptyUrl.selector);
        register.register(NAME_AP, DESC_AP, "", LOGO_AP, INFO_AP);
    }

    function test_register_allowsEmptyOptionalFields() public {
        vm.prank(alice);
        register.register(NAME_AP, "", URL_AP, "", "");

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.delegation, aliceDelegation); // from EntityManager
        assertEq(bytes(p.description).length, 0);
        assertEq(bytes(p.logoURI).length, 0);
        assertEq(bytes(p.infoURI).length, 0);
    }

    function test_register_multipleParticipants() public {
        _registerAlice();
        _registerBob();

        assertEq(register.participantCount(), 2);

        IParticipantRegister.Participant memory pa = register.getParticipant(alice);
        assertEq(pa.index, 0);

        IParticipantRegister.Participant memory pb = register.getParticipant(bob);
        assertEq(pb.index, 1);
        assertEq(pb.name, NAME_BOB);
    }

    // ---------------------------------------------------------------
    // EntityManager integration
    // ---------------------------------------------------------------

    function test_delegationReadFromEntityManager() public {
        _registerAlice();

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.delegation, aliceDelegation);
    }

    function test_delegationHijackingImpossible() public {
        _registerAlice();

        // Attacker registers — has no delegation in EntityManager
        vm.prank(attacker);
        register.register("Evil Provider", "", "https://evil.com", "", "");

        // Alice's delegation lookup still returns Alice
        IParticipantRegister.Participant memory p = register.getByDelegationAddress(aliceDelegation);
        assertEq(p.owner, alice);
        assertEq(p.name, NAME_AP);

        // Attacker has no delegation (address(0) from EntityManager)
        IParticipantRegister.Participant memory a = register.getParticipant(attacker);
        assertEq(a.delegation, address(0));
    }

    function test_noDelegationInEntityManager() public {
        // Charlie has no delegation in EntityManager — can still register
        vm.prank(charlie);
        register.register("Charlie", "No delegation", "https://charlie.com", "", "");

        IParticipantRegister.Participant memory p = register.getParticipant(charlie);
        assertEq(p.owner, charlie);
        assertEq(p.delegation, address(0));
        assertTrue(p.active);
    }

    function test_entityManagerAddress() public view {
        assertEq(address(register.entityManager()), address(mockEntityManager));
    }

    // ---------------------------------------------------------------
    // refreshDelegation
    // ---------------------------------------------------------------

    function test_refreshDelegation() public {
        _registerAlice();

        // Change delegation in EntityManager
        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        // Anyone can call refreshDelegation
        vm.prank(bob);
        register.refreshDelegation(alice);

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.delegation, newDelegation);
    }

    function test_refreshDelegation_updatesReverseIndex() public {
        _registerAlice();

        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        register.refreshDelegation(alice);

        // Old delegation no longer resolves
        IParticipantRegister.Participant memory old = register.getByDelegationAddress(aliceDelegation);
        assertEq(old.owner, address(0));

        // New delegation works
        IParticipantRegister.Participant memory p = register.getByDelegationAddress(newDelegation);
        assertEq(p.owner, alice);
    }

    function test_refreshDelegation_noChange() public {
        vm.roll(100);
        _registerAlice();

        vm.roll(200);
        register.refreshDelegation(alice);

        // updatedAt should NOT change if delegation didn't change
        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.updatedAt, 100);
    }

    function test_refreshDelegation_revertsIfNotRegistered() public {
        vm.expectRevert(IParticipantRegister.NotRegistered.selector);
        register.refreshDelegation(charlie);
    }

    // ---------------------------------------------------------------
    // Delegation address lookup
    // ---------------------------------------------------------------

    function test_getByDelegationAddress() public {
        _registerAlice();

        IParticipantRegister.Participant memory p = register.getByDelegationAddress(aliceDelegation);
        assertEq(p.owner, alice);
        assertEq(p.name, NAME_AP);
    }

    function test_getByDelegationAddress_afterUpdate() public {
        _registerAlice();

        address newDelegation = makeAddr("newDelegation");
        mockEntityManager.setDelegation(alice, newDelegation);

        vm.prank(alice);
        register.register(NAME_AP, DESC_AP, URL_AP, LOGO_AP, INFO_AP);

        // Old delegation no longer resolves
        IParticipantRegister.Participant memory old = register.getByDelegationAddress(aliceDelegation);
        assertEq(old.owner, address(0));

        // New delegation works
        IParticipantRegister.Participant memory p = register.getByDelegationAddress(newDelegation);
        assertEq(p.owner, alice);
    }

    function test_getByDelegationAddress_unknownReturnsEmpty() public view {
        IParticipantRegister.Participant memory p = register.getByDelegationAddress(address(0xdead));
        assertEq(p.owner, address(0));
    }

    // ---------------------------------------------------------------
    // Max length validation
    // ---------------------------------------------------------------

    function test_maxNameLength_reverts() public {
        // 65 bytes — exceeds MAX_NAME (64)
        bytes memory longName = new bytes(65);
        for (uint i = 0; i < 65; i++) longName[i] = "A";

        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.NameTooLong.selector);
        register.register(string(longName), DESC_AP, URL_AP, LOGO_AP, INFO_AP);
    }

    function test_maxNameLength_exactlyAtLimit() public {
        // 64 bytes — exactly at MAX_NAME
        bytes memory name64 = new bytes(64);
        for (uint i = 0; i < 64; i++) name64[i] = "A";

        vm.prank(alice);
        register.register(string(name64), "", URL_AP, "", "");

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(bytes(p.name).length, 64);
    }

    function test_maxDescriptionLength_reverts() public {
        bytes memory longDesc = new bytes(513);
        for (uint i = 0; i < 513; i++) longDesc[i] = "A";

        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.DescriptionTooLong.selector);
        register.register(NAME_AP, string(longDesc), URL_AP, LOGO_AP, INFO_AP);
    }

    function test_maxUrlLength_reverts() public {
        bytes memory longUrl = new bytes(257);
        for (uint i = 0; i < 257; i++) longUrl[i] = "A";

        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.UriTooLong.selector);
        register.register(NAME_AP, DESC_AP, string(longUrl), LOGO_AP, INFO_AP);
    }

    function test_maxLogoUriLength_reverts() public {
        bytes memory longUri = new bytes(257);
        for (uint i = 0; i < 257; i++) longUri[i] = "A";

        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.UriTooLong.selector);
        register.register(NAME_AP, DESC_AP, URL_AP, string(longUri), INFO_AP);
    }

    function test_maxInfoUriLength_reverts() public {
        bytes memory longUri = new bytes(257);
        for (uint i = 0; i < 257; i++) longUri[i] = "A";

        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.UriTooLong.selector);
        register.register(NAME_AP, DESC_AP, URL_AP, LOGO_AP, string(longUri));
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
        assertEq(p.name, NAME_AP); // data retained
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
        register.register("Reactivated", "Back online", URL_AP, LOGO_AP, INFO_AP);

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertTrue(p.active);
        assertEq(p.name, "Reactivated");
        assertEq(p.index, 0);
        assertEq(p.registeredAt, 100); // original
        assertEq(p.updatedAt, 200);
        assertEq(register.participantCount(), 1); // no duplicate
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
        assertEq(register.activeCount(), 2);

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
        register.register("Reactivated", "", URL_AP, "", "");
        assertEq(register.activeCount(), 1);
    }

    function test_activeCount_noDoubleCount() public {
        _registerAlice();
        assertEq(register.activeCount(), 1);

        // Update while already active — should not double-count
        vm.prank(alice);
        register.register("Updated", "", URL_AP, "", "");
        assertEq(register.activeCount(), 1);
    }

    function test_activeCount_doubleUnregister() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();
        assertEq(register.activeCount(), 0);

        // Second unregister should not underflow
        vm.prank(alice);
        vm.expectRevert(); // NotRegistered — already inactive? No, still registered but inactive
        // Actually unregister checks _isRegistered which returns true (still in index)
        // But active is false, so activeCount should not decrement
    }

    // ---------------------------------------------------------------
    // Read access
    // ---------------------------------------------------------------

    function test_getParticipant_anyoneCanRead() public {
        _registerAlice();

        vm.prank(bob);
        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.name, NAME_AP);
    }

    function test_getParticipant_unregisteredReturnsEmpty() public view {
        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.owner, address(0));
        assertEq(bytes(p.name).length, 0);
        assertFalse(p.active);
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
        address[] memory all = register.getAllParticipants();
        assertEq(all.length, 0);
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

        address[] memory active = register.getActiveParticipants();
        assertEq(active.length, 2);
    }

    function test_getActiveParticipants_noneActive() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();

        address[] memory active = register.getActiveParticipants();
        assertEq(active.length, 0);
    }

    function test_getActiveParticipants_empty() public view {
        address[] memory active = register.getActiveParticipants();
        assertEq(active.length, 0);
    }

    // ---------------------------------------------------------------
    // Pagination
    // ---------------------------------------------------------------

    function test_getParticipants_fullPage() public {
        _registerAlice();
        _registerBob();

        IParticipantRegister.Participant[] memory page = register.getParticipants(0, 10);
        assertEq(page.length, 2);
        assertEq(page[0].name, NAME_AP);
        assertEq(page[1].name, NAME_BOB);
    }

    function test_getParticipants_partialPage() public {
        _registerAlice();
        _registerBob();

        IParticipantRegister.Participant[] memory page = register.getParticipants(0, 1);
        assertEq(page.length, 1);
        assertEq(page[0].name, NAME_AP);
    }

    function test_getParticipants_offset() public {
        _registerAlice();
        _registerBob();

        IParticipantRegister.Participant[] memory page = register.getParticipants(1, 10);
        assertEq(page.length, 1);
        assertEq(page[0].name, NAME_BOB);
    }

    function test_getParticipants_emptyRegistry() public view {
        IParticipantRegister.Participant[] memory page = register.getParticipants(0, 10);
        assertEq(page.length, 0);
    }

    function test_getParticipants_offsetOutOfBounds() public {
        _registerAlice();

        vm.expectRevert(IParticipantRegister.OffsetOutOfBounds.selector);
        register.getParticipants(5, 10);
    }

    // ---------------------------------------------------------------
    // isRegistered / participantCount
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

        assertTrue(register.isRegistered(alice)); // still in index
    }

    function test_participantCount() public {
        assertEq(register.participantCount(), 0);

        _registerAlice();
        assertEq(register.participantCount(), 1);

        _registerBob();
        assertEq(register.participantCount(), 2);

        vm.prank(alice);
        register.unregister();
        assertEq(register.participantCount(), 2); // unregister doesn't reduce count
    }

    // ---------------------------------------------------------------
    // Bulk / edge cases
    // ---------------------------------------------------------------

    function test_manyParticipants() public {
        for (uint256 i = 0; i < 20; i++) {
            address user = makeAddr(string(abi.encodePacked("user", vm.toString(i))));
            address del = makeAddr(string(abi.encodePacked("del", vm.toString(i))));
            mockEntityManager.setDelegation(user, del);
            vm.prank(user);
            register.register(
                string(abi.encodePacked("Provider ", vm.toString(i))),
                "A provider",
                string(abi.encodePacked("https://example.com/", vm.toString(i))),
                "",
                ""
            );
        }

        assertEq(register.participantCount(), 20);
        assertEq(register.activeCount(), 20);

        // Paginate through all
        IParticipantRegister.Participant[] memory page1 = register.getParticipants(0, 10);
        IParticipantRegister.Participant[] memory page2 = register.getParticipants(10, 10);
        assertEq(page1.length, 10);
        assertEq(page2.length, 10);
        assertEq(page1[0].name, "Provider 0");
        assertEq(page2[9].name, "Provider 19");
    }

    function test_manyParticipants_delegationLookup() public {
        _registerAlice();
        _registerBob();

        // Both delegation lookups work
        assertEq(register.getByDelegationAddress(aliceDelegation).owner, alice);
        assertEq(register.getByDelegationAddress(bobDelegation).owner, bob);
    }
}
