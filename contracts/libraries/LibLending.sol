// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "../interfaces/IERC20.sol";



library LibLending {
    bytes32 constant LENDING_STORAGE_POSITION = keccak256("diamond.standard.lending.storage");
    
      struct Loan {
        address borrower;
        uint256 nftId;
        address nftContract;
        uint256 amount;
        uint256 interest;
        uint256 startTime;
        uint256 duration;
        bool active;
    }
    
    struct LendingStorage {
        mapping(uint256 => Loan) loans;
        uint256 totalLoans;
        mapping(address => bool) supportedNFTs;
        mapping(address => uint256) collateralFactors;
        IERC20 lendingToken;
    }
    function lendingStorage() internal pure returns (LendingStorage storage ls) {
        bytes32 position = LENDING_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

       // struct LendingStorage {
    //     mapping(uint256 => Loan) loans;
    //     uint256 loanCount;
    //     mapping(address => mapping(uint256 => uint256)) nftToLoan;
    // }
}
