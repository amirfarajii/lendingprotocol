// SPDX-License-Identifier: ISC
pragma solidity ^0.8.15;

struct VaultAccount {
    uint128 amount; //tatal amount, like marketcap
    uint128 shares; //total shares, like shares outstanding
}

//title VaultAccount library
library VaultAccountingLibrary {

    function toShares(VaultAccount memory total, uint256 amount, bool roundUp) internal pure returns(uint256 shares) {
        if(total.shares == 0) {
            shares = amount;
        } else {
            shares = (amount * total.shares) / total.amount;
            if(roundUp && (amount * total.shares) / total.amount < amount) {
                shares = shares + 1;
            }
        }

    }

    function toAmount(VaultAccount memory total, uint256 shares, bool roundUp) internal pure returns(uint256 amount) {
        if(total.amount == 0) {
            amount  = shares;
        } else {
            amount = (shares * total.amount) / total.shares;
            if(roundUp && (amount * total.shares) / total.amount < amount) {
                amount = amount + 1;
            }
        }
    }
}