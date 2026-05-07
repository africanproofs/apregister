// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IEntityManager {
    function getDelegationAddressOfAt(address identity, uint256 rewardEpochId)
        external view returns (address);
}
