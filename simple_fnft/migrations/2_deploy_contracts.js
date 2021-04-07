const Simple721 = artifacts.require("Simple721");
const Simple1155 = artifacts.require("Simple1155");
const NFT2E20 = artifacts.require("NFT2E20");
const FE20Sale = artifacts.require("FE20Sale");
const tokenId = 31415926;

module.exports = async (deployer, networks, accounts) => {
  await deployer.deploy(Simple721, "Hello", "HELO");
  const inst_Simple721 = await Simple721.deployed();
  await deployer.deploy(Simple1155, "http://this.is.fake");
  const inst_Simple1155 = await Simple1155.deployed();
  await inst_Simple721.mint(accounts[1], tokenId);
  await deployer.deploy(FE20Sale, inst_Simple721.address, tokenId);
  const inst_FE20Sale = await FE20Sale.deployed();
};
