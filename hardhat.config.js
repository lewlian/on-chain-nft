require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");
require("@nomiclabs/hardhat-ethers");
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetworks: "hardhat",
  networks: {
    hardhat: {},
    rinkeby: {
      url:, 
      accounts: {

      }
    }
  },
  solidity: "0.8.4",
  namedAccounts: {
    deployer: {
      default: 0, // Account 0 will be the default account
    },
  },
};
