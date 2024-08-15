// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./security/ReentrancyGuard.sol";

contract NFTMarketplaceV2 is ERC721URIStorage, ReentrancyGuard {
    uint private _tokenIds = 0;
    uint private _itemsSold = 0;

    address payable private contractOwner;
    uint256 private listPrice = 0.01 ether;

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 price;
        bool currentlyListed;
        uint256 royalty;
    }

    struct SaleHistory {
        uint256 tokenId;
        address previousOwner;
        address newOwner;
        uint256 salePrice;
        uint256 saleTimestamp;
    }

    mapping(uint256 => ListedToken) private idToListedToken;
    mapping(uint256 => SaleHistory[]) private saleHistories;

    event TokenListedSuccess(
        uint256 indexed tokenId,
        address owner,
        address creator,
        uint256 price,
        bool currentlyListed
    );

    event TokenSold(
        uint256 indexed tokenId,
        address previousOwner,
        address newOwner,
        uint256 salePrice
    );

    constructor() ERC721("NFTMarketplace", "NFTMP") {
        contractOwner = payable(msg.sender);
    }

    function createToken(string memory tokenURI, uint256 price, uint256 royalty) public returns (uint) {
        require(royalty <= 30, "Royalty cannot exceed 30%");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        idToListedToken[newTokenId] = ListedToken(
            newTokenId,
            payable(msg.sender),
            payable(msg.sender),
            price,
            false,
            royalty
        );

        return newTokenId;
    }

    function listTokenForSale(uint256 tokenId, uint256 price) public payable nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "You must own the token to list it for sale");
        require(price > 0, "Price must be greater than zero");
        require(msg.value == listPrice, "Price must be equal to listing price");

        ListedToken storage token = idToListedToken[tokenId];
        require(!token.currentlyListed, "Token is already listed for sale");

        token.price = price;
        token.owner = payable(msg.sender);
        token.currentlyListed = true;

        _transfer(msg.sender, address(this), tokenId);

        emit TokenListedSuccess(
            tokenId,
            msg.sender,
            token.creator,
            price,
            true
        );
    }

    function executeSale(uint256 tokenId) public payable nonReentrant {
        ListedToken storage token = idToListedToken[tokenId];
        uint256 price = token.price;
        address payable seller = token.owner;
        address payable creator = token.creator;
        uint256 royalty = token.royalty;
        
        require(token.currentlyListed, "Token is not currently listed for sale");
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        uint256 royaltyFee = (price * royalty) / 100;
        uint256 sellerAmount = price - royaltyFee;

        token.currentlyListed = false;
        address previousOwner = token.owner;
        token.owner = payable(msg.sender);

        _itemsSold++;

        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);

        // Переводим средства
        payable(contractOwner).transfer(listPrice); 
        creator.transfer(royaltyFee);
        seller.transfer(sellerAmount);

        // Записываем историю продажи
        SaleHistory memory newSale = SaleHistory({
            tokenId: tokenId,
            previousOwner: previousOwner,
            newOwner: msg.sender,
            salePrice: price,
            saleTimestamp: block.timestamp
        });
        saleHistories[tokenId].push(newSale);

        emit TokenSold(tokenId, previousOwner, msg.sender, price);
    }

    function getAllNFTs () public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds;

        ListedToken[] memory allNFTs = new ListedToken[](nftCount);
        for (uint i = 0; i < nftCount; i++) {
            allNFTs[i] = idToListedToken[i + 1];
        }

        return allNFTs;
    }
    
    function getListedNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds;
        uint listedCount = 0;


        for (uint i = 0; i < nftCount; i++) {
            if (idToListedToken[i + 1].currentlyListed) {
                listedCount++;
            }
        }


        ListedToken[] memory listedTokens = new ListedToken[](listedCount);
        uint currentIndex = 0;


        for (uint i = 0; i < nftCount; i++) {
            if (idToListedToken[i + 1].currentlyListed) {
                listedTokens[currentIndex] = idToListedToken[i + 1];
                currentIndex++;
            }
        }

        return listedTokens;
    }


    function getSaleHistory(uint256 tokenId) public view returns (SaleHistory[] memory) {
        return saleHistories[tokenId];
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(contractOwner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds;
    }
}