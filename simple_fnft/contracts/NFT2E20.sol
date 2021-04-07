// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract NFT2E20 is ERC20{
    uint public nftId;

    constructor(string memory _name, string memory _symbol, uint _nftId, uint tokenSupply) 
    ERC20(_name, _symbol) 
    {
        nftId = _nftId;
        _mint(msg.sender, tokenSupply);
    }
}