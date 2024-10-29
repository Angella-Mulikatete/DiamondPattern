// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../interfaces/IERC20.sol";
import { MerkleProof } from "../interfaces/IMerkle.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import './ERC721Facet.sol';


contract MerkleFacet{

    constructor(address _tokenAddress, bytes32 _merkleRoot){
        require(_tokenAddress != address(0),"invalid address");
        require(_merkleRoot != bytes32(0),"invalid merkle root");

       LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.tokenAddress = _tokenAddress;
        ds.merkleRoot = _merkleRoot;
        ds.owner = msg.sender;
        
    }

    
    event claimSuccessful(address indexed account, uint256 indexed amount);
    event merkleRootUpdated(bytes32 indexed merkleRoot);

  
    function claim(uint256 amount,  bytes32[] calldata merkleProof) external{
       LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(!ds.isClaimed[msg.sender], "Already claimed");
     

        // bytes32 node = keccak256(abi.encodePacked(account, amount));
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));

        bool isValidProof = MerkleProof.verify(merkleProof,  ds.merkleRoot, node);

        require(isValidProof, "Merkle proof is invalid");

        ds.isClaimed[msg.sender] = true;

        ERC721Facet(address(this)).safeMint(msg.sender, ds.totalSupply);
            
    }

    //updating merkel root
    function updateMerkleRoot(bytes32 newMerkleRoot) external{
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(newMerkleRoot != bytes32(0),"invalid merkle root");
        ds.merkleRoot == newMerkleRoot;
        emit merkleRootUpdated(newMerkleRoot);
    }

   
    function withdrawBalance() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
       uint256 balance = ERC721Facet(ds.tokenAddress).balanceOf(address(this));
       ERC721Facet(address(this)).safeMint(msg.sender, balance);
    }

    function hasClaimed(address _address) external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.isClaimed[_address];
    }
}