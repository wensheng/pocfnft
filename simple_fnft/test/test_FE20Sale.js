const FE20Sale = artifacts.require('FE20Sale');
//const NFT = artifacts.require('Simple1155');
const Simple721 = artifacts.require('Simple721');
const tokenId = 31415926;

let iSale;
let iNFT;

before(async () => {
    iSale = await FE20Sale.deployed();
    iNFT = await Simple721.deployed();
});

contract("FE20Sale Test", accounts => {
    it("should acquire NFT721", async () => {
        const owner = await iNFT.ownerOf(tokenId);
        assert.equal(owner, accounts[1], "account1 should hold nft");
        const nftype = await iSale.nftype();
        assert.equal(nftype, 0, "ok")
        //await iNFT.safeTransferFrom(accounts[1], iSale.address, tokenId, {from: accounts[1]});
        await iNFT.approve(iSale.address, tokenId, {from: accounts[1]})
        await iSale.transferNFT({from: accounts[1]});
        const newOnwer = await iNFT.ownerOf(tokenId)
        assert.equal(newOnwer, iSale.address, "contract should now hold nft")
    });
    it("should start selling E20 tokens", async () => {
        await iSale.startSelling(100, 100, 24);
    });
    it("should be able to buy tokens", async () => {
        await web3.eth.sendTransaction({
            to: iSale.address,
            from: accounts[2],
            value: web3.utils.toWei('1')
        });
        await web3.eth.sendTransaction({
            to: iSale.address,
            from: accounts[3],
            value: web3.utils.toWei('2')
        });
    });
});
