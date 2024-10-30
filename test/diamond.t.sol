// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
// import "../contracts/facets/NftFacet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {LibLending} from "../contracts/libraries/LibLending.sol";


contract MockNFT is ERC721URIStorage {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _mint(to, tokenId); 
        return tokenId;
    }
}

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract DiamondNFTLendingTest is Test {
    Diamond public diamond;
    NFTFacet public nftFacet;
    LendingFacet public lendingFacet;
    MockNFT public mockNFT;
    MockToken mockToken;
    
    address borrower = address(1);
    address lender = address(2);
    
    function setUp() public {

        // Deploy mock NFT
        mockNFT = new MockNFT();
        // mockToken = new MockToken();

        // Deploy facets
        nftFacet = new NFTFacet();
        lendingFacet = new LendingFacet();
        
        // Deploy diamond with facets
        diamond = new Diamond(address(nftFacet), address(lendingFacet));
        
        bytes4[] memory functionSelectors = new bytes4[](3);
        functionSelectors[0] = LendingFacet.createLoan.selector;
        functionSelectors[1] = LendingFacet.repayLoan.selector;
        functionSelectors[2] = LendingFacet.liquidateLoan.selector;
        
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        for (uint i = 0; i < functionSelectors.length; i++) {
            ds.selectorToFacetAndPosition[functionSelectors[i]].facetAddress = address(lendingFacet);
        }
        
        // Setup lending storage
        LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        ls.supportedNFTs[address(mockNFT)] = true;
        // ls.lendingToken = IERC20(address(mockToken));


        // Setup test accounts
        vm.deal(borrower, 100 ether);
        vm.deal(lender, 100 ether);
        
        // Setup test data
        mockNFT.mint(borrower);
        mockToken.mint(address(diamond), 100 ether);
        vm.prank(borrower);
        mockNFT.approve(address(diamond), 1);
    }
    
    function testNFTDeposit() public {
        // Mint NFT to borrower
        uint256 tokenId = mockNFT.mint(borrower);
        
        // Approve diamond contract
        vm.prank(borrower);
        mockNFT.approve(address(diamond), tokenId);
        
        // Deposit NFT
        vm.prank(borrower);
        NFTFacet(address(diamond)).depositNFT(address(mockNFT), tokenId);
        
        assertEq(mockNFT.ownerOf(tokenId), address(diamond));
    }
    
     function testCreateLoan() public {
        vm.startPrank(borrower);
        
        uint256 loanAmount = 1 ether;
        uint256 duration = 30 days;
        
        LendingFacet(address(diamond)).createLoan(
            address(mockNFT),
            1,
            loanAmount,
            duration
        );
        
        LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        LibLending.Loan memory loan = ls.loans[0];
        
        assertEq(loan.borrower, borrower);
        assertEq(loan.nftId, 1);
        assertEq(loan.amount, loanAmount);
        assertTrue(loan.active);
        
        vm.stopPrank();
    }
    
    function testRepayLoan() public {
        // First create a loan
        vm.startPrank(borrower);
        
        uint256 loanAmount = 1 ether;
        uint256 duration = 30 days;
        
        uint256 loanId = LendingFacet(address(diamond)).createLoan(
            address(mockNFT),
            1,
            loanAmount,
            duration
        );
        
        // Now repay the loan
        mockToken.approve(address(diamond), loanAmount * 2); // Approve for loan + interest
        LendingFacet(address(diamond)).repayLoan(loanId);
        
        LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        LibLending.Loan memory loan = ls.loans[loanId];
        
        assertFalse(loan.active);
        assertEq(mockNFT.ownerOf(1), borrower);
        
        vm.stopPrank();
    }
    
    function testLiquidateLoan() public {
        // Create loan
        vm.startPrank(borrower);
        uint256 loanId = LendingFacet(address(diamond)).createLoan(
            address(mockNFT),
            1,
            1 ether,
            30 days
        );
        vm.stopPrank();
        
        // Advance time past duration
        vm.warp(block.timestamp + 31 days);
        
        // Liquidate
        LendingFacet(address(diamond)).liquidateLoan(loanId);
        
        LibLending.LendingStorage storage ls = LibLending.lendingStorage();
        LibLending.Loan memory loan = ls.loans[loanId];
        
        assertFalse(loan.active);
        assertEq(mockNFT.ownerOf(1), address(this));
    }
}