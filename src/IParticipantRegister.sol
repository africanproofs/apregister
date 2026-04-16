// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IParticipantRegister
/// @notice Permissionless on-chain registry mapping Flare ecosystem entities
/// to their metadata. Any address can register — providers, protocols, wallets,
/// tools, agents, exchanges, apps.
///
/// The contract stores the entity type (on-chain, filterable) and a pointer
/// (infoURI) to off-chain metadata. All rich metadata (name, logo, description,
/// contact) lives in the JSON-LD file at that URI.
///
/// No admin. No ownership. No external dependencies.
interface IParticipantRegister {

    /// @notice Participant type — determines how tools categorize the entity.
    /// Types 0-6 are defined. Types 7-19 are reserved for future use —
    /// assign meaning via off-chain convention without redeploying the contract.
    enum ParticipantType {
        Provider,       // 0 — FTSO, validators, FDC operators (default)
        DeFi,           // 1 — lending, DEX, yield, staking protocols
        Wallet,         // 2 — wallet applications
        Tool,           // 3 — explorers, analytics, dev tools
        FAssetsAgent,   // 4 — FAssets minting agents
        Exchange,       // 5 — CEX/DEX with Flare listings
        App,            // 6 — games, NFT projects, general dApps
        Reserved7,      // 7 — future use
        Reserved8,      // 8
        Reserved9,      // 9
        Reserved10,     // 10
        Reserved11,     // 11
        Reserved12,     // 12
        Reserved13,     // 13
        Reserved14,     // 14
        Reserved15,     // 15
        Reserved16,     // 16
        Reserved17,     // 17
        Reserved18,     // 18
        Reserved19      // 19
    }

    /// @notice On-chain participant record.
    struct Participant {
        address owner;                      // Entity address (msg.sender on registration)
        ParticipantType participantType;    // Entity type (filterable on-chain)
        string infoURI;                     // URL to participant.json with all metadata
        bool active;                        // Whether the registration is active
        uint256 index;                      // Position in the participant index
        uint256 registeredAt;               // Block number of first registration
        uint256 updatedAt;                  // Block number of last update
    }

    /// @notice Emitted when a participant registers or updates.
    event ParticipantRegistered(
        address indexed owner,
        ParticipantType indexed participantType,
        uint256 index,
        string infoURI
    );

    /// @notice Emitted when a participant deactivates their registration.
    event ParticipantUnregistered(address indexed owner, uint256 index);

    /// @notice The provided infoURI is empty.
    error EmptyInfoURI();

    /// @notice The provided infoURI exceeds the maximum length.
    error UriTooLong();

    /// @notice The caller is not a registered participant.
    error NotRegistered();

    /// @notice The caller's registration is already inactive.
    error NotActive();

    /// @notice The offset exceeds the participant count.
    error OffsetOutOfBounds();

    /// @notice Register or update. Links msg.sender to a type and metadata URI.
    /// @param participantType The type of entity (Provider, DeFi, Wallet, etc.).
    /// @param infoURI URL to the participant's metadata JSON (max 256 bytes).
    function register(ParticipantType participantType, string calldata infoURI) external;

    /// @notice Deactivate the caller's registration. Record retained, marked inactive.
    function unregister() external;

    /// @notice Get a participant by their entity address.
    function getParticipant(address addr) external view returns (Participant memory);

    /// @notice All registered addresses (active and inactive).
    function getAllParticipants() external view returns (address[] memory);

    /// @notice Active participant addresses only. Intended for off-chain use.
    function getActiveParticipants() external view returns (address[] memory);

    /// @notice Active participants filtered by type. Intended for off-chain use.
    function getParticipantsByType(ParticipantType participantType) external view returns (address[] memory);

    /// @notice Paginated participant retrieval. Safe for on-chain consumers.
    function getParticipants(uint256 offset, uint256 limit)
        external view returns (Participant[] memory);

    /// @notice Check if an address is registered (active or inactive).
    function isRegistered(address addr) external view returns (bool);

    /// @notice Total registered count (active + inactive).
    function participantCount() external view returns (uint256);

    /// @notice Active participant count.
    function activeCount() external view returns (uint256);

    /// @notice Active participant count for a specific type.
    function typeCount(ParticipantType participantType) external view returns (uint256);
}
