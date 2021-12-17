let { networkConfig } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, get, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  // if we are on local chain (hardhat), what is the link token address?
  // A: There is none
  // So we deploy a fake one for our localchain
  // but for real chains we will use the real ones
  let linkTokenAddress, vrfCoordinatorAddress;
  if (chainId == 31337) {
    // on local chain
    let linkToken = await get("LinkToken");
    linkTokenAddress = linkToken.address;
    let vrfCoordinatorMock = await get("VRFCoordinatorMock");
    vrfCoordinatorAddress = vrfCoordinatorMock.address;
  } else {
    linkTokenAddress = networkConfig[chainId]["linkToken"];
    vrfCoordinatorAddress = networkConfig[chainId]["vrfCoordinator"];
  }
  const keyHash = networkConfig[chainId]["keyHash"];
  const fee = networkConfig[chainId]["fee"];
  let args = [vrfCoordinatorAddress, linkTokenAddress, keyHash, fee];

  log("🟠 Starting Deployment");
  const RandomSVG = await deploy("RandomSVG", {
    from: deployer,
    args: args,
    log: true,
  });
  log("🟢 Successfully deployed RandomSVG contract");
  const networkName = networkConfig[chainId]["name"];
  log(`☑️ Verify with:\n npx hardhat verify --network ${networkName} ${RandomSVG.address} ${args.toString().replace(/,/g, " ")}`);

  // fund with LINK
  log("🟠 Funding RandomSVG contract with LINK tokens");
  const linkTokenContract = await ethers.getContractFactory("LinkToken");
  const accounts = await hre.ethers.getSigners();
  const signer = accounts[0];
  const linkToken = new ethers.Contract(linkTokenAddress, linkTokenContract.interface, signer);
  let fund_tx = await linkToken.transfer(RandomSVG.address, fee);
  await fund_tx.wait(1);
  log("🟢 Successfully funded RandomSVG contract with LINK tokens");

  // creating an NFT
  log("🟠 Creating an NFT...");
  const randomSVGContract = await ethers.getContractFactory("RandomSVG");
  const randomSVG = new ethers.Contract(RandomSVG.address, randomSVGContract.interface, signer);
  let mint_tx = await randomSVG.create({
    gasLimit: 300000,
  });
  receipt = await mint_tx.wait(1);
  tokenId = receipt.events[3].topics[2]; // 4th event emitted is the CreatedRandomSVG event, topics[0] will be the hash of the entire event
  log(`🟠 Waiting for Chainlink node to respond...`);
  if (chainId != 31337) {
  } else {
    const VRFCoordinatorMock = await deployments.get("VRFCoordinatorMock");
    vrfCoordinator = await ethers.getContractAt("VRFCoordinatorMock", VRFCoordinatorMock.address, signer);
    let vrf_tx = await vrfCoordinator.callBackWithRandomness(receipt.logs[3].topics[1], 6969, randomSVG.address);
    await vrf_tx.wait(1);
    log("Mock chainlink callback done, finsihing the mint!");
    let finish_tx = await randomSVG.finishMint(tokenId, { gasLimit: 2000000 });
    await finish_tx.wait(1);
    log(`🚀 NFT Minted, You can view the tokenURI here: ${await randomSVG.tokenURI(tokenId)}`);
  }
};

module.exports.tags = ["all", "rsvg"];
