// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract Simple721 is ERC721 {
    uint private tokenId;
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    function _mint(address to, uint _tokenId) internal override {
      super._mint(to, _tokenId);
    }

    function mint(address to, uint _tokenId) external {
        tokenId = _tokenId;
        _mint(to, tokenId);
    }

    function tid() public view returns (uint){
      return tokenId;
    }
}
