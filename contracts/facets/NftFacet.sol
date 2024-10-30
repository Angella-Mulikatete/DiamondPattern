// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibLending } from "../libraries/LibLending.sol";
import { ERC721 } from "../interfaces/IERC721.sol";

contract NFTFacet {
    using LibDiamond for LibDiamond.DiamondStorage;
    using LibLending for LibLending.LendingStorage;
    
    event NFTDeposited(address indexed owner, address indexed nftContract, uint256 tokenId);
    event NFTWithdrawn(address indexed owner, address indexed nftContract, uint256 tokenId);
    
    function depositNFT(address _nftContract, uint256 _tokenId) external {
        ERC721 nft = ERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        
        nft.transferFrom(msg.sender, address(this), _tokenId);
        emit NFTDeposited(msg.sender, _nftContract, _tokenId);
    }
    
    // function withdrawNFT(address _nftContract, uint256 _tokenId) external {
    //     LibLending.LendingStorage storage ls = LibLending.lendingStorage();
    //     require(ls.nftToLoan[_nftContract][_tokenId] == 0, "NFT is locked in loan");
        
    //     ERC721 nft = ERC721(_nftContract);
    //     require(nft.ownerOf(_tokenId) == address(this), "NFT not in contract");
        
    //     nft.transferFrom(address(this), msg.sender, _tokenId);
    //     emit NFTWithdrawn(msg.sender, _nftContract, _tokenId);
    // }
}