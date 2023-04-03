const { expect } = require("chai");
const { ethers } = require("hardhat");
const { assert } = require("assert");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");
const { BigNumber } = require("ethers");
const { mine, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("LevelREward", function () {
  let owner;
  let acc2;
  let acc3;
  let payments;

  this.beforeEach(async function () {
    const InitialSuplay = 100;

    [owner, acc2, acc3] = await ethers.getSigners();
    const ERC20 = await ethers.getContractFactory("ERC20_SUIT_TOKEN", owner);
    paymentsErc20 = await ERC20.deploy(InitialSuplay);
    await paymentsErc20.deployed(InitialSuplay);

    const SuitToken = await ethers.getContractFactory(
      "ERC721SuitUnlimited",
      owner
    );
    payments = await SuitToken.deploy(
      "SuitToken",
      "ST",
      3,
      paymentsErc20.address
    );
    await payments.deployed("SuitToken", "ST", 3, paymentsErc20.address);

    await paymentsErc20.setNewCreater(payments.address);

    const SetPriceOwner = payments.setPrice(500);
    const MintOwner = await payments._safeMint(owner.address, {
      value: 550,
    });
    const MintAcc2 = await payments.connect(acc2)._safeMint(acc2.address, {
      value: 550,
    });
    const MintAcc3 = await payments.connect(acc3)._safeMint(acc3.address, {
      value: 550,
    });
  });

  describe("Function addLevelAndRewardForMeet", function () {
    it("Run emit AddReward and emit AddReward", async function () {
      const addLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      await expect(addLevelAndReward)
        .to.emit(payments, "AddReward")
        .withArgs(owner.address, 0);

      await expect(addLevelAndReward)
        .to.emit(payments, "AddReward")
        .withArgs(acc2.address, 1);
    });

    it("Function _setMeetCount and showMeetCount work", async function () {
      const addLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        0
      );

      expect(await payments.showMeetCount(0, 1)).to.be.eq(1);
      expect(await payments.showMeetCount(1, 0)).to.be.eq(1);
    });

    it("Set reloaded time for User and Invited", async function () {
      const addLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );
      const showBlock = await ethers.provider.getBlock(
        addLevelAndReward.blockHash
      );
      const getCooldownTime = showBlock.timestamp + 86400;

      const reloadedOwner = await payments.suitoption(0);
      const reloadedAcc2 = await payments.suitoption(1);
      expect(await reloadedOwner["reloaded"]).to.be.eq(getCooldownTime);
      expect(await reloadedAcc2["reloaded"]).to.be.eq(getCooldownTime);

      await time.increase(86400);

      const newAddLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      const showNewBlock = await ethers.provider.getBlock(
        newAddLevelAndReward.blockHash
      );
      const getCooldownTimeNew = showNewBlock.timestamp + 86400 + 86400;
      const reloadedOwnerTwo = await payments.suitoption(0);
      const reloadedAcc2Two = await payments.suitoption(1);
      expect(await reloadedOwnerTwo["reloaded"]).to.be.eq(getCooldownTimeNew);
      expect(await reloadedAcc2Two["reloaded"]).to.be.eq(getCooldownTimeNew);

      await time.increase(172800);

      const newAddLevelAndReward3 = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      await expect(newAddLevelAndReward3)
        .to.emit(payments, "NewLevel")
        .withArgs(owner.address, 0);

      await expect(newAddLevelAndReward3)
        .to.emit(payments, "NewLevel")
        .withArgs(acc2.address, 1);

      const showNewBlock3 = await ethers.provider.getBlock(
        newAddLevelAndReward3.blockHash
      );
      const getCooldownTimeNew3 =
        showNewBlock3.timestamp + 86400 + 129600 - 21600; // user have new level 2 (-21600 6 hour)
      const reloadedOwnerThree = await payments.suitoption(0);
      const reloadedAcc2Three = await payments.suitoption(1);
      expect(await reloadedOwnerThree["reloaded"]).to.be.eq(
        getCooldownTimeNew3
      );
      expect(await reloadedAcc2Three["reloaded"]).to.be.eq(getCooldownTimeNew3);

      // проверили что число встреч меняется
      expect(await payments.showMeetCount(0, 1)).to.be.eq(3);
      expect(await payments.showMeetCount(1, 0)).to.be.eq(3);
    });

    it("Function _rewardToken work correct", async function () {
      const addLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      await expect(addLevelAndReward)
        .to.emit(payments, "Responce")
        .withArgs(true);

      await expect(addLevelAndReward)
        .to.emit(payments, "Responce")
        .withArgs(true);

      const rewardOwner = 10 * 10;
      const rewardAcc2 = 10 * (10 + 5);
      expect(await paymentsErc20.balanceOf(owner.address)).to.be.equal(
        100000000000000000000n + BigInt(rewardOwner)
      );
      expect(await paymentsErc20.balanceOf(acc2.address)).to.be.equal(
        rewardAcc2
      );

      await time.increase(86400);

      const newAddLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      const rewardOwnerTwo = 10 * (10 - 5);
      const rewardAcc2Two = 10 * (10 + 5 - 5);
      expect(await paymentsErc20.balanceOf(owner.address)).to.be.equal(
        100000000000000000000n + BigInt(rewardOwner + rewardOwnerTwo)
      );
      expect(await paymentsErc20.balanceOf(acc2.address)).to.be.equal(
        rewardAcc2 + rewardAcc2Two
      );

      await time.increase(172800);

      const newAddLevelAndReward3 = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      const rewardOwnerThree = 10 * (10 - 5 + 7);
      const rewardAcc2Three = 10 * (10 + 5 - 5 + 7);
      expect(await paymentsErc20.balanceOf(owner.address)).to.be.equal(
        100000000000000000000n +
          BigInt(rewardOwner + rewardOwnerTwo + rewardOwnerThree)
      );
      expect(await paymentsErc20.balanceOf(acc2.address)).to.be.equal(
        rewardAcc2 + rewardAcc2Two + rewardAcc2Three
      );

      await expect(
        payments.addLevelAndRewardForMeet(
          owner.address,
          0,
          acc2.address,
          1,
          false
        )
      ).to.be.revertedWith("Too early for user");

      const newAcc3 = payments.connect(acc3);
      await expect(
        newAcc3.addLevelAndRewardForMeet(acc3.address, 2, acc2.address, 1, true)
      ).to.be.revertedWith("Not enouth level to meet");
    });

    it("Function addLevelForApgrade() - work correct", async function () {
      const payUpgrade = await payments.addLevelForApgrade(owner.address, 0);

      await expect(payUpgrade)
        .to.emit(payments, "Upgrade")
        .withArgs(owner.address, 0);

      expect(await paymentsErc20.balanceOf(owner.address)).to.be.equal(
        100000000000000000000n - 100000000000000000n
      );

      await expect(payUpgrade).to.emit(payments, "Responce").withArgs(true);

      const color = await payments.suitoption(0);
      expect(await color["color"]).to.be.eq(2);

      const payUpgradeTwo = await payments.addLevelForApgrade(owner.address, 0);

      const payUpgradeFree = await payments.addLevelForApgrade(
        owner.address,
        0
      );

      expect(await paymentsErc20.balanceOf(owner.address)).to.be.equal(
        100000000000000000000n - 600000000000000000n
      );

      const colorNew = await payments.suitoption(0);
      expect(await colorNew["color"]).to.be.eq(4);
      expect(await colorNew["level"]).to.be.eq(2);

      await expect(
        payments.connect(acc2).addLevelForApgrade(acc2.address, 1)
      ).to.be.revertedWith("Cant spend token");

      await expect(
        payments.addLevelForApgrade(acc2.address, 1)
      ).to.be.revertedWith("Not an owner to update tokens");
    });

    it("Function _priceForUpgrade() - work correct", async function () {
      const priceUpgrade = await payments._priceForUpgrade(0);

      expect(priceUpgrade).to.be.equal(100000000000000000n);

      const addLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      await time.increase(86400);

      const newAddLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      await time.increase(172800);

      const newAddLevelAndReward3 = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      const priceUpgradeNew = await payments._priceForUpgrade(0);

      expect(priceUpgradeNew).to.be.equal(700000000000000000n);
    });
  });
});
