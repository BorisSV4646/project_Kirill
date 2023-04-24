const hre = require("hardhat");
const { verify } = require("../task/verify");

async function main() {
  const InitialSuplay = 100;

  [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ERC20 = await ethers.getContractFactory("ERC20_SUIT_TOKEN", deployer);

  const TokenERC20 = await ERC20.deploy(InitialSuplay);

  await TokenERC20.deployed(InitialSuplay);

  console.log("Token ERC20 address:", TokenERC20.address);

  const SuitToken = await ethers.getContractFactory(
    "ERC721SuitUnlimited",
    deployer
  );

  const SuitMainContract = await SuitToken.deploy(
    "SuitToken",
    "ST",
    3,
    TokenERC20.address
  );

  await SuitMainContract.deployed("SuitToken", "ST", 3, TokenERC20.address);

  console.log("Main contract address:", SuitMainContract.address);

  await TokenERC20.setNewCreater(SuitMainContract.address);

  console.log(`Creator ERC20 contract set: ${await TokenERC20.creater()}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
