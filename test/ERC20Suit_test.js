const { expect } = require("chai");
const { ethers } = require("hardhat");
const { assert } = require("assert");
const { BigNumber } = require("ethers");

describe("ERC20_SUIT_TOKEN", function () {
  let acc1;
  let acc2;
  let acc3;
  let payments;

  this.beforeEach(async function () {
    const InitialSuplay = 100;

    [acc1, acc2, acc3] = await ethers.getSigners();
    const Payments = await ethers.getContractFactory("ERC20_SUIT_TOKEN", acc1);
    payments = await Payments.deploy(InitialSuplay);
    await payments.deployed(InitialSuplay);
  });

  it("Deploy - shoud be deployed and address correct", async function () {
    expect(payments.address).to.be.properAddress;
  });

  it("Constructor() - creator = msg.sender", async function () {
    expect(await payments.creater()).to.equal(acc1.address);
  });

  it("Constructor() - balance creator = totalsuplay", async function () {
    const ownerBalance = await payments.balanceOf(acc1.address);
    expect(await payments.totalSupply()).to.equal(ownerBalance);
  });

  it("Fallback() - contract recieve ethers", async function () {
    tx = {
      to: payments.address,
      value: 100,
      data: 0x12322,
    };
    const NewTransaction = await acc1.sendTransaction(tx);
    await expect(() => NewTransaction).to.changeEtherBalance(
      payments.address,
      100
    );
  });

  it("Receive() - contract recieve ethers", async function () {
    tx = {
      to: payments.address,
      value: 100,
    };
    const NewTransaction = await acc1.sendTransaction(tx);
    await expect(() => NewTransaction).to.changeEtherBalance(
      payments.address,
      100
    );
  });

  it("Fuction name(), symbol(), decimals(), totalSupply(), cap() - can show all this", async function () {
    const NotOwner = payments.connect(acc2);
    expect(await NotOwner.name()).to.equal("SUITSTOKEN");
    expect(await NotOwner.symbol()).to.equal("ST");
    expect(await NotOwner.decimals()).to.equal(18);
    expect((await NotOwner.totalSupply()) / 1000000000000000000).to.equal(100);
    expect((await NotOwner.cap()) / 1000000000000000000).to.equal(1500000);
  });

  it("Function balanceOf() - show balance", async function () {
    const BalanceAcc1 = await payments.balanceOf(acc1.address);
    const BalanceAcc2 = await payments.balanceOf(acc2.address);
    expect(BalanceAcc1 / 1000000000000000000).to.equal(100);
    expect(BalanceAcc2).to.equal(0);
  });

  it("Function transfer() - show balance", async function () {
    const TransferOne = await payments.transfer(acc2.address, 5000);

    await expect(() =>
      payments.transfer(acc2.address, 5000)
    ).to.changeTokenBalances(payments, [acc1, acc2], [-5000, 5000]);

    await expect(TransferOne)
      .to.emit(payments, "Transfer")
      .withArgs(acc1.address, acc2.address, 5000);

    await expect(
      payments.transfer(ethers.constants.AddressZero, 5000)
    ).to.be.revertedWith("ERC20: transfer to the zero address");

    const NotOwner = payments.connect(acc2);

    await expect(NotOwner.transfer(acc1.address, 50000)).to.be.revertedWith(
      "ERC20: transfer amount exceeds balance"
    );
  });

  it("Function allowance() - show allowance address", async function () {
    const Allow = await payments.allowance(acc1.address, acc2.address);
    expect(await Allow).to.equal(0);
  });

  it("Function approve() - user can set approve", async function () {
    const Approve = await payments.approve(acc2.address, 5000);
    const Allow = await payments.allowance(acc1.address, acc2.address);
    expect(await Allow).to.equal(5000);

    await expect(
      payments.approve(ethers.constants.AddressZero, 5000)
    ).to.be.revertedWith("ERC20: approve to the zero address");

    await expect(Approve)
      .to.emit(payments, "Approval")
      .withArgs(acc1.address, acc2.address, 5000);
  });

  it("Function transferFrom() - user can transfer token", async function () {
    const NotOwner = payments.connect(acc3);
    const amoutApprove = 15000;
    const Approve = await payments.approve(acc3.address, amoutApprove);
    const amount = 5000;
    const TransferOne = await NotOwner.transferFrom(
      acc1.address,
      acc2.address,
      amount
    );

    await expect(TransferOne).to.changeTokenBalances(
      payments,
      [acc1, acc2],
      [-amount, amount]
    );

    const Allow = await payments.allowance(acc1.address, acc3.address);
    expect(await Allow).to.equal(amoutApprove - amount);

    await expect(
      payments.transferFrom(acc1.address, acc2.address, amount)
    ).to.revertedWith("ERC20: insufficient allowance");
  });

  it("Function increaseAllowance() - Owner can add allowance", async function () {
    const NotOwner = payments.connect(acc3);
    const AmoutApprove = 15000;
    const Approve = await payments.approve(acc3.address, AmoutApprove);

    const Allow = await payments.allowance(acc1.address, acc3.address);
    expect(await Allow).to.equal(AmoutApprove);

    const AddAllowance = payments.increaseAllowance(acc3.address, 500);
    const AllowNew = await payments.allowance(acc1.address, acc3.address);
    expect(await AllowNew).to.equal(AmoutApprove + 500);

    await expect(AddAllowance)
      .to.emit(payments, "Approval")
      .withArgs(acc1.address, acc3.address, AmoutApprove + 500);
  });

  it("Function decreaseAllowance() - Owner can decrease allowance", async function () {
    const NotOwner = payments.connect(acc3);
    const AmoutApprove = 15000;
    const Approve = await payments.approve(acc3.address, AmoutApprove);

    const Allow = await payments.allowance(acc1.address, acc3.address);
    expect(await Allow).to.equal(AmoutApprove);

    const AddAllowance = payments.decreaseAllowance(acc3.address, 500);
    const AllowNew = await payments.allowance(acc1.address, acc3.address);
    expect(await AllowNew).to.equal(AmoutApprove - 500);

    await expect(AddAllowance)
      .to.emit(payments, "Approval")
      .withArgs(acc1.address, acc3.address, AmoutApprove - 500);

    await expect(
      payments.decreaseAllowance(acc3.address, 50000)
    ).to.revertedWith("ERC20: decreased allowance below zero");
  });

  it("Function _mint() - user can mint tokens", async function () {
    expect(acc1.address).to.equal(await payments.creater());

    const NotOwner = payments.connect(acc2);
    await expect(NotOwner._mint(acc3.address, 50000)).to.revertedWith(
      "Not allowe"
    );

    const TotalSupply = await payments.totalSupply();
    const Mint = await payments._mint(acc3.address, 5000000);
    const NewTotalSupply = await payments.totalSupply();
    await expect(Mint).to.changeTokenBalance(payments, acc3, 5000000);
    expect(NewTotalSupply / 1000000).to.equal(TotalSupply / 1000000 + 5);

    await expect(
      payments._mint(ethers.constants.AddressZero, 50000)
    ).to.revertedWith("ERC20: mint to the zero address");

    await expect(
      payments._mint(ethers.constants.AddressZero, 50000)
    ).to.revertedWith("ERC20: mint to the zero address");

    await expect(Mint)
      .to.emit(payments, "Transfer")
      .withArgs(ethers.constants.AddressZero, acc3.address, 5000000);

    await expect(
      payments._mint(acc1.address, 1500000000000000000000000n)
    ).to.revertedWith("ERC20Capped: cap exceeded");
  });

  it("Function _burn() - usr can burn tokens", async function () {
    expect(acc1.address).to.equal(await payments.creater());

    const NotOwner = payments.connect(acc2);
    await expect(NotOwner._burn(acc3.address, 50000)).to.revertedWith(
      "Not allowe"
    );

    await expect(NotOwner._burn(acc2.address, 50000)).to.revertedWith(
      "Not allowe"
    );

    await expect(payments._burn(acc2.address, 50000)).to.revertedWith(
      "ERC20: burn amount exceeds balance"
    );

    const Burn = await payments._burn(acc1.address, 5000000);
    await expect(Burn).to.changeTokenBalance(payments, acc1, -5000000);

    await expect(Burn)
      .to.emit(payments, "Transfer")
      .withArgs(acc1.address, ethers.constants.AddressZero, 5000000);

    expect(await payments.cap()).to.equal(
      1500000000000000000000000n - 5000000n
    );
  });

  it("Function setNewCreater() - Owner can  set newcreator", async function () {
    await payments.setNewCreater(acc2.address);
    expect(await payments.creater()).to.equal(acc2.address);

    const NewAcc = payments.connect(acc3);
    await expect(NewAcc.setNewCreater(acc3.address)).to.be.revertedWith(
      "Not allowe"
    );
  });
});
