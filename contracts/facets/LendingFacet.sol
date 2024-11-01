// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";
// import { LibLending } from "../libraries/LibLending.sol";
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
         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.loans[loanId].active, "Loan not active");
        _;
    }
    
      function createLoan(
        address nftContract,
        uint256 nftId,
        uint256 amount,
        uint256 duration
    ) external nonReentrant returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(ds.supportedNFTs[nftContract], "NFT not supported");
        require(amount > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        // Transfer NFT collateral
        ERC721(nftContract).transferFrom(msg.sender, address(this), nftId);

        uint256 loanId = ds.totalLoans++;
        uint256 interest = calculateInterest(amount, duration);

        ds.loans[loanId] = LibDiamond.Loan({
            borrower: msg.sender,
            nftId: nftId,
            nftContract: nftContract,
            amount: amount,
            interest: interest,
            startTime: block.timestamp,
            duration: duration,
            active: true
        });

        ds.lendingToken.safeTransfer(msg.sender, amount);

        emit LoanCreated(loanId, msg.sender, amount);
        return loanId;
    }
    
    function repayLoan(uint256 loanId) external nonReentrant onlyActiveLoan(loanId) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        LibDiamond.Loan storage loan = ds.loans[loanId];
        
        require(msg.sender == loan.borrower, "Not loan borrower");
        
        uint256 totalRepayment = loan.amount + loan.interest;
        ds.lendingToken.safeTransferFrom(msg.sender, address(this), totalRepayment);
        
        ERC721(loan.nftContract).transferFrom(address(this), msg.sender, loan.nftId);
        
        loan.active = false;
        
        emit LoanRepaid(loanId);
    }
    
    function liquidateLoan(uint256 loanId) external nonReentrant onlyActiveLoan(loanId) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Loan storage loan = ds.loans[loanId];
        
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





// import "forge-std/Test.sol";
// import { LendingFacet } from "../src/LendingFacet.sol";
// import { LibDiamond } from "../src/libraries/LibDiamond.sol";
// import { IERC20 } from "../src/interfaces/IERC20.sol";
// import { ERC721 } from "../src/interfaces/IERC721.sol";
// import { MockERC20 } from "../test/mocks/MockERC20.sol";
// import { MockERC721 } from "../test/mocks/MockERC721.sol";

// contract LendingFacetTest is Test {
//     LendingFacet public lendingFacet;
//     MockERC20 public lendingToken;
//     MockERC721 public nft;

//     address borrower = address(0x123);
//     uint256 nftId = 1;
//     uint256 loanAmount = 1000 ether;
//     uint256 loanDuration = 30 days;

//     function setUp() public {
//         // Deploy mocks and the lending facet
//         lendingToken = new MockERC20("LendingToken", "LEND", 18);
//         nft = new MockERC721("NFT", "NFT");
//         lendingFacet = new LendingFacet();

//         // Mint tokens and approve to lendingFacet
//         lendingToken.mint(borrower, loanAmount);
//         lendingToken.approve(address(lendingFacet), loanAmount);

//         // Mint an NFT to the borrower
//         nft.mint(borrower, nftId);

//         // Configure lendingFacet to accept this NFT as collateral
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//         ds.supportedNFTs[address(nft)] = true;
//         ds.lendingToken = IERC20(address(lendingToken));

//         // Transfer token balance to lendingFacet to fund loans
//         lendingToken.mint(address(lendingFacet), loanAmount * 10);
//     }

//     function testCreateLoan() public {
//         vm.startPrank(borrower);

//         nft.approve(address(lendingFacet), nftId);

//         uint256 loanId = lendingFacet.createLoan(address(nft), nftId, loanAmount, loanDuration);

//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//         LibDiamond.Loan memory loan = ds.loans[loanId];

//         assertEq(loan.borrower, borrower, "Loan borrower should match");
//         assertEq(loan.nftId, nftId, "NFT ID should match");
//         assertEq(loan.amount, loanAmount, "Loan amount should match");
//         assertTrue(loan.active, "Loan should be active");

//         vm.stopPrank();
//     }

//     function testCannotCreateLoanWithUnsupportedNFT() public {
//         vm.startPrank(borrower);

//         MockERC721 unsupportedNFT = new MockERC721("UnsupportedNFT", "UNFT");
//         unsupportedNFT.mint(borrower, nftId);
//         unsupportedNFT.approve(address(lendingFacet), nftId);

//         vm.expectRevert("NFT not supported");
//         lendingFacet.createLoan(address(unsupportedNFT), nftId, loanAmount, loanDuration);

//         vm.stopPrank();
//     }

//     function testRepayLoan() public {
//         vm.startPrank(borrower);

//         nft.approve(address(lendingFacet), nftId);
//         uint256 loanId = lendingFacet.createLoan(address(nft), nftId, loanAmount, loanDuration);

//         // Calculate total repayment
//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//         LibDiamond.Loan memory loan = ds.loans[loanId];
//         uint256 totalRepayment = loan.amount + loan.interest;

//         lendingToken.mint(borrower, totalRepayment);
//         lendingToken.approve(address(lendingFacet), totalRepayment);

//         lendingFacet.repayLoan(loanId);

//         assertEq(lendingToken.balanceOf(borrower), 0, "Borrower should have repaid");
//         assertEq(nft.ownerOf(nftId), borrower, "NFT should be returned to borrower");

//         vm.stopPrank();
//     }

//     function testOnlyBorrowerCanRepayLoan() public {
//         vm.startPrank(borrower);

//         nft.approve(address(lendingFacet), nftId);
//         uint256 loanId = lendingFacet.createLoan(address(nft), nftId, loanAmount, loanDuration);

//         vm.stopPrank();
//         vm.startPrank(address(0x456)); // Some other address

//         vm.expectRevert("Not loan borrower");
//         lendingFacet.repayLoan(loanId);

//         vm.stopPrank();
//     }

//     function testLiquidateLoan() public {
//         vm.startPrank(borrower);

//         nft.approve(address(lendingFacet), nftId);
//         uint256 loanId = lendingFacet.createLoan(address(nft), nftId, loanAmount, loanDuration);

//         // Simulate loan expiration
//         vm.warp(block.timestamp + loanDuration + 1);

//         vm.stopPrank();
//         vm.startPrank(address(0x456)); // Liquidator

//         lendingFacet.liquidateLoan(loanId);

//         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
//         assertFalse(ds.loans[loanId].active, "Loan should be inactive");
//         assertEq(nft.ownerOf(nftId), address(0x456), "NFT should be transferred to liquidator");

//         vm.stopPrank();
//     }

//     function testCannotLiquidateActiveLoan() public {
//         vm.startPrank(borrower);

//         nft.approve(address(lendingFacet), nftId);
//         uint256 loanId = lendingFacet.createLoan(address(nft), nftId, loanAmount, loanDuration);

//         vm.stopPrank();
//         vm.startPrank(address(0x456)); // Liquidator

//         vm.expectRevert("Loan not yet eligible for liquidation");
//         lendingFacet.liquidateLoan(loanId);

//         vm.stopPrank();
//     }
// }




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