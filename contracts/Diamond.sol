// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
// import {LibLending} from "./libraries/libLending.sol";
import {NFTFacet} from "../contracts/facets/NftFacet.sol";
import {LendingFacet} from "../contracts/facets/LendingFacet.sol";

contract Diamond {
    // ERC20Storage public token;
    constructor(address _nftFacet, address _lendingFacet) payable {
          LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Add Nft Facet
        bytes4[]  memory nftSelectors = new bytes4[](2);
        nftSelectors[0] = NFTFacet.depositNFT.selector;


        for(uint i = 0; i < nftSelectors.length; i++) {
            ds.selectorToFacetAndPosition[nftSelectors[i]].facetAddress = _nftFacet;
            ds.facetFunctionSelectors[_nftFacet].functionSelectors.push(nftSelectors[i]);
            
        }

         
        // Add Lending Facet
        bytes4[] memory lendingSelectors = new bytes4[](3);
        lendingSelectors[0] = LendingFacet.createLoan.selector;
        lendingSelectors[1] = LendingFacet.repayLoan.selector;
        lendingSelectors[2] = LendingFacet.liquidateLoan.selector;
        
        for(uint i = 0; i < lendingSelectors.length; i++) {
            ds.selectorToFacetAndPosition[lendingSelectors[i]].facetAddress = _lendingFacet;
            ds.facetFunctionSelectors[_lendingFacet].functionSelectors.push(lendingSelectors[i]);
        }

    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    //immutable function example
    function example() public pure returns (string memory) {
        return "THIS IS AN EXAMPLE OF AN IMMUTABLE FUNCTION";
    }

    receive() external payable {}
}
