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
  });

  describe("Function addLevelAndRewardForMeet", function () {
    it("Run emit NewLevel and emit NewLevel", async function () {
      const addLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );

      await expect(addLevelAndReward)
        .to.emit(payments, "NewLevel")
        .withArgs(owner.address, 0);

      await expect(addLevelAndReward)
        .to.emit(payments, "NewLevel")
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

    // проверить что при более 1 встрече увеличивается колдаун
    // проверить что перезагрузка зависит от уровня
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
      console.log(getCooldownTime);

      const reloadedOwner = await payments.suitoption(0);
      const reloadedAcc2 = await payments.suitoption(1);
      expect(await reloadedOwner["reloaded"]).to.be.eq(getCooldownTime);
      expect(await reloadedAcc2["reloaded"]).to.be.eq(getCooldownTime);

      await time.increase(100000);

      const latestBlock = await hre.ethers.provider.getBlock("latest");
      const b = latestBlock.timestamp;
      console.log(b);

      // проблема в том, что он еще где-то день накидывает на кулдаун
      const newAddLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );
    });

    // проверить что колличество ревардов снижается если были уже встречи между людьми
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
    });

    // проверить что уровень от встреч прокачивается
    it("Set parametr correct", async function () {
      const addLevelAndReward = await payments.addLevelAndRewardForMeet(
        owner.address,
        0,
        acc2.address,
        1,
        false
      );
    });
  });
});
