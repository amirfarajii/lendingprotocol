// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;


//dependencies
import "./dependencies/openzeppelin/ERC20.sol";
import "./dependencies/openzeppelin/IERC20.sol";
import "./dependencies/openzeppelin/ReentrancyGuard.sol";
import "./dependencies/openzeppelin/Pausable.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./dependencies/openzeppelin/SafeCast.sol";
import "./dependencies/chainlink/AggregatorV3Interface.sol";
import "./dependencies/openzeppelin/SafeERC20.sol";

import "./LendConstant.sol";
import "./libraries/VaultAccount.sol";

import "./interfaces/IERC4626.sol";
import "./interfaces/ILendWhitelist.sol";
import "./interfaces/IRateCalculator.sol";
import "./interfaces/ISwapper.sol";

abstract contract Core is LendConstant, IERC4626, ERC20, Ownable, ReentrancyGuard, Pausable{
    // frist and frist add library 
    using VaultAccountingLibrary for VaultAccount;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    string public version = "1.0.0";

    //Setting set by constructor() & initialize()
    //------------------------------------

    //Asset and collateral contracts
    IERC20 internal immutable assetContract;
    IERC20 internal immutable collateralContract;
    
    //Oracle
    address public immutable oracleMultiply;
    address public immutable oracleDivid;
    address public immutable oracleNormalization;

    //LTV Setting
    uint256 public immutable maxLTV;

    //Liqudiation Fee;
    uint256 public immutable cleanLiqudationFee;
    uint256 public immutable dirtyLiqudationFee;

    //Calculator APR 
    IRateCalculater public immutable rateContract; //Linear & Variable ...?
    bytes public rateInitCallData;










}