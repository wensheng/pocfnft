require('dotenv').config()
const HDWalletProvider = require("@truffle/hdwallet-provider");
const infura_rinkeby_link = "wss://rinkeby.infura.io/ws/v3/" + process.env.INFURAID
const seed_phrase = process.env.SEED_PHRASE
const account1 = process.env.MMACCOUNT01

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    rinkeby: {
      provider: () => new HDWalletProvider(seed_phrase, infura_rinkeby_link),
      network_id: 4,
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      from: account1
    }
  },
  mocha: {
  },
  compilers: {
    solc: {
      version: "0.8.3",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};
