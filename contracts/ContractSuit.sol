// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./ContractLevelReward.sol";

// !Распределить функционал контракта между бэком, фронтом и самим контрактом

contract ERC721SuitUnlimited is
    LevelRevard,
    Context,
    ERC165,
    IERC721,
    IERC721Metadata
{
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;
    using Counters for Counters.Counter;
    uint256 private _tokenPrice = 50000000000000000; //0.05 ETH
    uint256 private platformFee;
    string private _baseURI;
    string private _name;
    string private _symbol;
    bool public saleIsActive = true;
    address private _creater;
    address private _contracttoken;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => mapping(uint256 => ListNFT)) private listNfts;

    struct ListNFT {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool onsail;
    }

    event ListedNFT(
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller,
        bool onsail
    );

    event NewPrice(uint256 newprice);

    event NewFee(uint256 newplatformFee);

    event CancelListedNFT(uint256 indexed tokenId, address indexed seller);

    event BoughtNFT(
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller,
        address indexed buyer
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _platformFee,
        address contracttoken_
    ) LevelRevard(getadress(contracttoken_)) {
        _name = name_;
        _symbol = symbol_;
        _creater = _msgSender();
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
    }

    modifier onlyCreater() {
        require(_creater == msg.sender, "Not an owner");
        _;
    }

    receive() external payable {}

    function getadress(address contracttoken_) internal returns (address) {
        require(contracttoken_ != address(0), "Zero address");
        _contracttoken = contracttoken_;
        return contracttoken_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);

        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId.toString()))
                : "";
    }

    function setBaseURI(string memory newBaseURI) public onlyCreater {
        _baseURI = newBaseURI;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ERC721SuitUnlimited.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = ERC721SuitUnlimited.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _safeMint(address to) public payable {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(to, currentTokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal {
        require(saleIsActive, "Sale must be active to mint");
        require(to == _msgSender(), "You can only buy with your wallet");
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(_tokenPrice <= msg.value, "Ether value sent is not correct");

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        Level storage user = suitoption[tokenId];
        user.color = 1;
        user.fashion = 1;
        user.endurance = 1;
        user.reloaded = block.timestamp;
        user.level = 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(
            ERC721SuitUnlimited.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721SuitUnlimited.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function flipSaleState() public onlyCreater {
        saleIsActive = !saleIsActive;
    }

    function getBalance() public view onlyCreater returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyCreater {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawEthFromToken() public onlyCreater {
        (bool success, ) = _contracttoken.call(
            abi.encodeWithSignature("withdraw()")
        );
        require(success, "Cant withdraw ETH");

        emit Responce(success);
    }

    function setPrice(uint256 _newPrice) public onlyCreater {
        require(_newPrice > 0, "Price can`t 0");
        _tokenPrice = _newPrice;

        emit NewPrice(_newPrice);
    }

    function getPrice() public view returns (uint256) {
        return _tokenPrice;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function listNft(uint256 _tokenId, uint256 _price) public {
        address owner = _ownerOf(_tokenId);
        require(_msgSender() == owner, "Not owner NFT");
        require(owner != address(0), "ERC721: invalid token ID");
        require(
            listNfts[msg.sender][_tokenId].onsail == false,
            "Tolen already listed"
        );

        listNfts[msg.sender][_tokenId] = ListNFT({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            onsail: true
        });

        emit ListedNFT(_tokenId, _price, msg.sender, true);
    }

    function cancelListedNFT(uint256 _tokenId) public {
        ListNFT memory listedNFT = listNfts[msg.sender][_tokenId];
        address owner = _ownerOf(_tokenId);
        require(_msgSender() == owner, "Not owner NFT");
        require(owner != address(0), "ERC721: invalid token ID");
        require(listedNFT.onsail != false, "Token not listed");

        delete listNfts[msg.sender][_tokenId];

        emit CancelListedNFT(_tokenId, msg.sender);
    }

    // ! до покупки надо предоставить разрешение на распоряжение токенами
    function buyNFT(address seller, uint256 _tokenId) public payable {
        ListNFT memory listedNft = listNfts[seller][_tokenId];
        address owner = _ownerOf(_tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        require(listedNft.onsail == true, "NFT not on sale");

        delete listNfts[seller][_tokenId];

        uint256 totalPrice = listedNft.price;
        uint256 platformFeeTotal = calculatePlatformFee(totalPrice);

        IERC20(_contracttoken).transferFrom(
            msg.sender,
            address(this),
            platformFeeTotal
        );

        IERC20(_contracttoken).transferFrom(
            msg.sender,
            listedNft.seller,
            totalPrice - platformFeeTotal
        );

        _transfer(listedNft.seller, msg.sender, listedNft.tokenId);

        Level storage user = suitoption[_tokenId];
        user.reloaded = block.timestamp;

        emit BoughtNFT(
            listedNft.tokenId,
            msg.value,
            listedNft.seller,
            msg.sender
        );
    }

    function calculatePlatformFee(
        uint256 _price
    ) internal view returns (uint256) {
        return uint((_price * platformFee) / 100);
    }

    function getListedNFT(
        address seller,
        uint256 _tokenId
    ) public view returns (ListNFT memory) {
        return listNfts[seller][_tokenId];
    }

    function updatePlatformFee(uint256 _platformFee) public onlyCreater {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;

        emit NewFee(_platformFee);
    }

    function changeCreatorERC20ST(address newcreater) public onlyCreater {
        require(newcreater != address(0), "Zero address");
        (bool success, ) = _contracttoken.call(
            abi.encodeWithSignature("setNewCreater(address)", newcreater)
        );
        require(success, "Cant change creator");

        emit Responce(success);
    }

    function addLevelForApgrade(
        address owner,
        uint userTokenId
    ) external payable override {
        Level storage user = suitoption[userTokenId];
        uint price = _priceForUpgrade(userTokenId);
        address ownerToken = _ownerOf(userTokenId);
        require(ownerToken != address(0), "ERC721: invalid token ID");
        require(ownerToken == owner, "ERC721: you are not an owner");
        require(msg.sender == owner, "Not an owner to update tokens");

        _payForApgrade(owner, price);

        user.color++;
        user.endurance++;
        user.fashion++;

        uint256 suntolevel = user.color + user.fashion + user.endurance;
        if (suntolevel >= 10 && suntolevel < 20) {
            user.level = 2;
        } else if (suntolevel >= 20 && suntolevel < 30) {
            user.level = 3;
        } else if (suntolevel >= 30 && suntolevel < 40) {
            user.level = 4;
        } else if (suntolevel >= 40 && suntolevel < 50) {
            user.level = 5;
        }

        emit Upgrade(owner, userTokenId);
    }
}
