// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;

    // SVG Parameters
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommands;
    uint256 public size;
    string[] public pathCommands;
    string[] public colors;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event requestedRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId); //indexing a parameter = it will be a topic (incurs more gas than unindexed parameters)
    event CreatedUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);

    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash, uint256 _fee) 
    VRFConsumerBase(_VRFCoordinator,_LinkToken) 
    ERC721 ("RandomSVG NFT", "rsNFT")
    {
        fee = _fee;
        keyHash = _keyHash;
        maxNumberOfPaths = 10;
        maxNumberOfPathCommands = 5;
        size = 500;
        pathCommands = ["M", "L"];
        colors = ["red","blue","green","yellow","black","white"];
    }

    function create() public returns (bytes32 requestId) {
        // get a random number
        // use that random number to generate some random SVg code
        // base64 encode the SVG code 
        // get the tokenURI, set it and mint the NFT
        // blockchains are deterministic (so we need to use oracles to get a true random number using chainlink VRF)
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender; // keep track of who initiated the request
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter++;
        emit requestedRandomSVG(requestId, tokenId);
       
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        // Chainlink VRF has a max gas of 200,000 gas (computation units)
        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId); // minting only when random number is fulfilled
        tokenIdToRandomNumber[tokenId] = randomNumber;
        emit CreatedUnfinishedRandomSVG(tokenId, randomNumber);
        // we can't call generateRandomSVG here (too much gas)
    }    

    function finishMint (uint256 _tokenId) public {
        // check to see if it's been minted and a random number is returned
        // generate random SVG code
        // turn that into an image URI
        // use that imageURI to format into a tokenURI
        require(bytes(tokenURI(_tokenId)).length <= 0, "tokenURI is already all set!"); // check if it has been done
        require(tokenCounter>_tokenId, "TokenId has not been minted yet"); // check to see if token is minted
        require(tokenIdToRandomNumber[_tokenId]>0, "Need to wait for Chainlink VRF"); // check to see if random number has been updated in mapping
        uint256 randomNumber = tokenIdToRandomNumber[_tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(_tokenId, tokenURI);
        emit CreatedRandomSVG(_tokenId,svg);
    }

    function generateSVG(uint256 _randomNumber) public view returns (string memory finalSvg) {
        uint256 numberOfPaths = (_randomNumber % maxNumberOfPaths) + 1;
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='",uint2str(size),"' width='",uint2str(size),"'>"));

        for(uint i = 0; i < numberOfPaths; i++){
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber,i))); // to get more randomNumbers from an already generated randomness
            string memory pathSvg = generatePath(newRNG);
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));
        }
        finalSvg = string(abi.encodePacked(finalSvg,"</svg>"));
    }

    function generatePath(uint256 _randomNumber) public view returns(string memory pathSvg) {
        uint256 numberOfPathCommands = (_randomNumber % maxNumberOfPathCommands) + 1;
        pathSvg = "<path d='";

        for (uint i = 0; i < numberOfPathCommands; i ++){
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, size + i)));
            string memory pathCommand = generatePathCommand(newRNG);
            pathSvg = string(abi.encodePacked(pathSvg, pathCommand));
        }
        string memory color = colors[_randomNumber % colors.length];
        pathSvg = string(abi.encodePacked(pathSvg,"' fill='transparent' stroke='", color,"'/>"));
    }

    function generatePathCommand(uint256 _randomNumber) public view returns(string memory pathCommand) {
        pathCommand = pathCommands[_randomNumber % pathCommands.length];
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size * 2))) % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size * 3))) % size;
        pathCommand = string(abi.encodePacked(pathCommand," ", uint2str(parameterOne)," ", uint2str(parameterTwo)));
    }

    function svgToImageURI(string memory _svg) public pure returns (string memory){
        // <svg xmlns="http://www.w3.org/2000/svg" height="210" width="400"> <path d="M150 0 L75 200 L225 200 Z" /> </svg>
        // data:image/svg+xml;base64,<Base64-encoding>
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(_svg))));
        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
        return imageURI;
    }

    function formatTokenURI(string memory _imageURI) public pure returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        return string(abi.encodePacked(
            baseURL,
            Base64.encode(bytes(abi.encodePacked(
            '{"name":"SVG NFT",', 
            '"description":"An NFT based on SVG",',
            '"attributes":"",', 
            '"image":"',_imageURI,'"}')
            ))
        ));  
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
