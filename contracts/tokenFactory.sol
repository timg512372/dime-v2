pragma solidity ^0.6.6;

import '@openzeppelin/contracts/access/AccessControl.sol';

// SPDX-License-Identifier: UNLICENSED
// Root token contract
// Contains: Individual Token Methods
contract TokenFactory is AccessControl {
    struct Token {
        string company;
        string purpose;
    }

    Token[] public tokenArray;

    mapping(uint256 => address) internal tokenToOwner;
    mapping(address => uint256) internal ownerTokenCount;

    bytes32 public constant MINTERS = keccak256('MINTERS');

    event MintToken(uint256 idStart, uint256 idEnd, string company, string purpose);

    modifier onlyMinters() {
        require(hasRole(MINTERS, msg.sender), 'Not The Minter');
        _;
    }

    modifier onlyOwners() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Not The Owner');
        _;
    }

    modifier ownsToken(uint256 _tokenId) {
        require(tokenToOwner[_tokenId] == msg.sender, "You don't own the token");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setMinterAuthorization(address _minter, bool status) external onlyOwners {
        if (status == true) {
            grantRole(MINTERS, _minter);
        } else {
            revokeRole(MINTERS, _minter);
        }
    }

    function getMinterAuthorization(address _minter) external view returns (bool) {
        return hasRole(MINTERS, _minter);
    }

    function getTokenByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](ownerTokenCount[_owner]);
        uint256 counter = 0;
        for (uint256 i = 0; i < tokenArray.length; i++) {
            if (tokenToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function newToken(
        string calldata _company,
        string calldata _purpose,
        uint256 tokens
    ) external onlyMinters {
        uint256 idStart = tokenArray.length;
        for (uint256 i = 0; i < tokens; i++) {
            tokenArray.push(Token(_company, _purpose));
            uint256 id = tokenArray.length - 1;
            tokenToOwner[id] = msg.sender;
            ownerTokenCount[msg.sender]++;
        }
        emit MintToken(idStart, idStart + tokens - 1, _company, _purpose);
    }

    function setCompany(string calldata _company, uint256 _tokenId) external ownsToken(_tokenId) {
        tokenArray[_tokenId].company = _company;
    }

    function setPurpose(string calldata _purpose, uint256 _tokenId) external ownsToken(_tokenId) {
        tokenArray[_tokenId].purpose = _purpose;
    }
}
