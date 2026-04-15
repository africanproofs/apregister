// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IParticipantRegister} from "./IParticipantRegister.sol";
import {IEntityManager} from "./IEntityManager.sol";

/// @title ParticipantRegister
/// @author African Proofs (https://proofs.africa)
/// @notice Links Flare ecosystem participants to their metadata.
///
/// Any address can register — providers, protocols, DAOs. The contract stores
/// only the pointer (infoURI). All metadata lives in the JSON at that URL.
///
/// Delegation addresses are cached from EntityManager for participants that
/// have one (infrastructure providers). Non-providers get address(0).
///
/// @dev Append-only: unregistering sets active = false, never removes the record.
contract ParticipantRegister is IParticipantRegister {

    uint256 private constant MAX_URI = 256;

    /// @notice EntityManager — authoritative source for delegation addresses.
    IEntityManager public immutable entityManager;

    mapping(address => Participant) private _participants;
    mapping(address => address) private _delegationToVoter;
    address[] private _index;
    uint256 private _activeCount;

    constructor(IEntityManager _entityManager) {
        entityManager = _entityManager;
    }

    /// @inheritdoc IParticipantRegister
    function register(string calldata infoURI) external {
        if (bytes(infoURI).length == 0) revert EmptyInfoURI();
        if (bytes(infoURI).length > MAX_URI) revert UriTooLong();

        address delegation = entityManager.getDelegationAddressOf(msg.sender);

        if (_isRegistered(msg.sender)) {
            address oldDelegation = _participants[msg.sender].delegation;
            if (oldDelegation != delegation && oldDelegation != address(0)) {
                delete _delegationToVoter[oldDelegation];
            }
            if (!_participants[msg.sender].active) {
                _activeCount++;
            }
            _participants[msg.sender].delegation = delegation;
            _participants[msg.sender].infoURI = infoURI;
            _participants[msg.sender].active = true;
            _participants[msg.sender].updatedAt = block.number;
        } else {
            _index.push(msg.sender);
            _participants[msg.sender] = Participant({
                owner: msg.sender,
                delegation: delegation,
                infoURI: infoURI,
                active: true,
                index: _index.length - 1,
                registeredAt: block.number,
                updatedAt: block.number
            });
            _activeCount++;
        }

        if (delegation != address(0)) {
            _delegationToVoter[delegation] = msg.sender;
        }

        emit ParticipantRegistered(
            msg.sender,
            delegation,
            _participants[msg.sender].index,
            infoURI
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
        return _participants[_delegationToVoter[delegation]];
    }

    /// @inheritdoc IParticipantRegister
    function getAllParticipants() external view returns (address[] memory) {
        return _index;
    }

    /// @inheritdoc IParticipantRegister
    function getActiveParticipants() external view returns (address[] memory) {
        uint256 len = _index.length;
        address[] memory result = new address[](_activeCount);
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

    function _isRegistered(address addr) internal view returns (bool) {
        if (_index.length == 0) return false;
        return _index[_participants[addr].index] == addr;
    }
}
