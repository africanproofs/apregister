// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IParticipantRegister
/// @notice Interface for the Flare Participant Register — a permissionless on-chain registry
/// where data providers and validators publish metadata about their offerings.
///
/// Designed as a decentralized alternative to centralized provider lists (e.g. TowoLabs
/// ftso-signal-providers). Any participant can register and update their own metadata
/// without gatekeepers.
///
/// Delegation addresses are read from EntityManager (the authoritative source) — not
/// self-reported. This prevents delegation address hijacking.
interface IParticipantRegister {
    /// @notice Participant metadata stored on-chain.
    struct Participant {
        address owner;          // Voter/identity address (msg.sender on registration)
        address delegation;     // Delegation address (cached from EntityManager)
        string name;            // Display name (max 64 bytes)
        string description;     // Short description (max 512 bytes)
        string url;             // Website URL (max 256 bytes)
        string logoURI;         // Direct URL to logo image (max 256 bytes)
        string infoURI;         // URL to full standardized JSON metadata file (max 256 bytes)
        bool active;            // Whether the registration is active
        uint256 index;          // Position in the participant index
        uint256 registeredAt;   // Block number of first registration
        uint256 updatedAt;      // Block number of last update
    }

    /// @notice Emitted when a participant registers or updates their registration.
    event ParticipantRegistered(
        address indexed owner,
        address indexed delegation,
        uint256 index,
        string name,
        string url,
        string logoURI
    );

    /// @notice Emitted when a participant deactivates their registration.
    event ParticipantUnregistered(address indexed owner, uint256 index);

    /// @notice The caller is not a registered participant.
    error NotRegistered();

    /// @notice The provided name is empty.
    error EmptyName();

    /// @notice The provided URL is empty.
    error EmptyUrl();

    /// @notice The provided name exceeds the maximum length.
    error NameTooLong();

    /// @notice The provided description exceeds the maximum length.
    error DescriptionTooLong();

    /// @notice A provided URI exceeds the maximum length.
    error UriTooLong();

    /// @notice The offset exceeds the participant count.
    error OffsetOutOfBounds();

    /// @notice Register or update a participant entry. Callable only by the participant themselves.
    /// Delegation address is read from EntityManager automatically.
    /// @param name        Display name of the participant (max 64 bytes).
    /// @param description Short description of services offered (max 512 bytes).
    /// @param url         Website URL (max 256 bytes).
    /// @param logoURI     Direct URL to a logo image (max 256 bytes).
    /// @param infoURI     URL to the full standardized JSON metadata file (max 256 bytes).
    function register(
        string calldata name,
        string calldata description,
        string calldata url,
        string calldata logoURI,
        string calldata infoURI
    ) external;

    /// @notice Deactivate the caller's registration. The record is retained but marked inactive.
    function unregister() external;

    /// @notice Refresh a participant's cached delegation address from EntityManager.
    /// Callable by anyone — keeps the reverse index fresh if delegation changes.
    /// @param addr The voter/identity address to refresh.
    function refreshDelegation(address addr) external;

    /// @notice Retrieve a participant's metadata by their voter/identity address.
    /// @param addr The voter/identity address of the participant.
    /// @return participant The participant's stored metadata.
    function getParticipant(address addr) external view returns (Participant memory participant);

    /// @notice Retrieve a participant's metadata by their delegation address.
    /// @param delegation The delegation address to look up.
    /// @return participant The participant's stored metadata.
    function getByDelegationAddress(address delegation) external view returns (Participant memory participant);

    /// @notice Returns all registered voter/identity addresses regardless of active status.
    /// @return addresses Array of all participant addresses.
    function getAllParticipants() external view returns (address[] memory addresses);

    /// @notice Returns only active participant voter/identity addresses.
    /// @return addresses Array of active participant addresses.
    function getActiveParticipants() external view returns (address[] memory addresses);

    /// @notice Paginated retrieval of participant metadata.
    /// @param offset Starting index in the participant list.
    /// @param limit  Maximum number of participants to return.
    /// @return participants Array of participant metadata.
    function getParticipants(uint256 offset, uint256 limit)
        external view returns (Participant[] memory participants);

    /// @notice Check whether an address is a registered participant.
    /// @param addr The voter/identity address to check.
    /// @return True if the address has registered (regardless of active status).
    function isRegistered(address addr) external view returns (bool);

    /// @notice Returns the total number of registered participants (active and inactive).
    /// @return count The total participant count.
    function participantCount() external view returns (uint256 count);

    /// @notice Returns the number of active participants.
    /// @return count The active participant count.
    function activeCount() external view returns (uint256 count);
}
