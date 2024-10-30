// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
// import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";
// import "../contracts/facets/NftFacet.sol";

// import "../contracts/facets/ERC721Facet.sol";
// import "../contracts/facets/MerkleFacet.sol";
// import "../contracts/facets/PreSaleFacet.sol";


contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    // OwnershipFacet ownerF;
    NFTFacet nftFacet;
    LendingFacet lendingFacet;
    // MerkleFacet merkleFacet;
    // PresaleFacet presaleFacet;

    function testDeployDiamond() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(nftFacet), address(lendingFacet));
        dLoupe = new DiamondLoupeFacet();
        // ownerF = new OwnershipFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(nftFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("NFTFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(lendingFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LendingFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
