// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IParticipantRegister} from "./IParticipantRegister.sol";

/// @title ParticipantRegister
/// @author African Proofs (https://proofs.africa)
/// @notice Maps Flare ecosystem entities to their metadata URI.
///
/// Any address can register — providers, protocols, DAOs. The contract stores
/// only the pointer (infoURI). All metadata lives in the JSON at that URL.
///
/// No admin. No ownership. No external dependencies. No funds held.
///
/// @dev Append-only: unregistering sets active = false, never removes the record.
/// The _isRegistered check uses _index[_participants[addr].index] == addr for O(1)
/// lookup. This works because unregistered addresses have index = 0 (default) but
/// _index[0] is the first registrant, not the queried address — so the equality
/// check fails correctly. The empty-registry case is caught by the length check.
contract ParticipantRegister is IParticipantRegister {

    uint256 private constant MAX_URI = 256;

    mapping(address => Participant) private _participants;
    address[] private _index;
    uint256 private _activeCount;

    /// @dev Reject any FLR sent to this contract. No funds should be held here.
    receive() external payable {
        revert();
    }

    /// @inheritdoc IParticipantRegister
    function register(string calldata infoURI) external {
        if (bytes(infoURI).length == 0) revert EmptyInfoURI();
        if (bytes(infoURI).length > MAX_URI) revert UriTooLong();

        if (_isRegistered(msg.sender)) {
            if (!_participants[msg.sender].active) {
                _activeCount++;
            }
            _participants[msg.sender].infoURI = infoURI;
            _participants[msg.sender].active = true;
            _participants[msg.sender].updatedAt = block.number;
        } else {
            _index.push(msg.sender);
            _participants[msg.sender] = Participant({
                owner: msg.sender,
                infoURI: infoURI,
                active: true,
                index: _index.length - 1,
                registeredAt: block.number,
                updatedAt: block.number
            });
            _activeCount++;
        }

        emit ParticipantRegistered(msg.sender, _participants[msg.sender].index, infoURI);
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

    /// @dev O(1) registration check. Works because unregistered addresses default
    /// to index 0, but _index[0] is the first actual registrant — the equality
    /// check fails correctly. Empty registry caught by length check.
    function _isRegistered(address addr) internal view returns (bool) {
        if (_index.length == 0) return false;
        return _index[_participants[addr].index] == addr;
    }
}
