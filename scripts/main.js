const hre = require("hardhat")

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const TheRegistry = await hre.ethers.getContractFactory("TheRegistry")
  console.log(process.env.SISMO_APP_ID)
  const theRegistry = await TheRegistry.deploy(process.env.SISMO_APP_ID)

  await theRegistry.deployed()

  console.log("TheRegistry deployed to:", theRegistry.address)
}
exports.main = main
