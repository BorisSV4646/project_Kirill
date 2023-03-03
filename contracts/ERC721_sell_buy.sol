// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721_suit_unlimited.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC721_sell_buy {
    uint256 private platformFee;

    struct ListNFT {
        address nft;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool onsail;
    }

    mapping(address => mapping(uint256 => ListNFT)) private listNfts;

    event ListedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller
    );

    event CancelListedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed seller
    );

    event BoughtNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address indexed buyer
    );

    constructor(uint256 _platformFee) {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
    }

    function listNft(address _nft, uint256 _tokenId, uint256 _price) external {
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        require(
            listNfts[msg.sender][_tokenId].onsail == true,
            "Tolen already listed"
        );

        listNfts[msg.sender][_tokenId] = ListNFT({
            nft: _nft,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            onsail: true
        });

        emit ListedNFT(_nft, _tokenId, _price, msg.sender);
    }

    function cancelListedNFT(address _nft, uint256 _tokenId) external {
        ListNFT memory listedNFT = listNfts[_nft][_tokenId];
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        require(listedNFT.onsail == false, "Tolen not listed");

        delete listNfts[_nft][_tokenId];

        emit CancelListedNFT(_nft, _tokenId, msg.sender);
    }

    function buyNFT(address _nft, uint256 _tokenId) external payable {
        ListNFT storage listedNft = listNfts[_nft][_tokenId];
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        require(listedNft.onsail == false, "nft not on sale");
        require(msg.value >= listedNft.price, "Not enouth money");

        delete listNfts[_nft][_tokenId];

        uint256 totalPrice = _price;

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(msg.value);
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            address(this),
            platformFeeTotal
        );

        // Transfer to nft owner
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            listedNft.seller,
            totalPrice - platformFeeTotal
        );

        // Transfer NFT to buyer
        IERC721(listedNft.nft)._transfer(
            listedNft.seller,
            msg.sender,
            listedNft.tokenId
        );

        emit BoughtNFT(
            listedNft.nft,
            listedNft.tokenId,
            msg.value,
            listedNft.seller,
            msg.sender
        );
    }

    function calculatePlatformFee(
        uint256 _price
    ) internal view returns (uint256) {
        return (_price * platformFee) / 10000;
    }

    function getListedNFT(
        address _nft,
        uint256 _tokenId
    ) public view returns (ListNFT memory) {
        return listNfts[_nft][_tokenId];
    }

    function updatePlatformFee(uint256 _platformFee) external onlyCreater {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
    }
}
