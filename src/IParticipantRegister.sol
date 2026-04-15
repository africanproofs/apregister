// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IParticipantRegister
/// @notice Permissionless on-chain registry mapping Flare ecosystem entities
/// to their metadata URI. Any address can register — providers, protocols, DAOs.
///
/// The contract stores only the pointer (infoURI). All metadata (name, logo,
/// description, delegation address, contact, infrastructure) lives in the JSON
/// at that URI. See assets/participant.template.json for the schema.
///
/// No admin. No ownership. No external dependencies.
interface IParticipantRegister {

    /// @notice On-chain participant record.
    struct Participant {
        address owner;          // Entity address (msg.sender on registration)
        string infoURI;         // URL to participant.json with all metadata
        bool active;            // Whether the registration is active
        uint256 index;          // Position in the participant index
        uint256 registeredAt;   // Block number of first registration
        uint256 updatedAt;      // Block number of last update
    }

    /// @notice Emitted when a participant registers or updates.
    event ParticipantRegistered(address indexed owner, uint256 index, string infoURI);

    /// @notice Emitted when a participant deactivates their registration.
    event ParticipantUnregistered(address indexed owner, uint256 index);

    /// @notice The provided infoURI is empty.
    error EmptyInfoURI();

    /// @notice The provided infoURI exceeds the maximum length.
    error UriTooLong();

    /// @notice The caller is not a registered participant.
    error NotRegistered();

    /// @notice The offset exceeds the participant count.
    error OffsetOutOfBounds();

    /// @notice Register or update. Links msg.sender to a metadata URI.
    /// @param infoURI URL to the participant's metadata JSON (max 256 bytes).
    function register(string calldata infoURI) external;

    /// @notice Deactivate the caller's registration. Record retained, marked inactive.
    function unregister() external;

    /// @notice Get a participant by their entity address.
    function getParticipant(address addr) external view returns (Participant memory);

    /// @notice All registered addresses (active and inactive).
    function getAllParticipants() external view returns (address[] memory);

    /// @notice Active participant addresses only. Intended for off-chain use.
    function getActiveParticipants() external view returns (address[] memory);

    /// @notice Paginated participant retrieval. Safe for on-chain consumers.
    function getParticipants(uint256 offset, uint256 limit)
        external view returns (Participant[] memory);

    /// @notice Check if an address is registered (active or inactive).
    function isRegistered(address addr) external view returns (bool);

    /// @notice Total registered count (active + inactive).
    function participantCount() external view returns (uint256);

    /// @notice Active participant count.
    function activeCount() external view returns (uint256);
}
