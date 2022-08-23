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

    //swapper
    mapping(address => bool) public swappers; // approved swapper addressers

    //deployers
    address public immutable DEPLOYER_ADDRESS;

    //admin contracts
    address public immutable CIRCUIT_BREAKER_ADDRESS;
    address public immutable COMPTROLLER_ADDRESS;
    address public TIME_LOCK_ADDRESS;

    // Dependencies
    address public immutable LEND_WHITELIST_ADDRESS;


    //ERC20 token name, accessible via name()
    string internal nameOfContract;

    // Matury Date & Penalty Interest Rate (per sec)
    uint256 public immutable maturityDate;
    uint256 public immutable penaltyRate;


    //==============================================================================
    //Storage
    //==============================================================================


    //@notice Stores information about the current interest rate;
    //@dev struct is packed to reduce SLOADs. feeToProtocolRate is 1e5 precision, ratePerSec is 1e18 precision
    CurrentRateInfo public currentRateInfo;
    struct  CurrentRateInfo {
        uint64 lastBlock;
        uint65 feeToProtocolRate; //Fee amount 1e5 precision
        uint64 lastTimestamp;
        uint64 ratePerSec;
    }

    ExchangeRateInfo public exchangeRateIfo;
    struct ExchangeRateIfo {
        uint64 lastTimeStamp;
        uint224 exchangeRate; // collateral: asset ratio. i.e. how much collateral to buy 1e18 asset

    }


    // Contract Level Accounting
    VaultAccount public totalAsset; // amount = total amount of assets, shares = total shares outstanding
    VaultAccount public totalBorrow; // amount = total barrow amount with interest accrued, shares = total shares outstanding
    uint256 public totalCollateral; // total amount of collateral in contract

    //User Level Accounting
    // @notic Stores the balace of collateral for each user;
    mapping(address => uint256) public userCollateralBalance;
    // notice Stores the balance of borrow  shares for each user;
    mapping(address => uint256) public userBorrowShares;

    // Internal Whitelists;
    bool public immutable borrowerWhitelistActive;
    mapping(address => bool) public approvedBorrowers;

    bool public immutable lenderWhitelistActive;
    mapping(address => bool) public approvedLender;

    //===============================================================================
    //Initialize
    //===============================================================================

    
    /* 
    ** @param _configData => abi.encode(address _asset, address _collateral, address _oracleMultiply, address _oracleDivide,
    ** uint256 _oracleNormalization, address _rateContract, bytes memory _rateInitData)
    ** @param _maxLTV => The maximum Loan-to-Value for a Barrower to be considered solvent (1e5 precision)
    ** @param _liqudationFee => The fee paid to liqudators given as a % of the payment (1e5 precision)
    ** @param _maturityData =>  The maturityData date for the pair
    ** @param _penaltyRae => The interest rate after maturity date
    ** @param _isBorrowerWhitelistActive => Enables brrower whitelist
    ** @param _isLenderWhitelistActive => Enable borrower whitelist
    */
    constructor(
        bytes memory _configData,
        bytes memory _immutables,
        uint256 _maxLTV,
        uint256 _liqudationFee,
        uint256 _maturityData,
        uint256 _penaltyRae,
        bool _isBorrowerWhitelistActive,
        bool _isLenderWhitelistActive
    ) {
        //handle Immutable configuration
        {
            (
                address _circuitBreaker,
                address _comptrollerAddress,
                address _timeLockAddress,
                address _fraxlendWhitelistAddress
            ) = abi.decode(_immutables, (address, address, address, address));
            DEPLOYER_ADDRESS = msg.sender;
            CIRCUIT_BREAKER_ADDRESS = _circuitBreaker;
            CCOMPTROLLER_ADDRESS = _comptrollerAddress;
            TIME_LOCK_ADDRESS = _timeLockAddress;
            FRAXLEND_WHITELIST_ADDRESS = _fraxlendWhitelistAddress;


        }

        {
            (
                address _asset,
                address _collateral,
                address _oracleMultiply,
                address _oracleDivide,
                uint256 _oracleNormalization,
                address _rateContract, 
            ) = abi.decode(_configData, (address, address, address, address, uint256, address));

            // Pair Settings
            assetContract  = IERC20(_asset);
            collateralContract = IERC20(_collateral);
            currentRateInfo.feeToProtocolRate = DEFUALT_PROTOCOL_FEE;
            cleanLiqudationFee = _liqudationFee;
            dirtyLiqudationFee = (_liqudationFee * 90000) / LIQ_PRECISION; //90 % of clean fee
            if (_maxLTV >= LTV_PRECISION && !_isBorrowerWhitelistActive) revert BorrowerWhitelistRequired();
            maxLtv = _maxLTV;

            //swapper Settings 
            swappers[SWAP_ROUTER_ADDRESS] = true;

            //Oracle Sttings
            {
                ILendWhitelist _lendWhitelist = ILendWhitelist(LEND_WHITELIST_ADDRESS);
                // check that oracles on the whitelist
                if (_oracleMultiply != address(0) && !lendWhitelist.oracleContractWhitelist(_oracleMultiply)) {
                    revert NotOnWhitelist(_oracleMultiply);
                }
                if (_oracleDivide != address(0) && !_lendWhitelist.oracleContractWhitelist(_oracleDivide)) {
                    revert NotOnWhitelist(_oracleDivide);
                }

                // Write oracleData to storage
                oracleMultiply = _oracleMultiply;
                oracleDivid = _oracleDivid;
                oracleNormalization = _oracleNormalization;

                //Rate Settings 
                if(!_lendWhitelist.rateContractWhitelist(_rateContract)) {
                    revert NotOnWhitelist(_rateContract);
                
                }
            }
            rateContract = IRateCalculater(_rateContract);

        }
        // Set approved borrowers Whitelist active
        borrowerWhitelistActive = _isBorrowerWhitelistActive;

        // Set approved lenders Whitelist active
        lenderWhitelistActive = _isLenderWhitelistActive;

        // Set matury date & penalty interest rate
        maturityDate = _maturityData;
        penaltyRate = _penaltyRae;
    }





































































}