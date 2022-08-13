// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./InterestRateModel.sol";

contract JumpRateModel is InterestRateModel {
    event NewInterestParams(uint baseRatePerBlock, uint multiplierPerBlock, uint jumpMultiplierPerBlock, uint kink);
    uint private constant BASE = 1e18;
    uint public constant blocksPerYear = 2102400;
    uint public multiplierPerBlock;
    uint public baseRatePerBlock;
    uint public jumpMultiplierPerBlock;
    uint public kink;

    constructor(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_){
        baseRatePerBlock = baseRatePerYear / blocksPerYear;
        multiplierPerBlock = multiplierPerYear / blocksPerYear;
        jumpMultiplierPerBlock = jumpMultiplierPerYear / blocksPerYear;
        kink = kink_;
        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    }

    function utilizationRate(uint cash, uint barrows, uint reserves) public pure returns(uint) {
        if(barrows == 0) {
            return 0;
        }

        return barrows * BASE / (cash + barrows - reserves);
    }

    function getBorrowRate(uint cash, uint borrows, uint reserves) override public view returns (uint) {
        uint util = utilizationRate(cash, borrows, reserves);
        if(util <= kink) {
            return (util *multiplierPerBlock / BASE) + baseRatePerBlock;
        } else {
            uint normalRate = (kink * multiplierPerBlock / BASE) + baseRatePerBlock;
            uint excessUtil = util - kink;
            return (excessUtil * jumpMultiplierPerBlock / BASE) + normalRate;
        }
    }

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) override public view returns(uint) {
        uint oneMinusReserveFactor = BASE - reserveFactorMantissa;
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate * oneMinusReserveFactor / BASE;
        return utilizationRate(cash, borrows, reserves) * rateToPool / BASE;
    }

    
    

}