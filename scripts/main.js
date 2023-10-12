const hre = require("hardhat");


async function main() {
// Hardhat always runs the compile task when running scripts with its command
// line interface.
//
// If this script is run directly using `node` you may want to call compile
// manually to make sure everything is compiled
// await hre.run('compile');
// We get the contract to deploy
const Docissue = await hre.ethers.getContractFactory("Docissue");
console.log(process.env.SISMO_APP_ID);
const docissue = await Docissue.deploy(process.env.SISMO_APP_ID);

await docissue.deployed();

console.log("Docissue deployed to:", docissue.address);
}
exports.main = main;
