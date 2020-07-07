pragma solidity ^0.6.6;

import './tokenFactory.sol';
import './supports-interface.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';

// SPDX-License-Identifier: UNLICENSED
// Contains ERC721 logic
contract TokenOwnership is TokenFactory, IERC721, SupportsInterface {
    using SafeMath for uint256;
    using Address for address;

    string constant ZERO_ADDRESS = '003001';
    string constant NOT_VALID_NFT = '003002';
    string constant NOT_OWNER_OR_OPERATOR = '003003';
    string constant NOT_OWNER_APPROWED_OR_OPERATOR = '003004';
    string constant NOT_ABLE_TO_RECEIVE_NFT = '003005';
    string constant NFT_ALREADY_EXISTS = '003006';
    string constant NOT_OWNER = '003007';
    string constant IS_OWNER = '003008';

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(address => mapping(address => bool)) internal ownerToOperators;
    mapping(uint256 => address) internal idToApproval;

    constructor() public {
        supportedInterfaces[0x80ac58cd] = true; // ERC721
    }

    modifier validNFToken(uint256 _tokenId) {
        require(tokenToOwner[_tokenId] != address(0), NOT_VALID_NFT);
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
            NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            NOT_OWNER_APPROWED_OR_OPERATOR
        );
        _;
    }

    function balanceOf(address _owner) external override view returns (uint256) {
        uint256 count = ownerTokenCount[_owner];
        return count;
    }

    function ownerOf(uint256 _tokenId) external override view returns (address) {
        return tokenToOwner[_tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        _safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _safeTransferFrom(from, to, tokenId, '');
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _transfer(to, tokenId);
    }

    function approve(address to, uint256 tokenId)
        external
        override
        canOperate(tokenId)
        validNFToken(tokenId)
    {
        address tokenOwner = tokenToOwner[tokenId];
        require(to != tokenOwner, IS_OWNER);

        idToApproval[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external override view returns (address operator) {
        return idToApproval[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        ownerToOperators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        external
        override
        view
        returns (bool)
    {
        return ownerToOperators[owner][operator];
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = tokenToOwner[_tokenId];
        require(tokenOwner == _from, NOT_OWNER);
        require(_to != address(0), ZERO_ADDRESS);
        _transfer(_to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
            require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
        }
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = tokenToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(tokenToOwner[_tokenId] == _from, NOT_OWNER);
        ownerTokenCount[_from] = ownerTokenCount[_from] - 1;
        delete tokenToOwner[_tokenId];
    }

    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(tokenToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
        tokenToOwner[_tokenId] = _to;
        ownerTokenCount[_to] = ownerTokenCount[_to].add(1);
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }
}
