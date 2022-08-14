// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

/*
** 14 August 2022
** forket from FraxLend
*/

import "./interfaces/IRateCalculator.sol";

contract VariableInterestRate is IRateCalculater {

    uint32 private constant MIN_UTIL = 75000; // 75%
    uint32 private constant MAX_UTIL = 80000; // 80%
    uint32 private constant UTIL_PREC = 1e5; // 5 decimals
    

    //Interest Rate Settings (all rate are per second), 365.24 days per year
    uint64 private constant MIN_INT = 79123523; //0.25% annual rate;
    uint64 private constant MAX_INT = 146248508681; //10% annual rate;
    uint256 private constant INT_HALF_LIFE = 43200e36; // given per seconds, equal to hours, additional 1e36 to make math simpler

    //Name of contract
    function name() external pure returns(string memory){
        return "Variable Time-Weighted Interest Rate";
    }

    function getConstants() external pure returns(bytes memory _calldata){
        return abi.encode(MIN_UTIL, MAX_UTIL, UTIL_PREC, MIN_INT, MAX_INT, INT_HALF_LIFE);
    }

    function requireValidInitData(bytes calldata _initData) external pure{}

    //@param intiDate empty for this calculator

    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns(uint64 _newRatePerSec){
        (uint64 _currentRatePerSec, uint256 _deltaTime, uint256 _utilization, ) = abi.decode(
            _data,
            (uint64, uint256, uint256,uint256)
        );

        if(_utilization < MIN_UTIL) {
            uint256 _deltaUtilization  = ((MIN_UTIL - _utilization) * 1e18) / MIN_UTIL;
            uint256 _decayGrowth = INT_HALF_LIFE + (_deltaUtilization * _deltaUtilization * _deltaTime);
            _newRatePerSec = uint64((_currentRatePerSec * _decayGrowth) / INT_HALF_LIFE);
            if(_newRatePerSec < MIN_INT) {
                _newRatePerSec = MIN_INT;
            }
            
        } else if (_utilization > MAX_UTIL) {
            uint256 _deltaUtilization = ((_utilization - MAX_UTIL) * 1e18) / (UTIL_PREC - MAX_UTIL);
            uint256 _decayGrowth = INT_HALF_LIFE + (_deltaUtilization * _deltaUtilization * _deltaTime);
            _newRatePerSec = uint64((_currentRatePerSec * _decayGrowth) / INT_HALF_LIFE);
            if(_newRatePerSec > MAX_INT){
                _newRatePerSec = MAX_INT;
            }
        } else {
            _newRatePerSec = _currentRatePerSec;
        }
    }   

}