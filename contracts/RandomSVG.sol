// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;

    event requestedRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId); //indexing a parameter = it will be a topic (incurs more gas than unindexed parameters)

    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash, uint256 _fee) 
    VRFConsumerBase(_VRFCoordinator,_LinkToken) 
    ERC721 ("RandomSVG NFT", "rsNFT")
    {
        fee = _fee;
        keyHash = _keyHash;
    }

    function create() public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender; // keep track of who initiated the request
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter++;
        emit requestedRandomSVG(requestId, tokenId);
        // get a random number
        // use that random number to generate some random SVg code
        // base64 encode the SVG code 
        // get the tokenURI, set it and mint the NFT
        // blockchains are deterministic (so we need to use oracles to get a true random number using chainlink VRF)
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        // Chainlink VRF has a max gas of 200,000 gas (computation units)
    }    

    function finishMint () public {

    }
}
