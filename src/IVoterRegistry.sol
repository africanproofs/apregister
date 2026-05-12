// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVoterRegistry {
    function getRegisteredVoters(uint256 rewardEpochId)
        external view returns (address[] memory);

    function isVoterRegistered(address voter, uint256 rewardEpochId)
        external view returns (bool);
}
