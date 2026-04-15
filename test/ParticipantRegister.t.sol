// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {ParticipantRegister} from "../src/ParticipantRegister.sol";
import {IParticipantRegister} from "../src/IParticipantRegister.sol";

contract ParticipantRegisterTest is Test {
    ParticipantRegister private register;

    // Re-declare enum for test convenience
    using {_t} for uint8;

    event ParticipantRegistered(
        address indexed owner,
        IParticipantRegister.ParticipantType indexed participantType,
        uint256 index,
        string infoURI
    );
    event ParticipantUnregistered(address indexed owner, uint256 index);

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");
    address private defiProtocol = makeAddr("defiProtocol");
    address private wallet = makeAddr("wallet");

    IParticipantRegister.ParticipantType constant PROVIDER = IParticipantRegister.ParticipantType.Provider;
    IParticipantRegister.ParticipantType constant DEFI = IParticipantRegister.ParticipantType.DeFi;
    IParticipantRegister.ParticipantType constant WALLET = IParticipantRegister.ParticipantType.Wallet;
    IParticipantRegister.ParticipantType constant TOOL = IParticipantRegister.ParticipantType.Tool;
    IParticipantRegister.ParticipantType constant APP = IParticipantRegister.ParticipantType.App;

    string private constant INFO_AP = "https://proofs.africa/participant.json";
    string private constant INFO_BOB = "https://bob.example.com/participant.json";
    string private constant INFO_DEFI = "https://kinetic.market/participant.json";
    string private constant INFO_WALLET = "https://bifrostwallet.com/participant.json";

    function setUp() public {
        register = new ParticipantRegister();
    }

    function _registerAlice() internal {
        vm.prank(alice);
        register.register(PROVIDER, INFO_AP);
    }

    function _registerBob() internal {
        vm.prank(bob);
        register.register(PROVIDER, INFO_BOB);
    }

    // ---------------------------------------------------------------
    // Registration
    // ---------------------------------------------------------------

    function test_register() public {
        vm.roll(100);
        _registerAlice();

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.owner, alice);
        assertTrue(p.participantType == PROVIDER);
        assertEq(p.infoURI, INFO_AP);
        assertTrue(p.active);
        assertEq(p.index, 0);
        assertEq(p.registeredAt, 100);
        assertEq(p.updatedAt, 100);
    }

    function test_register_emitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit ParticipantRegistered(alice, PROVIDER, 0, INFO_AP);

        vm.prank(alice);
        register.register(PROVIDER, INFO_AP);
    }

    function test_register_update() public {
        vm.roll(100);
        _registerAlice();

        vm.roll(200);
        vm.prank(alice);
        register.register(PROVIDER, "https://proofs.africa/v2/participant.json");

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertEq(p.infoURI, "https://proofs.africa/v2/participant.json");
        assertEq(p.registeredAt, 100);
        assertEq(p.updatedAt, 200);
    }

    function test_register_revertsOnEmptyURI() public {
        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.EmptyInfoURI.selector);
        register.register(PROVIDER, "");
    }

    function test_register_revertsOnUriTooLong() public {
        bytes memory longUri = new bytes(257);
        for (uint i = 0; i < 257; i++) longUri[i] = "A";

        vm.prank(alice);
        vm.expectRevert(IParticipantRegister.UriTooLong.selector);
        register.register(PROVIDER, string(longUri));
    }

    function test_register_exactlyAtMaxLength() public {
        bytes memory uri256 = new bytes(256);
        for (uint i = 0; i < 256; i++) uri256[i] = "A";

        vm.prank(alice);
        register.register(PROVIDER, string(uri256));
        assertEq(bytes(register.getParticipant(alice).infoURI).length, 256);
    }

    function test_register_multipleParticipants() public {
        _registerAlice();
        _registerBob();

        assertEq(register.participantCount(), 2);
        assertEq(register.getParticipant(alice).index, 0);
        assertEq(register.getParticipant(bob).index, 1);
    }

    // ---------------------------------------------------------------
    // Types
    // ---------------------------------------------------------------

    function test_register_asDefi() public {
        vm.prank(defiProtocol);
        register.register(DEFI, INFO_DEFI);

        IParticipantRegister.Participant memory p = register.getParticipant(defiProtocol);
        assertTrue(p.participantType == DEFI);
    }

    function test_register_asWallet() public {
        vm.prank(wallet);
        register.register(WALLET, INFO_WALLET);

        assertTrue(register.getParticipant(wallet).participantType == WALLET);
    }

    function test_register_changeType() public {
        vm.prank(alice);
        register.register(PROVIDER, INFO_AP);
        assertTrue(register.getParticipant(alice).participantType == PROVIDER);
        assertEq(register.typeCount(PROVIDER), 1);

        vm.prank(alice);
        register.register(TOOL, INFO_AP);
        assertTrue(register.getParticipant(alice).participantType == TOOL);
        assertEq(register.typeCount(PROVIDER), 0);
        assertEq(register.typeCount(TOOL), 1);
    }

    function test_register_withReservedType() public {
        IParticipantRegister.ParticipantType reserved7 = IParticipantRegister.ParticipantType.Reserved7;

        vm.prank(alice);
        register.register(reserved7, INFO_AP);

        assertTrue(register.getParticipant(alice).participantType == reserved7);
        assertEq(register.typeCount(reserved7), 1);

        address[] memory reserved = register.getParticipantsByType(reserved7);
        assertEq(reserved.length, 1);
        assertEq(reserved[0], alice);
    }

    function test_typeCount() public {
        vm.prank(alice);
        register.register(PROVIDER, INFO_AP);

        vm.prank(bob);
        register.register(PROVIDER, INFO_BOB);

        vm.prank(defiProtocol);
        register.register(DEFI, INFO_DEFI);

        assertEq(register.typeCount(PROVIDER), 2);
        assertEq(register.typeCount(DEFI), 1);
        assertEq(register.typeCount(WALLET), 0);
    }

    function test_typeCount_decrementOnUnregister() public {
        _registerAlice();
        assertEq(register.typeCount(PROVIDER), 1);

        vm.prank(alice);
        register.unregister();
        assertEq(register.typeCount(PROVIDER), 0);
    }

    function test_typeCount_incrementOnReregister() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();
        assertEq(register.typeCount(PROVIDER), 0);

        vm.prank(alice);
        register.register(PROVIDER, INFO_AP);
        assertEq(register.typeCount(PROVIDER), 1);
    }

    function test_getParticipantsByType() public {
        vm.prank(alice);
        register.register(PROVIDER, INFO_AP);

        vm.prank(bob);
        register.register(PROVIDER, INFO_BOB);

        vm.prank(defiProtocol);
        register.register(DEFI, INFO_DEFI);

        address[] memory providers = register.getParticipantsByType(PROVIDER);
        assertEq(providers.length, 2);
        assertEq(providers[0], alice);
        assertEq(providers[1], bob);

        address[] memory defi = register.getParticipantsByType(DEFI);
        assertEq(defi.length, 1);
        assertEq(defi[0], defiProtocol);

        address[] memory wallets = register.getParticipantsByType(WALLET);
        assertEq(wallets.length, 0);
    }

    function test_getParticipantsByType_excludesInactive() public {
        _registerAlice();
        _registerBob();

        vm.prank(alice);
        register.unregister();

        address[] memory providers = register.getParticipantsByType(PROVIDER);
        assertEq(providers.length, 1);
        assertEq(providers[0], bob);
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
        assertEq(p.infoURI, INFO_AP);
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
        register.register(PROVIDER, "https://proofs.africa/v2/participant.json");

        IParticipantRegister.Participant memory p = register.getParticipant(alice);
        assertTrue(p.active);
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
        register.register(PROVIDER, INFO_AP);
        assertEq(register.activeCount(), 1);
    }

    function test_activeCount_noDoubleCount() public {
        _registerAlice();
        assertEq(register.activeCount(), 1);

        vm.prank(alice);
        register.register(PROVIDER, "https://proofs.africa/v2/participant.json");
        assertEq(register.activeCount(), 1);
    }

    function test_activeCount_doubleUnregister() public {
        _registerAlice();
        vm.prank(alice);
        register.unregister();

        vm.prank(alice);
        register.unregister();
        assertEq(register.activeCount(), 0);
    }

    // ---------------------------------------------------------------
    // FLR rejection
    // ---------------------------------------------------------------

    function test_rejectFLR() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        (bool sent,) = address(register).call{value: 1 ether}("");
        assertFalse(sent);
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

    function test_manyParticipants_mixedTypes() public {
        for (uint256 i = 0; i < 10; i++) {
            address user = makeAddr(string(abi.encodePacked("user", vm.toString(i))));
            IParticipantRegister.ParticipantType t = i < 5 ? PROVIDER : DEFI;
            vm.prank(user);
            register.register(t, string(abi.encodePacked("https://example.com/", vm.toString(i), ".json")));
        }

        assertEq(register.participantCount(), 10);
        assertEq(register.activeCount(), 10);
        assertEq(register.typeCount(PROVIDER), 5);
        assertEq(register.typeCount(DEFI), 5);

        address[] memory providers = register.getParticipantsByType(PROVIDER);
        assertEq(providers.length, 5);

        address[] memory defi = register.getParticipantsByType(DEFI);
        assertEq(defi.length, 5);
    }
}

function _t(uint8) pure returns (IParticipantRegister.ParticipantType) {
    return IParticipantRegister.ParticipantType.Provider;
}
