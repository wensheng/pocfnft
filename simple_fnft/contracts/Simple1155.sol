// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

contract Simple1155 is ERC1155 {
    // For one NFT only
    uint private tokenId; 
    bytes public data;
    constructor(string memory uri) ERC1155(uri) {
        data = bytes(uri);
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory _data) internal override {
        super._mint(account, id, amount, _data);
    }

    function mint(address to, uint _tokenId) external {
        tokenId = _tokenId;
        _mint(to, _tokenId, 1, data);
    }

    function tid() public view returns (uint) {
        return tokenId;
    }
}