// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IParticipantRegister
/// @notice Interface for the Flare Participant Register — a permissionless on-chain registry
/// where data providers and validators publish metadata about their offerings.
///
/// Designed as a decentralized alternative to centralized provider lists (e.g. TowoLabs
/// ftso-signal-providers). Any participant can register and update their own metadata
/// without gatekeepers.
interface IParticipantRegister {
    /// @notice Participant metadata stored on-chain.
    struct Participant {
        address owner;          // Voter/identity address (msg.sender on registration)
        address delegation;     // Delegation address used by delegators
        string name;            // Display name (recommended max 32 chars)
        string description;     // Short description (recommended max 350 chars)
        string url;             // Website URL
        string logoURI;         // Direct URL to logo image (128-256px square PNG)
        string infoURI;         // URL to full standardized JSON metadata file
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

    /// @notice The offset exceeds the participant count.
    error OffsetOutOfBounds();

    /// @notice Register or update a participant entry. Callable only by the participant themselves.
    /// @param delegation The delegation address associated with this participant.
    /// @param name       Display name of the participant.
    /// @param description Short description of services offered.
    /// @param url        Website URL.
    /// @param logoURI    Direct URL to a logo image.
    /// @param infoURI    URL to the full standardized JSON metadata file.
    function register(
        address delegation,
        string calldata name,
        string calldata description,
        string calldata url,
        string calldata logoURI,
        string calldata infoURI
    ) external;

    /// @notice Deactivate the caller's registration. The record is retained but marked inactive.
    function unregister() external;

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
}
