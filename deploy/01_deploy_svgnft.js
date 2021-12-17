const fs = require("fs");
const { ethers } = require("hardhat");
let { networkConfig } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  //deployments and getNamedAccounts are provided by hardhat-deploy

  const { deploy, log } = deployments; // the deployments field itself contains the deploy function
  const { deployer } = await getNamedAccounts(); // this is defined in hardhat config
  const chainId = await getChainId();

  log("-------------------------------");
  // This will create a deployment called 'Token'. By default it will look for an artifact with the same name. The 'contract' option allows you to use a different artifact.
  const SVGNFT = await deploy("SVGNFT", {
    from: deployer,
    log: true, // display the address and gas used in the console
  });
  log(`🟢 You have deployed an NFT contract to ${SVGNFT.address}!`);

  let filepath = "./img/triangle.svg";
  let svg = fs.readFileSync(filepath, { encoding: "utf8" });

  const svgNFTContract = await ethers.getContractFactory("SVGNFT"); //get the details of the contract
  const accounts = await hre.ethers.getSigners(); //get the signers of the accounts
  const signer = accounts[0]; //use the first account
  const svgNFT = new ethers.Contract(SVGNFT.address, svgNFTContract.interface, signer); //.interface provides the ABI of the contract

  // verification of contract, this will only work on testnet and mainnet NOT localhost
  const networkName = networkConfig[chainId]["name"];
  log(`Verify with: \n npx hardhat verify --network ${networkName} ${svgNFT.address}`);

  let transactionResponse = await svgNFT.create(svg);
  let receipt = await transactionResponse.wait(1); //wait for 1 block
  log(`You've made an NFT`);
  log(`You can view the tokenURI here ${await svgNFT.tokenURI(0)}`);
};
