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

        LibDiamond.DiamondStorage storage ds = new DiamondStorage();

        ds.tokenAddress = _tokenAddress;
        ds.merkleRoot = _merkleRoot;
        ds.owner = msg.sender;
        
    }

    
    event claimSuccessful(address indexed account, uint256 indexed amount);
    event merkleRootUpdated(bytes32 indexed merkleRoot);

    modifier onlyOwner {
        require(owner == msg.sender, "You are Not the owner");
        _;
    }

  function claim(uint256 amount,  bytes32[] calldata merkleProof) external{
       LibDiamond.DiamondStorage storage ds = new DiamondStorage();
        require(!isClaimed[msg.sender], "Already claimed");
        IMerkle.MerkleProof  proof;

        // bytes32 node = keccak256(abi.encodePacked(account, amount));
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));

        bool isValidProof = proof.verify(merkleProof, merkleRoot, node);

        require(isValidProof, "Merkle proof is invalid");

        ds.isClaimed[msg.sender] = true;

        ERC721Facet(address(this)).safeMint(msg.sender, ds.totalSupply);
            
    }

    //updating merkel root
    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner{
        LibDiamond.DiamondStorage storage ds = new DiamondStorage();
        require(newMerkleRoot != bytes32(0),"invalid merkle root");
        ds.merkleRoot == newMerkleRoot;
        emit merkleRootUpdated(newMerkleRoot);
    }

   
    function withdrawBalance() external onlyOwner{
        LibDiamond.DiamondStorage storage ds = new DiamondStorage();
       uint256 balance = ERC721Facet(ds.tokenAddress).balanceOf(address(this));
       require(ERC721Facet(tokenAddress).transfer(msg.sender, balance), "Transfer failed");
    }

    function hasClaimed(address _address) external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = new DiamondStorage();
        return ds.claimed[_address];
    }
}