// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IFlareContractRegistry {
    function getContractAddressByName(string calldata _name)
        external view returns (address);
}
