// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IParticipantRegister} from "./IParticipantRegister.sol";

/// @title ParticipantRegister
/// @author African Proofs (https://proofs.africa)
/// @notice Maps Flare ecosystem entities to their type and metadata URI.
///
/// Any address can register — providers, protocols, wallets, tools, agents,
/// exchanges, apps. The contract stores type (for on-chain filtering) and
/// infoURI (pointer to off-chain JSON-LD metadata).
///
/// No admin. No ownership. No external dependencies. No funds held.
///
/// @dev Append-only: unregistering sets active = false, never removes the record.
/// The _isRegistered check uses _index[_participants[addr].index] == addr for O(1)
/// lookup. This works because unregistered addresses default to index 0, but
/// _index[0] is the first registrant — the equality check fails correctly.
/// Empty registry caught by the length check.
contract ParticipantRegister is IParticipantRegister {

    uint256 private constant MAX_URI = 256;

    mapping(address => Participant) private _participants;
    address[] private _index;
    uint256 private _activeCount;
    mapping(ParticipantType => uint256) private _typeCounts;

    /// @dev Reject any FLR sent to this contract.
    receive() external payable {
        revert();
    }

    /// @inheritdoc IParticipantRegister
    function register(ParticipantType participantType, string calldata infoURI) external {
        if (bytes(infoURI).length == 0) revert EmptyInfoURI();
        if (bytes(infoURI).length > MAX_URI) revert UriTooLong();

        if (_isRegistered(msg.sender)) {
            ParticipantType oldType = _participants[msg.sender].participantType;
            bool wasActive = _participants[msg.sender].active;

            if (!wasActive) {
                _activeCount++;
                _typeCounts[participantType]++;
            } else if (oldType != participantType) {
                _typeCounts[oldType]--;
                _typeCounts[participantType]++;
            }

            _participants[msg.sender].participantType = participantType;
            _participants[msg.sender].infoURI = infoURI;
            _participants[msg.sender].active = true;
            _participants[msg.sender].updatedAt = block.number;
        } else {
            _index.push(msg.sender);
            _participants[msg.sender] = Participant({
                owner: msg.sender,
                participantType: participantType,
                infoURI: infoURI,
                active: true,
                index: _index.length - 1,
                registeredAt: block.number,
                updatedAt: block.number
            });
            _activeCount++;
            _typeCounts[participantType]++;
        }

        emit ParticipantRegistered(msg.sender, participantType, _participants[msg.sender].index, infoURI);
    }

    /// @inheritdoc IParticipantRegister
    function unregister() external {
        if (!_isRegistered(msg.sender)) revert NotRegistered();
        if (!_participants[msg.sender].active) revert NotActive();
        _activeCount--;
        _typeCounts[_participants[msg.sender].participantType]--;
        _participants[msg.sender].active = false;
        _participants[msg.sender].updatedAt = block.number;
        emit ParticipantUnregistered(msg.sender, _participants[msg.sender].index);
    }

    /// @inheritdoc IParticipantRegister
    function getParticipant(address addr) external view returns (Participant memory) {
        return _participants[addr];
    }

    /// @inheritdoc IParticipantRegister
    function getAllParticipants() external view returns (address[] memory) {
        return _index;
    }

    /// @inheritdoc IParticipantRegister
    /// @dev Iterates full index — intended for off-chain eth_call only.
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
    /// @dev Iterates full index — intended for off-chain eth_call only.
    function getParticipantsByType(ParticipantType participantType) external view returns (address[] memory) {
        uint256 len = _index.length;
        uint256 count = _typeCounts[participantType];
        address[] memory result = new address[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < len; i++) {
            Participant storage p = _participants[_index[i]];
            if (p.active && p.participantType == participantType) {
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

    /// @inheritdoc IParticipantRegister
    function typeCount(ParticipantType participantType) external view returns (uint256) {
        return _typeCounts[participantType];
    }

    function _isRegistered(address addr) internal view returns (bool) {
        if (_index.length == 0) return false;
        return _index[_participants[addr].index] == addr;
    }
}
