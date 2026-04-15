// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IParticipantRegister} from "./IParticipantRegister.sol";
import {IEntityManager} from "./IEntityManager.sol";

/// @title ParticipantRegister
/// @author African Proofs (https://proofs.africa)
/// @notice A permissionless on-chain registry for Flare and Songbird infrastructure participants.
///
/// Participants (data providers, validators, FDC operators) register with metadata including
/// name, description, logo, website, and a URL to a standardized JSON file. Designed as a
/// decentralized alternative to centralized provider lists.
///
/// Delegation addresses are read from Flare's EntityManager — the authoritative source for
/// entity address relationships. This prevents delegation address hijacking.
///
/// Anyone can read the registry. No admin, no ownership, fully permissionless.
///
/// @dev The registry is append-only: unregistering sets `active = false` but never removes
/// the record or its index. Re-registering reactivates the entry with updated data.
/// A reverse index maps delegation addresses to voter addresses for efficient lookup.
contract ParticipantRegister is IParticipantRegister {

    /// @dev Maximum byte lengths for string fields.
    uint256 private constant MAX_NAME = 64;
    uint256 private constant MAX_DESCRIPTION = 512;
    uint256 private constant MAX_URI = 256;

    /// @notice The EntityManager contract — authoritative source for delegation addresses.
    IEntityManager public immutable entityManager;

    /// @dev Mapping from voter/identity address to participant metadata.
    mapping(address => Participant) private _participants;

    /// @dev Reverse index: delegation address => voter/identity address.
    mapping(address => address) private _delegationToVoter;

    /// @dev Ordered list of all voter/identity addresses (append-only).
    address[] private _index;

    /// @dev Count of active participants.
    uint256 private _activeCount;

    /// @param _entityManager The EntityManager contract address for this network.
    constructor(IEntityManager _entityManager) {
        entityManager = _entityManager;
    }

    /// @inheritdoc IParticipantRegister
    function register(
        string calldata name,
        string calldata description,
        string calldata url,
        string calldata logoURI,
        string calldata infoURI
    ) external {
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(url).length == 0) revert EmptyUrl();
        if (bytes(name).length > MAX_NAME) revert NameTooLong();
        if (bytes(description).length > MAX_DESCRIPTION) revert DescriptionTooLong();
        if (bytes(url).length > MAX_URI) revert UriTooLong();
        if (bytes(logoURI).length > MAX_URI) revert UriTooLong();
        if (bytes(infoURI).length > MAX_URI) revert UriTooLong();

        // Read delegation from EntityManager (authoritative source)
        address delegation = entityManager.getDelegationAddressOf(msg.sender);

        if (_isRegistered(msg.sender)) {
            // Clear old delegation reverse index if delegation changed
            address oldDelegation = _participants[msg.sender].delegation;
            if (oldDelegation != delegation && oldDelegation != address(0)) {
                delete _delegationToVoter[oldDelegation];
            }

            // Re-activate if was inactive
            if (!_participants[msg.sender].active) {
                _activeCount++;
            }

            _participants[msg.sender].delegation = delegation;
            _participants[msg.sender].name = name;
            _participants[msg.sender].description = description;
            _participants[msg.sender].url = url;
            _participants[msg.sender].logoURI = logoURI;
            _participants[msg.sender].infoURI = infoURI;
            _participants[msg.sender].active = true;
            _participants[msg.sender].updatedAt = block.number;
        } else {
            _index.push(msg.sender);
            uint256 idx = _index.length - 1;
            _participants[msg.sender] = Participant({
                owner: msg.sender,
                delegation: delegation,
                name: name,
                description: description,
                url: url,
                logoURI: logoURI,
                infoURI: infoURI,
                active: true,
                index: idx,
                registeredAt: block.number,
                updatedAt: block.number
            });
            _activeCount++;
        }

        // Update delegation reverse index
        if (delegation != address(0)) {
            _delegationToVoter[delegation] = msg.sender;
        }

        emit ParticipantRegistered(
            msg.sender,
            delegation,
            _participants[msg.sender].index,
            name,
            url,
            logoURI
        );
    }

    /// @inheritdoc IParticipantRegister
    function unregister() external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();

        if (_participants[msg.sender].active) {
            _activeCount--;
        }

        _participants[msg.sender].active = false;
        _participants[msg.sender].updatedAt = block.number;

        emit ParticipantUnregistered(msg.sender, _participants[msg.sender].index);
    }

    /// @inheritdoc IParticipantRegister
    function refreshDelegation(address addr) external {
        if (!_isRegistered(addr)) revert NotRegistered();

        address oldDelegation = _participants[addr].delegation;
        address newDelegation = entityManager.getDelegationAddressOf(addr);

        if (oldDelegation != newDelegation) {
            if (oldDelegation != address(0)) {
                delete _delegationToVoter[oldDelegation];
            }
            _participants[addr].delegation = newDelegation;
            if (newDelegation != address(0)) {
                _delegationToVoter[newDelegation] = addr;
            }
            _participants[addr].updatedAt = block.number;
        }
    }

    /// @inheritdoc IParticipantRegister
    function getParticipant(address addr) external view returns (Participant memory) {
        return _participants[addr];
    }

    /// @inheritdoc IParticipantRegister
    function getByDelegationAddress(address delegation) external view returns (Participant memory) {
        address voter = _delegationToVoter[delegation];
        return _participants[voter];
    }

    /// @inheritdoc IParticipantRegister
    function getAllParticipants() external view returns (address[] memory) {
        return _index;
    }

    /// @inheritdoc IParticipantRegister
    function getActiveParticipants() external view returns (address[] memory) {
        // First pass: count active
        uint256 len = _index.length;
        uint256 count = _activeCount;

        // Second pass: collect active addresses
        address[] memory result = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < len; i++) {
            if (_participants[_index[i]].active) {
                result[j++] = _index[i];
            }
        }

        return result;
    }

    /// @inheritdoc IParticipantRegister
    function getParticipants(uint256 offset, uint256 limit)
        external view returns (Participant[] memory)
    {
        uint256 len = _index.length;
        if (offset >= len) {
            if (offset == 0 && len == 0) {
                return new Participant[](0);
            }
            revert OffsetOutOfBounds();
        }

        uint256 remaining = len - offset;
        uint256 count = limit < remaining ? limit : remaining;

        Participant[] memory result = new Participant[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = _participants[_index[offset + i]];
        }

        return result;
    }

    /// @inheritdoc IParticipantRegister
    function isRegistered(address addr) external view returns (bool) {
        return _isRegistered(addr);
    }

    /// @inheritdoc IParticipantRegister
    function participantCount() external view returns (uint256) {
        return _index.length;
    }

    /// @inheritdoc IParticipantRegister
    function activeCount() external view returns (uint256) {
        return _activeCount;
    }

    /// @dev Check if an address is in the registry. Uses the index array for O(1) lookup.
    function _isRegistered(address addr) internal view returns (bool) {
        if (_index.length == 0) return false;
        return _index[_participants[addr].index] == addr;
    }
}
