require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-solhint");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking: {
        url: process.env.INFURA_URL_ETH,
        blockNumber: 16974700,
      },
    },
    goerly: {
      url: process.env.INFURA_URL_GOERLY,
      accounts: [process.env.PRIVATE_KEY],
    },
    sepolia: {
      url: process.env.INFURA_URL_SEPOLYA,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000,
      },
    },
  },
};
