import hre, { ethers } from "hardhat";
import { expect } from "chai";
import { NFTMarketplaceV2 } from "../typechain-types/contracts";
type NFTMarketplaceType = NFTMarketplaceV2;
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("NFTMarketplaceV2", async function () {
  const dep = async () => {
    const [owner, otherAccount, thirdAccount] = await ethers.getSigners();
    const NFTMarketplaceV2 = await ethers.getContractFactory(
      "NFTMarketplaceV2",
      owner
    );

    const contract: NFTMarketplaceType = await NFTMarketplaceV2.deploy();
    await contract.waitForDeployment();
    return {
      owner,
      otherAccount,
      thirdAccount,
      contract,
    };
  };

  it("Should be deployed", async function () {
    const { contract } = await loadFixture(dep);
    expect(await contract.getAddress()).to.not.equal(0);
  });

  it("Should create an NFT", async function () {
    const { contract } = await loadFixture(dep);
    const tx = await contract.createToken("URI", ethers.parseEther("0.01"), 10);
    await tx.wait();
    expect(await contract.tokenURI(1)).to.equal("URI");
  });

  it("Should buy an NFT", async function () {
    const { owner, contract, otherAccount } = await loadFixture(dep);
    const tx = await contract
      .connect(owner)
      .createToken("URI", ethers.parseEther("0.01"), 10);
    await tx.wait();
    const nfts = await contract.getAllNFTs();
    console.log(nfts);
    const tx2 = await contract
      .connect(owner)
      .listTokenForSale(1, ethers.parseEther("0.03"), {
        value: ethers.parseEther("0.01"),
      });
    await tx2.wait();
    const tx3 = await contract
      .connect(otherAccount)
      .executeSale(1, { value: ethers.parseEther("0.03") });
    await tx3.wait();
    expect(await contract.balanceOf(otherAccount.address)).to.equal(1);
  });

  it("Should save sale history", async function () {
    const { owner, contract, otherAccount, thirdAccount } = await loadFixture(
      dep
    );
    console.log(await ethers.provider.getBalance(await owner.getAddress()));
    const tx = await contract.createToken("URI", ethers.parseEther("1000"), 30);
    await tx.wait();
    console.log(
      "on sale ",
      await ethers.provider.getBalance(await owner.getAddress())
    );
    const tx2 = await contract.listTokenForSale(1, ethers.parseEther("1500"), {
      value: ethers.parseEther("0.01"),
    });
    await tx2.wait();
    const tx3 = await contract
      .connect(otherAccount)
      .executeSale(1, { value: ethers.parseEther("1500") });
    await tx3.wait();
    console.log(
      "sold ",
      await ethers.provider.getBalance(await owner.getAddress())
    );
    const tx4 = await contract
      .connect(otherAccount)
      .listTokenForSale(1, ethers.parseEther("2000"), {
        value: ethers.parseEther("0.01"),
      });
    await tx4.wait();
    const tx5 = await contract
      .connect(thirdAccount)
      .executeSale(1, { value: ethers.parseEther("2000") });
    await tx5.wait();
    console.log(
      "get royalty ",
      await ethers.provider.getBalance(await owner.getAddress())
    );

    console.log(await contract.getSaleHistory(1));
  });
});
