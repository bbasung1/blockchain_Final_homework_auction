const NFT = artifacts.require("NFT");
const Auction = artifacts.require("Auction");

module.exports = async function (deployer) {
  // 1. NFT 컨트랙트 먼저 배포
  await deployer.deploy(NFT);
  const nftInstance = await NFT.deployed();
  console.log("NFT deployed at:", nftInstance.address);

  // 2. NFT 주소를 인자로 Auction 컨트랙트 배포
  await deployer.deploy(Auction, nftInstance.address);
  const auctionInstance = await Auction.deployed();
  console.log("Auction deployed at:", auctionInstance.address);
};
