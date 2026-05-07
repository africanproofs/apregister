// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IFlareSystemsManager {
    function getCurrentRewardEpochId() external view returns (uint24);
}
