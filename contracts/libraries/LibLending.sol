// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibLending {
    bytes32 constant LENDING_STORAGE_POSITION = keccak256("diamond.standard.lending.storage");
    
    struct Loan {
        address borrower;
        address lender;
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        uint256 duration;
        uint256 startTime;
        bool active;
        bool repaid;
    }
    
    struct LendingStorage {
        mapping(uint256 => Loan) loans;
        uint256 loanCount;
        mapping(address => mapping(uint256 => uint256)) nftToLoan;
    }
    
    function lendingStorage() internal pure returns (LendingStorage storage ls) {
        bytes32 position = LENDING_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }
}
