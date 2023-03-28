require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    goerly: {
      url: "https://goerli.infura.io/v3/f8bf00d32b6448a3818f59c6f16e7f86",
      accounts: [
        "1effc9349ce5481f0cdf0fb07e8845be6051ee58c57d6e95e6b90bfb8f55a964",
        "052b68ee102d486773d8be0309ab30ac07ed9feb6da21e49d061e249fe9841b4",
        "a70b940c6edc673cb61033b5e3355ee7e1f3aef0e2ce5b7f5b199527210f64ef",
      ],
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/f8bf00d32b6448a3818f59c6f16e7f86",
      accounts: [
        "1effc9349ce5481f0cdf0fb07e8845be6051ee58c57d6e95e6b90bfb8f55a964",
        "052b68ee102d486773d8be0309ab30ac07ed9feb6da21e49d061e249fe9841b4",
        "a70b940c6edc673cb61033b5e3355ee7e1f3aef0e2ce5b7f5b199527210f64ef",
      ],
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
  // networks: {
  //   hardhat: {
  //     chainId: 1337,
  //   },
  // },
};
