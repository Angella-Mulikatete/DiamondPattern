// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "../interfaces/IReentrancy.sol";
import  {ERC721Facet} from "../facets/ERC721Facet.sol";
import {MerkleFacet} from "../facets/MerkleFacet.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract PresaleFacet is ReentrancyGuard {
    ERC721Facet public nftContract;
    MerkleFacet public merkleDistributor;


    event Purchased(uint256 indexed amount, address buyer);


    function setPresale(uint256 _price, uint256 _minPurchase, uint256 _maxPurchase) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.preSalePrice = _price;
        ds.minPurchaseAmount = _minPurchase;
        ds.maxPurchaseAmount = _maxPurchase;
    }


   function buyPresale(uint256 _amount) external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(_amount >= ds.minPurchaseAmount, "Below minimum purchase amount");
        require(_amount <= ds.maxPurchaseAmount, "Exceeds maximum purchase amount");
        require(msg.value >= _amount * ds.preSalePrice, "Insufficient payment");

        for (uint256 i = 0; i < _amount; i++) {
            ERC721Facet(address(this)).safeMint(msg.sender, ds.totalSupply);
            ds.totalSupply++;
        }
    }
}
