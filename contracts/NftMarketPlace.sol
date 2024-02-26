// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VideoNFTMarketplace is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event NFTMinted(uint256 tokenId, address creator, string videoUrl, uint256 price);
    event NFTSold(uint256 tokenId, address seller, address buyer, uint256 price);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event NFTUnlisted(uint256 tokenId, address seller);

    struct VideoNFT {
        uint256 id;
        address creator;
        string videoUrl;
        uint256 price;
        bool forSale;
    }

    mapping(uint256 => VideoNFT) private _videoNFTs;
    mapping(address => bool) private _authorizedMinters;

    modifier onlyMinter() {
        require(_authorizedMinters[msg.sender], "Caller is not an authorized minter");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        _;
    }

    constructor() ERC721("VideoNFT", "VNFT") {}

    function addMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Invalid minter address");
        _authorizedMinters[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Invalid minter address");
        _authorizedMinters[_minter] = false;
    }

    function mintNFT(string memory _videoUrl, uint256 _price) external onlyMinter {
        _tokenIds.increment();
        uint256 newNFTId = _tokenIds.current();
        _mint(msg.sender, newNFTId);

        VideoNFT memory newNFT = VideoNFT({
            id: newNFTId,
            creator: msg.sender,
            videoUrl: _videoUrl,
            price: _price,
            forSale: false
        });

        _videoNFTs[newNFTId] = newNFT;

        emit NFTMinted(newNFTId, msg.sender, _videoUrl, _price);
    }

    function buyNFT(uint256 _tokenId) external payable {
        VideoNFT storage nft = _videoNFTs[_tokenId];
        require(nft.forSale == true, "NFT is not for sale");
        require(msg.value >= nft.price, "Insufficient funds");

        address payable seller = payable(ownerOf(_tokenId));
        seller.transfer(msg.value);

        _transfer(seller, msg.sender, _tokenId);
        nft.forSale = false;

        emit NFTSold(_tokenId, seller, msg.sender, nft.price);
    }

    function sellNFT(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) {
        VideoNFT storage nft = _videoNFTs[_tokenId];
        require(!nft.forSale, "NFT is already for sale");

        nft.price = _price;
        nft.forSale = true;

        emit NFTListed(_tokenId, msg.sender, _price);
    }

    function cancelSale(uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        VideoNFT storage nft = _videoNFTs[_tokenId];
        require(nft.forSale, "NFT is not for sale");

        nft.forSale = false;

        emit NFTUnlisted(_tokenId, msg.sender);
    }

    function getNFT(uint256 _tokenId) external view returns (uint256, address, string memory, uint256, bool) {
        VideoNFT memory nft = _videoNFTs[_tokenId];
        return (nft.id, nft.creator, nft.videoUrl, nft.price, nft.forSale);
    }
}
