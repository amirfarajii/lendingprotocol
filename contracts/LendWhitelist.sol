// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

import "./dependencies/openzeppelin/Ownable.sol";


contract LendWhitelist is Ownable {
    
    //Oracle Whitelist Storage
    mapping(address => bool) public OracleContractWhitelist;

    //Interest Rate Calculator Whitelist Storage
    mapping(address => bool) public rateContractWhitelist;

    //Lend Deployer Whitelist Storage
    mapping(address => bool) public lendDeployerWhitelist;

    constructor() Ownable(){}

    event SetOracleWhitelist(address indexed _address, bool _bool);
    event SetRateContractWhitelist(address indexed _address, bool _bool);
    event SetLendDeployerWhitelist(address indexed _address, bool _bool);

    function setOracleContractWhitelist(address[] calldata _addresses, bool _bool) external onlyOwner {
        for(uint256 i=0; i < _addresses.length; i++) {
            OracleContractWhitelist[_addresses[i]] = _bool;
            emit SetOracleWhitelist(_addresses[i], _bool);
        }
    }
    function setRateContractWhitelist(address[] calldata _addresses, bool _bool) external onlyOwner {
        for(uint i=0; i < _addresses.length; i++) {
            rateContractWhitelist[_addresses[i]] = _bool;
            emit SetRateContractWhitelist(_addresses[i], _bool);
        }
    }

    function setLendDeployerWhitelist(address[] calldata _addresses, bool _bool) external onlyOwner {
        for(uint i=0; i < _addresses.length; i++){
            lendDeployerWhitelist[_addresses[i]] = _bool;
            emit SetLendDeployerWhitelist(_addresses[i], _bool);
        }
    }

}