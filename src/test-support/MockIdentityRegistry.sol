// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title MockIdentityRegistry
/// @author African Proofs (https://proofs.africa)
/// @notice Test-only registry that models "is this address a registered FSP
///         identity?" on Coston2. Coston2's real EntityManager only lists
///         identities whose private keys we do not own, so this contract
///         stands in as the on-chain source of truth for the testnet leg of
///         apregister-web's provider-identity gate.
///
///         NOT for Flare or Songbird mainnet — those reads go through the
///         canonical FlareContractRegistry → EntityManager path.
///
/// @dev Admin-controlled allowlist. Separate from the audited
///      ParticipantRegister contract; lives under src/test-support/ to keep
///      the mainnet surface area unchanged.
contract MockIdentityRegistry {

    address public admin;
    mapping(address => bool) private _registered;
    address[] private _identities;

    event IdentityAdded(address indexed identity);
    event IdentityRemoved(address indexed identity);
    event AdminTransferred(address indexed from, address indexed to);

    error NotAdmin();
    error AlreadyRegistered();
    error NotRegistered();
    error ZeroAddress();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(address initialAdmin) {
        if (initialAdmin == address(0)) revert ZeroAddress();
        admin = initialAdmin;
        emit AdminTransferred(address(0), initialAdmin);
    }

    /// @notice Primary check: is `who` a registered provider identity?
    function isRegisteredIdentity(address who) external view returns (bool) {
        return _registered[who];
    }

    /// @notice Full enumeration for operator visibility.
    function getRegisteredIdentities() external view returns (address[] memory) {
        return _identities;
    }

    function identityCount() external view returns (uint256) {
        return _identities.length;
    }

    function addIdentity(address who) external onlyAdmin {
        if (who == address(0)) revert ZeroAddress();
        if (_registered[who]) revert AlreadyRegistered();
        _registered[who] = true;
        _identities.push(who);
        emit IdentityAdded(who);
    }

    /// @notice Batch add. Silently skips already-registered entries so repeat
    ///         invocations are idempotent — useful when re-running the seed
    ///         script after adding a new HD index.
    function addIdentities(address[] calldata who) external onlyAdmin {
        uint256 n = who.length;
        for (uint256 i; i < n; ++i) {
            address a = who[i];
            if (a == address(0)) revert ZeroAddress();
            if (!_registered[a]) {
                _registered[a] = true;
                _identities.push(a);
                emit IdentityAdded(a);
            }
        }
    }

    function removeIdentity(address who) external onlyAdmin {
        if (!_registered[who]) revert NotRegistered();
        _registered[who] = false;
        uint256 len = _identities.length;
        for (uint256 i; i < len; ++i) {
            if (_identities[i] == who) {
                _identities[i] = _identities[len - 1];
                _identities.pop();
                break;
            }
        }
        emit IdentityRemoved(who);
    }

    function transferAdmin(address to) external onlyAdmin {
        if (to == address(0)) revert ZeroAddress();
        emit AdminTransferred(admin, to);
        admin = to;
    }
}
