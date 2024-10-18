// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "../interfaces/IReentrancy.sol";
import  {ERC721Facet} from "../interfaces/IERC721.sol";

contract PresaleFacet is ReentrancyGuard {
    ERC721Facet public nftContract;
    MerkleFacet public merkleDistributor;


    event Purchased(uint256 indexed amount, address buyer);

    constructor(address _nftContract, address _merkleDistributor) {
        nftContract = ERC721Facet(_nftContract);
        merkleDistributor = MerkleFacet(_merkleDistributor);
        LibDiamond.DiamondStorage storage ds = new DiamondStorage();
        ds.TOKENS_PER_ETHER = 30;
        ds.minPurchaseAmount = 0.01 ether;
    }

    function purchaseTokens(uint256 _amount) external payable nonReentrant {
        require(msg.value >= minPurchaseAmount * _amount, "Insufficient payment");
        require(msg.value % minPurchaseAmount == 0, "Payment amount must be divisible by minimum");

        uint256 tokensToReceive = _amount * TOKENS_PER_ETHER;
        uint256 remainingEther = msg.value - (msg.value / TOKENS_PER_ETHER);

        for (uint256 i = 0; i < _amount; i++) {
            merkleDistributor.distributeToken(new bytes32[](0));
            nftContract.mintToken("", "", msg.value / TOKENS_PER_ETHER);
        }

        payable(owner()).transfer(remainingEther);
        emit Purchased(_amount, msg.sender);
    }
}
