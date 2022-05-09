const { network, ethers } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const fs = require("fs")

module.exports = async ({ getNameAccounts, deployments}) => {
  const { deploy, log } = deployments
  const { deployer } = await getNameAccounts()
  const chainId = network.config.chainId
  let vrfCoordinatorV2Address, subscriptionId

  if (chainId == 31337) {
    // Create VRF V2 Subscription
    const vrfCoordinatorV2Address = await ethers.getContract("VRFCoordinatorV2")
    vrfCoordinatorV2Address = vrfCoordinatorV2Address.address
    const txResponse = await vrfCoordinatorV2Address.createSubscription()
    const txReceipt = await txResponse.wait() 
    subscriptionId = txReceipt.events[0].args.subscriptionId
    // Fund the subscription
    await vrfCoordinatorV2Address.fundSubscription(subscriptionId, FUND_AMOUNT)
  } else {
    vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2
    subscriptionId = networkConfig[chainId].subscriptionId
  }
}

module.exports.tags = ['all', 'mocks', 'meta', 'main']
