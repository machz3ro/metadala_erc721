//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";

error AlreadyInitialized();
error NeedMoreETHSent();
error RangeOutOfBounds();

contract Metadala is ERC721URIStorage, VRFConsumerBaseV2, Ownable {

    // Chainlink VRF V2 Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // NFT Variables
    uint256 private i_mintFee;
    uint256 public s_tokenCounter;
    mapping(uint256 => ERC721URIStorage ) private s_tokenIdMetadala;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_metadalaToken;
    bool private s_initialized;

    // VRF V2 Helpers 
    mapping(uint256 => address) public s_requestIdToSender;
    mapping(uint256 => uint256) public s_tokenIdToRandomNumber;
    mapping(bytes32 => uint256) public s_requestIdToTokenId;

    // Events
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);
    event CreatedUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event requestedRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId); 

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 mintFee,
        uint32 callbackGasLimit,
        string[1] memory metadalaToken
    ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Metadala", "MDL") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_mintFee = mintFee;
        i_callbackGasLimit = callbackGasLimit;
        // _initializeContract(metadalaToken);
    }

    function create() public returns (bytes32 requestId) {
        requestId = requestRandomness(i_subscriptionId, i_mintFee);
        s_requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = s_tokenIdToRandomNumber; 
        s_requestIdToTokenId[requestId] = tokenId;
        s_tokenCounter = s_tokenCounter + 1;
        emit requestedRandomSVG(requestId, tokenId);
    }

        function finishMint(uint256 tokenId) public {
        require(bytes(tokenURI(tokenId)).length <= 0, "tokenURI is already set!"); 
        require(s_tokenCounter > tokenId, "TokenId has not been minted yet!");
        require(s_tokenIdToRandomNumber[tokenId] > 0, "Need to wait for the Chainlink node to respond!");
        uint256 randomNumber = s_tokenIdToRandomNumber[tokenId];
        string memory meta = generateMetadala(randomNumber);
        string memory imageURI = svgToImageURI(meta);
        _setTokenURI(tokenId, formatTokenURI(imageURI));
        emit CreatedRandomSVG(tokenId, meta);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        address nftOwner = s_requestIdToSender[requestId];
        uint256 tokenId = s_requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId);
        s_tokenIdToRandomNumber[tokenId] = randomNumber;
        emit CreatedUnfinishedMetadala(tokenId, randomNumber);
    }

    function generateMetadala(uint256 _randomness) public view returns (string memory mintedMetadala) {
    
    }

    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI) public pure returns (string memory) {
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{\"name\":\"Metadala\",\"symbol\":\"MDL\",\"image\":\"',imageURI,'\"}')
                        )
                    )
                )
            );
    }
    

    /*
    // From: https://stackoverflow.com/a/65707309/11969592
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
    */
}