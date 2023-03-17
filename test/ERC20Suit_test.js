const { expect } = require("chai");
const { ethers } = require("hardhat");
const { assert } = require("assert");

describe("ERC20_SUIT_TOKEN", function () {
  let acc1;
  let acc2;
  let payments;

  this.beforeEach(async function () {
    const InitialSuplay = 100;

    [acc1, acc2] = await ethers.getSigners();
    const Payments = await ethers.getContractFactory("ERC20_SUIT_TOKEN", acc1);
    payments = await Payments.deploy(InitialSuplay);
    await payments.deployed(InitialSuplay);
  });

  it("shoud be deployed and address correct", async function () {
    expect(payments.address).to.be.properAddress;
  });

  it("creator = msg.sender", async function () {
    expect(await payments.creater()).to.equal(acc1.address);
  });

  it("if _CAP = 0 error", async function () {
    expect(await payments._CAP()).to.equal(0);
  });

  it("balance creator = totalsuplay", async function () {
    const ownerBalance = await payments.balanceOf(acc1.address);
    expect(await payments.totalSupply()).to.equal(ownerBalance);
    console.log(ownerBalance);
  });

  it("Fallback is work", async function () {
    const tx = await payments.pay("Hi", { value: 100 });
    await tx.wait();
    expect(await payments._CAP()).to.equal(0);
  });

  it("connect owner", async function () {
    const NewCreator = await payments.setNewCreater(acc2.address);
    expect(await payments.creater()).to.equal(acc2.address);
  });

  it("connect not owner", async function () {
    const NotOwner = payments.connect(payments.address, acc2);
    const NewCreator = await NotOwner.name();
    expect(await NewCreator).to.equal("SUITSTOKEN");

    expect(await NotOwner.setNewCreater(acc2.address)).to.be.reverted;
  });
});
