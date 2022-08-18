// SPDX-License-Identifier: ISC
pragma solidity >=0.8.15;

interface ILendWhitelist {
    function OracleContractWhitelist(address) external view returns(bool);

    function rateContractWhitelist(address) external view returns(bool);

    function lendDeployerWhitelist(address) external view returns(bool);

    function setOracleContractWhitelist(address[] calldata, bool) external;

    function setRateContractWhitelist(address[] calldata, bool) external;

    function setLendDeployerWhitelist(address[] calldata, bool) external; 

    function owner() external view returns (address);

    function renounceOwnership() external ;

    function transferOwnership(address newOwner) external;
}