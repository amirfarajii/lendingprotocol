// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

/*
** 14 August 2022
** forket from FraxLend
*/

import "./interfaces/IRateCalculator.sol";


// A formula for calculating interest rate linearly as a function of utilization;

contract LinearInterestRate {


    

    uint256 private constant MIN_INT = 0; //0% annual  rate
    uint256 private constant MAX_INT = 146248508681; //10% annual rate
    uint256 private constant MAX_VERTEX_UTIL = 1e5; //100%
    uint256 private constant UTIL_PREC = 1e5;


    //Name of contract 
    function name() external pure returns(string memory){
        return "Linear Interest Rate";
    }

    function getConstants() external pure returns(bytes memory _calldata) {
        return abi.encode(MIN_INT, MAX_INT, MAX_VERTEX_UTIL, UTIL_PREC);
    }

    //@param _initData abi.encode(uint256 _minInterest, uint256 _vertexInterest, uint256 _maxInterest, uint256 _vertexUtilization)
    function requireValidInitData(bytes calldata _initData) public pure {
        (uint256 _minInterest, uint256 _vertexInterest, uint256 _maxInterest, uint256 _vertexUtilization) = abi.decode(
            _initData,
            (uint256, uint256, uint256, uint256)
        );
        require(
            _minInterest < MAX_INT && _minInterest <= _vertexInterest && _minInterest >= MIN_INT,
            "LinearInterestRate: _minInterest < MAX_INT && _minInterest <= _vertexInterest && _minInterest >= MIN_INT"
        );
        require(
            _maxInterest <= MAX_INT && _vertexInterest <=_maxInterest && _maxInterest > MIN_INT,
            "LinearInterestRate: maxInterest <= MAX_INT && _vertexInterest <=_maxInterest && _maxInterest > MIN_INT"
        );
        require(
            _vertexUtilization < MAX_VERTEX_UTIL && _vertexUtilization > 0,
            "LinearInterestRate: _vertexUtilization < MAX_VERTEX_UTIL && _vertexUtilization > 0"
        );
    }

    //calculates interest rates using two linear functions
    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns(uint64 _newRatePerSec) {
        requireValidInitData(_initData);
        (, , uint256 _utilization, ) = abi.decode(_data, (uint64, uint256, uint256, uint256));
        (uint256 _minInterest, uint256 _vertexInterest, uint256 _maxInterest, uint256 _vertexUtilization)  = abi.decode(
            _initData,
            (uint256, uint256, uint256, uint256)
        );
        if(_utilization < _vertexUtilization) {
            uint256 _slop = (((_vertexInterest - _minInterest) * UTIL_PREC) / _vertexUtilization);
            _newRatePerSec = uint64(_minInterest + ((_utilization * _slop) / UTIL_PREC));
            
        } else if(_utilization > _vertexUtilization) {
            uint256 _slop = (((_maxInterest - _vertexInterest) * UTIL_PREC) / (UTIL_PREC - _vertexUtilization));
            _newRatePerSec = uint64(_vertexInterest + (((_utilization - _vertexUtilization) * _slop) / UTIL_PREC));
        } else {
            _newRatePerSec = uint64(_vertexUtilization);
        }

    }
}