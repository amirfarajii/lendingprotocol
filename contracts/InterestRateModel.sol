// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract InterestRateModel{

    bool public constant IS_INTRESTRATEMODEL = true;

    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns(uint);

    function getSupplyRate(uint cash, uint barrows, uint reserves, uint reservesFactoryMantinssa) virtual external view returns(uint);



}