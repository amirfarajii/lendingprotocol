// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

abstract contract LendConstant{

    //Precision settings
    uint256 internal constant LTV_PRECISION = 1e5; //  5 decimals
    uint256 internal constant LIQ_PRECISION = 1e5;
    uint256 internal constant UTIL_PREC = 1e5;
    uint256 internal constant FEE_PRECISION = 1e5;
    uint256 internal constant EXCHANGE_PRECISION = 1e5;

   uint64 internal constant  DEFAULT_INT = 158247046; // 0.5% annual rate 1e18 precision

   //Dependencies 
   //It just for test
   address internal constant SWAP_ROUTER_ADDRESS = 0xE52D0337904D4D0519EF7487e707268E1DB6495F;
    //Protocol fee
    uint16 internal constant DEFAULT_PROTOCOL_FEE = 0; // 1e5 precision
    uint256 internal constant MAX_PROTOCOL_FEE = 5e4; // 50% with 1e5 precision


    //error

}