// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibLending } from "../libraries/LibLending.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import { SafeERC20 } from "../libraries/LibSafeErc20.sol";
import {ReentrancyGuard} from "../interfaces/IReentrancy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "../interfaces/IERC721.sol";


contract LendingFacet is ReentrancyGuard {
     using SafeERC20 for IERC20;
    
    event LoanCreated(uint256 indexed loanId, address borrower, uint256 amount);
    event LoanRepaid(uint256 indexed loanId);
    event NFTLiquidated(uint256 indexed loanId);
    
    modifier onlyActiveLoan(uint256 loanId) {
        require(LibLending.lendingStorage().loans[loanId].active, "Loan not active");
        _;
    }
    
    function createLoan(
        address nftContract,
        uint256 nftId,
        uint256 amount,
        uint256 duration
    ) external nonReentrant returns (uint256) {
        LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        
        require(ls.supportedNFTs[nftContract], "NFT not supported");
        require(amount > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        
        ERC721(nftContract).transferFrom(msg.sender, address(this), nftId);
        
        uint256 loanId = ls.totalLoans++;
        uint256 interest = calculateInterest(amount, duration);
        
        ls.loans[loanId] = LibLending.Loan({
            borrower: msg.sender,
            nftId: nftId,
            nftContract: nftContract,
            amount: amount,
            interest: interest,
            startTime: block.timestamp,
            duration: duration,
            active: true
        });
        
        ls.lendingToken.safeTransfer(msg.sender, amount);
        
        emit LoanCreated(loanId, msg.sender, amount);
        return loanId;
    }
    
    function repayLoan(uint256 loanId) external nonReentrant onlyActiveLoan(loanId) {
        LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        LibLending.Loan storage loan = ls.loans[loanId];
        
        require(msg.sender == loan.borrower, "Not loan borrower");
        
        uint256 totalRepayment = loan.amount + loan.interest;
        ls.lendingToken.safeTransferFrom(msg.sender, address(this), totalRepayment);
        
        ERC721(loan.nftContract).transferFrom(address(this), msg.sender, loan.nftId);
        
        loan.active = false;
        
        emit LoanRepaid(loanId);
    }
    
    function liquidateLoan(uint256 loanId) external nonReentrant onlyActiveLoan(loanId) {
        LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        LibLending.Loan storage loan = ls.loans[loanId];
        
        require(
            block.timestamp > loan.startTime + loan.duration,
            "Loan not yet eligible for liquidation"
        );
        
        loan.active = false;
        // In a real implementation, this would trigger an auction
        // For simplicity, we're just transferring the NFT to the liquidator
       ERC721(loan.nftContract).transferFrom(address(this), msg.sender, loan.nftId);
        
        emit NFTLiquidated(loanId);
    }
    
    function calculateInterest(uint256 amount, uint256 duration) internal pure returns (uint256) {
        // Simple interest calculation: 10% APR
        return (amount * 10 * duration) / (365 days * 100);
    }
}





// contract LendingFacet is ReentrancyGuard {
//     using LibLending for LibLending.LendingStorage;
    
//     event LoanCreated(uint256 indexed loanId, address borrower, address lender, uint256 amount);
//     event LoanRepaid(uint256 indexed loanId);
//     event CollateralClaimed(uint256 indexed loanId, address lender);
    
//     function createLoan(
//         address _nftContract,
//         uint256 _tokenId,
//         uint256 _duration
//     ) external payable nonReentrant {
//         LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        
//         require(msg.value > 0, "Loan amount must be greater than 0");
//         require(IERC721(_nftContract).ownerOf(_tokenId) == address(this), "NFT not deposited");
        
//         uint256 loanId = ++ls.loanCount;
//         ls.loans[loanId] = LibLending.Loan({
//             borrower: msg.sender,
//             lender: address(0),
//             nftContract: _nftContract,
//             tokenId: _tokenId,
//             amount: msg.value,
//             duration: _duration,
//             startTime: block.timestamp,
//             active: true,
//             repaid: false
//         });
        
//         ls.nftToLoan[_nftContract][_tokenId] = loanId;
//         emit LoanCreated(loanId, msg.sender, address(0), msg.value);
//     }
    
//     function repayLoan(uint256 _loanId) external payable nonReentrant {
//         LibLending.LendingStorage storage ls = LibLending.lendingStorage();
//         LibLending.Loan storage loan = ls.loans[_loanId];
        
//         require(loan.active, "Loan not active");
//         require(msg.value >= loan.amount, "Insufficient repayment");
//         require(msg.sender == loan.borrower, "Not borrower");
        
//         loan.active = false;
//         loan.repaid = true;
        
//         // Transfer NFT back to borrower
//         IERC721(loan.nftContract).transferFrom(address(this), loan.borrower, loan.tokenId);
        
//         // Transfer repayment to lender
//         payable(loan.lender).transfer(loan.amount);
        
//         // Refund excess payment
//         if (msg.value > loan.amount) {
//             payable(msg.sender).transfer(msg.value - loan.amount);
//         }
        
//         emit LoanRepaid(_loanId);
//     }
    
//     function claimCollateral(uint256 _loanId) external nonReentrant {
//         LibLending.LendingStorage storage ls = LibLending.lendingStorage();
//         LibLending.Loan storage loan = ls.loans[_loanId];
        
//         require(loan.active, "Loan not active");
//         require(block.timestamp > loan.startTime + loan.duration, "Loan not defaulted");
//         require(msg.sender == loan.lender, "Not lender");
        
//         loan.active = false;
        
//         // Transfer NFT to lender
//         IERC721(loan.nftContract).transferFrom(address(this), loan.lender, loan.tokenId);
        
//         emit CollateralClaimed(_loanId, loan.lender);
//     }
// }