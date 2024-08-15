import hre, { ethers } from "hardhat";
import fs from "fs";
import {
  NFTMarketplaceV2,
  NFTMarketplaceV2__factory,
} from "../typechain-types";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    await deployer.getAddress()
  );
  const Marketplace = await hre.ethers.getContractFactory(
    "NFTMarketplaceV2",
    deployer
  );
  const marketplace: NFTMarketplaceV2 = await Marketplace.deploy();

  await marketplace.waitForDeployment();

  const data = {
    address: await marketplace.getAddress(),
    abi: NFTMarketplaceV2__factory.abi,
  };

  fs.writeFileSync("./src/MarketplaceV2HHTest.json", JSON.stringify(data));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
