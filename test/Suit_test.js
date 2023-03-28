const { expect } = require("chai");
const { ethers } = require("hardhat");
const { assert } = require("assert");
// https://stermi.medium.com/how-to-create-tests-for-your-solidity-smart-contract-9fbbc4f0a319
// полезная статья из нее можно взять про разворачивание сразу двух контрактов
describe("ERC20_SUIT_TOKEN", function () {
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
  });

  it("Deploy - shoud be deployed and address correct", async function () {
    expect(payments.address).to.be.properAddress;
    expect(paymentsErc20.address).to.be.properAddress;
  });

  it("Deploy - rigth creator ERC20 and other params", async function () {
    expect(payments.address).to.equal(await paymentsErc20.creater());
    expect(await payments.name()).to.equal("SuitToken");
    expect(await payments.symbol()).to.equal("ST");
  });

  it("Deploy - test platform fee more 10 to deploy", async function () {
    const SuitToken = await ethers.getContractFactory(
      "ERC721SuitUnlimited",
      owner
    );
    await expect(
      SuitToken.deploy("SuitToken", "ST", 10001, paymentsErc20.address)
    ).to.be.revertedWith("can't more than 10 percent");
  });

  it("Receive() - contract recieve ethers", async function () {
    tx = {
      to: payments.address,
      value: 100,
    };
    const NewTransaction = await owner.sendTransaction(tx);
    await expect(() => NewTransaction).to.changeEtherBalance(
      payments.address,
      100
    );
  });

  it("SupportsInterface() - test check interface", async function () {
    expect(await payments.supportsInterface(0x5b5e139f)).to.true;
    expect(await payments.supportsInterface(0x80ac58cd)).to.true;
  });

  it("BalanceOf() - test check balance", async function () {
    await expect(
      payments.balanceOf(ethers.constants.AddressZero)
    ).to.be.revertedWith("ERC721: address zero is not a valid owner");

    const SetPriceOwner = payments.setPrice(500);
    const Mint = payments._safeMint(owner.address, {
      value: 550,
    });
    await expect(Mint).to.changeTokenBalance(payments, owner, 1);
    expect(await payments.balanceOf(owner.address)).to.equal(1);
    await expect(Mint).to.changeEtherBalance(payments, 550);
  });

  it("OwnerOf() - test check owner token", async function () {
    const SetPriceOwner = payments.setPrice(500);
    const Mint = await payments._safeMint(owner.address, {
      value: 550,
    });
    const Owner = await payments.ownerOf(0);
    await expect(Owner).to.equal(owner.address);

    await expect(payments.ownerOf(1)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );
  });

  it("TokenURI() and SetBaseURI() - test check chow tokenURI and set", async function () {
    const SetPriceOwner = payments.setPrice(500);
    const Mint = await payments._safeMint(owner.address, {
      value: 550,
    });
    const Uri = await payments.tokenURI(0);
    await expect(Uri).to.equal("");

    const BaseUri = "www.Boris.com";
    const TokenId = 0;
    const NewBaseUri = await payments.setBaseURI(BaseUri);
    const NewUri = await payments.tokenURI(TokenId);
    await expect(NewUri).to.equal("www.Boris.com0");

    await expect(payments.tokenURI(1)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );
  });

  it("Approve() and GetApproved() - user can approve token and get approve", async function () {
    const tokenId = 0;
    const SetPriceOwner = payments.setPrice(500);
    const Mint = await payments._safeMint(owner.address, {
      value: 550,
    });

    await expect(payments.approve(acc2.address, 1)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );

    await expect(payments.approve(owner.address, 0)).to.be.revertedWith(
      "ERC721: approval to current owner"
    );

    const NotOwner = payments.connect(acc2);
    await expect(NotOwner.approve(acc2.address, 0)).to.be.revertedWith(
      "ERC721: approve caller is not token owner or approved for all"
    );

    const Approve = await payments.approve(acc2.address, tokenId);
    const GerApprove = await payments.getApproved(0);
    await expect(GerApprove).to.equal(acc2.address);

    await expect(payments.getApproved(1)).to.be.revertedWith(
      "ERC721: invalid token ID"
    );

    await expect(Approve)
      .to.emit(payments, "Approval")
      .withArgs(owner.address, acc2.address, 0);
  });

  it("SetApprovalForAll() and IsApprovedForAll() - user can approve all token and get all approve", async function () {
    const tokenId = 0;
    const SetPriceOwner = payments.setPrice(500);
    const Mint = await payments._safeMint(owner.address, {
      value: 550,
    });

    await expect(
      payments.setApprovalForAll(owner.address, true)
    ).to.be.revertedWith("ERC721: approve to caller");

    const Approve = await payments.setApprovalForAll(acc2.address, true);
    await expect(await payments.isApprovedForAll(owner.address, acc2.address))
      .to.true;

    await expect(Approve)
      .to.emit(payments, "ApprovalForAll")
      .withArgs(owner.address, acc2.address, true);
  });

  it("TransferFrom() - user can transfer token", async function () {
    const tokenId = 0;
    const SetPriceOwner = payments.setPrice(500);
    const Mint = await payments._safeMint(owner.address, {
      value: 550,
    });

    await expect(
      payments.transferFrom(owner.address, ethers.constants.AddressZero, 0)
    ).to.be.revertedWith("ERC721: transfer to the zero address");

    await expect(await payments.ownerOf(0)).to.be.equal(owner.address);
    const transfer = await payments.transferFrom(
      owner.address,
      acc2.address,
      0
    );
    await expect(await payments.ownerOf(0)).to.be.equal(acc2.address);
    await expect(await payments.balanceOf(acc2.address)).to.be.equal(1);
    await expect(transfer).to.changeTokenBalances(
      payments,
      [owner, acc2],
      [-1, 1]
    );

    await expect(transfer)
      .to.emit(payments, "Transfer")
      .withArgs(owner.address, acc2.address, 0);

    await expect(
      payments.transferFrom(owner.address, acc2.address, 0)
    ).to.be.revertedWith("ERC721: caller is not token owner or approved");

    const newUserThree = payments.connect(acc3);
    const newUserTwo = payments.connect(acc2);
    const Approve = await newUserTwo.approve(acc3.address, 0);
    const transfertwo = await newUserThree.transferFrom(
      acc2.address,
      owner.address,
      0
    );
    await expect(transfertwo).to.changeTokenBalances(
      payments,
      [acc2, owner],
      [-1, 1]
    );
    const GerApprove = await payments.getApproved(0);
    await expect(GerApprove).to.equal(ethers.constants.AddressZero);
  });

  it("SafeTransferFrom() - user can safe transfer token", async function () {
    const SetPriceOwner = payments.setPrice(500);
    const Mint = await payments._safeMint(owner.address, {
      value: 550,
    });

    await expect(
      payments["safeTransferFrom(address,address,uint256)"](
        owner.address,
        paymentsErc20.address,
        0
      )
    ).to.be.reverted;

    await expect(await payments.ownerOf(0)).to.be.equal(owner.address);
    const transfer = await payments[
      "safeTransferFrom(address,address,uint256)"
    ](owner.address, acc2.address, 0);
    await expect(await payments.ownerOf(0)).to.be.equal(acc2.address);
    await expect(await payments.balanceOf(acc2.address)).to.be.equal(1);
    await expect(transfer).to.changeTokenBalances(
      payments,
      [owner, acc2],
      [-1, 1]
    );

    await expect(transfer)
      .to.emit(payments, "Transfer")
      .withArgs(owner.address, acc2.address, 0);

    await expect(
      payments["safeTransferFrom(address,address,uint256)"](
        owner.address,
        acc2.address,
        0
      )
    ).to.be.revertedWith("ERC721: caller is not token owner or approved");
  });

  it("_safeMint() - user can mint token", async function () {
    const SetPriceOwner = payments.setPrice(500);
    const MintOne = await payments._safeMint(owner.address, {
      value: 550,
    });
    const MintTwo = await payments._safeMint(owner.address, {
      value: 550,
    });
    await expect(MintTwo)
      .to.emit(payments, "Transfer")
      .withArgs(ethers.constants.AddressZero, owner.address, 1);
    await expect(await payments.ownerOf(1)).to.be.equal(owner.address);
    await expect(await payments.balanceOf(owner.address)).to.be.equal(2);
    const level = await payments.suitoption(1);
    await expect(await level.level).to.be.equal(1);

    const block = await ethers.provider.getBlock(MintTwo.blockHash);
    await expect(await level.reloaded).to.be.equal(block.timestamp);

    await expect(
      payments._safeMint(paymentsErc20.address, {
        value: 550,
      })
    ).to.be.reverted;

    await expect(
      payments._safeMint(owner.address, {
        value: 450,
      })
    ).to.be.revertedWith("Ether value sent is not correct");

    await expect(
      payments._safeMint(acc2.address, {
        value: 550,
      })
    ).to.be.revertedWith("You can only buy with your wallet");

    const saleInactive = await payments.flipSaleState();
    const newUser = payments.connect(acc2);
    await expect(newUser.flipSaleState()).to.be.revertedWith("Not an owner");
    await expect(
      payments._safeMint(owner.address, {
        value: 550,
      })
    ).to.be.revertedWith("Sale must be active to mint");
  });

  it("GetBalance() - owner can see balance contract", async function () {
    const MintOne = await payments._safeMint(owner.address, {
      value: 50000000000001000n,
    });

    expect(await payments.getBalance()).to.be.equal(50000000000001000n);

    const newUSer = payments.connect(acc2);
    await expect(newUSer.getBalance()).to.be.revertedWith("Not an owner");
  });

  it("SetPrice() and GetPrice() - owner can set new price", async function () {
    const NewUser = payments.connect(acc2);
    const SetPrice = NewUser.setPrice(500);
    await expect(SetPrice).to.be.revertedWith("Not an owner");

    const SetPriceOwner = payments.setPrice(500);
    expect(await payments.getPrice()).to.equal(500);

    const SetPriceZero = payments.setPrice(0);
    await expect(SetPriceZero).to.be.revertedWith("Price can`t 0");
  });

  it("Function withdraw() - shound allow owner to withdraw funds", async function () {
    tx = {
      to: payments.address,
      value: 100,
    };
    const NewTransaction = await owner.sendTransaction(tx);

    const WithDraw = await payments.withdraw();

    await expect(() => WithDraw).to.changeEtherBalances(
      [payments.address, owner.address],
      [-100, 100]
    );
  });

  it("Function withdraw() - shound not allow other accounts to withdraw funds", async function () {
    tx = {
      to: payments.address,
      value: 100,
    };
    await owner.sendTransaction(tx);

    await expect(payments.connect(acc2).withdraw()).to.be.revertedWith(
      "Not an owner"
    );
  });

  it("Function totalSupply() - user can see total token", async function () {
    const SetPriceOwner = payments.setPrice(500);
    for (i = 0; i <= 5; i++) {
      await payments._safeMint(owner.address, {
        value: 550,
      });
    }
    expect(await payments.totalSupply()).to.be.equal(5);
  });

  it("Function listNft() - user can sell nft", async function () {
    const SetPriceOwner = payments.setPrice(500);
    await payments._safeMint(owner.address, {
      value: 550,
    });

    const sell = await payments.listNft(0, 700);
    const listNFT = await payments.getListedNFT(owner.address, 0);
    await expect(await listNFT["onsail"]).to.true;

    await expect(sell)
      .to.emit(payments, "ListedNFT")
      .withArgs(0, 700, owner.address, true);

    await expect(payments.connect(acc2).listNft(0, 700)).to.be.revertedWith(
      "Not owner NFT"
    );

    await expect(payments.listNft(0, 700)).to.be.revertedWith(
      "Tolen already listed"
    );
  });

  it("Function cancelListedNFT() - user can cancel sell", async function () {
    const SetPriceOwner = payments.setPrice(500);
    await payments._safeMint(owner.address, {
      value: 550,
    });

    await expect(payments.cancelListedNFT(0)).to.be.revertedWith(
      "Token not listed"
    );

    const sell = await payments.listNft(0, 700);
    const listNFT = await payments.getListedNFT(owner.address, 0);
    await expect(await listNFT["onsail"]).to.true;

    await expect(payments.connect(acc2).cancelListedNFT(0)).to.be.revertedWith(
      "Not owner NFT"
    );

    const cancellSell = await payments.cancelListedNFT(0);
    const cancelNFT = await payments.getListedNFT(owner.address, 0);
    await expect(await cancelNFT["onsail"]).to.false;

    await expect(cancellSell)
      .to.emit(payments, "CancelListedNFT")
      .withArgs(0, owner.address);
  });

  it("Function buyNFT() - user can buy NFT", async function () {
    const SetPriceOwner = payments.setPrice(500);
    await payments._safeMint(owner.address, {
      value: 550,
    });

    await expect(payments.buyNFT(owner.address, 0)).to.be.revertedWith(
      "NFT not on sale"
    );

    const sell = await payments.listNft(0, 700);
    const listNFT = await payments.getListedNFT(owner.address, 0);
    await expect(await listNFT["onsail"]).to.true;

    const buyNFT = await payments.connect(acc2).buyNFT(owner.address, 0, {
      value: 850,
    });

    await expect(buyNFT).to.changeTokenBalances(
      payments,
      [owner, acc2],
      [-1, 1]
    );

    await expect(buyNFT)
      .to.emit(payments, "BoughtNFT")
      .withArgs(0, 850, owner.address, acc2.address);
  });
});
