const ethers = require("ethers");

const Roles = artifacts.require("./Roles.sol");
const Pool = artifacts.require("./Pool.sol");

const Configuration = artifacts.require('./BallotConfiguration.sol');
const Ballot = artifacts.require('./Ballot.sol');

const GovernanceRole = 1;
const LiquidityProviderRole = 2;

module.exports = async function(deployer, network, accounts){

  await deployer;

  await deployer.deploy(Roles);
  const rolesInstance = await Roles.deployed();
  
  if (network === "in_memory") {
    await rolesInstance.setUserRole(accounts[1], LiquidityProviderRole, true);
    await rolesInstance.setUserRole(accounts[2], LiquidityProviderRole, true);
    await rolesInstance.setUserRole(accounts[3], LiquidityProviderRole, true);
  }

  await deployer.deploy(Pool, Roles.address);
  const poolInstance = await Pool.deployed();
  const poolABI = new ethers.utils.Interface(Pool.abi);

  await deployer.deploy(Configuration);
  const configurationInstance = await Configuration.deployed();
  await configurationInstance.setProvider("pool", Pool.address);
  await configurationInstance.setProvider("roles", Roles.address);
  await configurationInstance.setParameter("maxActivePolls", 3);

  await deployer.deploy(Ballot, Configuration.address);
  const ballotABI = new ethers.utils.Interface(Ballot.abi);

  await rolesInstance.setRoleCapability(LiquidityProviderRole, Ballot.address, ballotABI.functions.startPoll.sighash, true);
  await rolesInstance.setRoleCapability(LiquidityProviderRole, Ballot.address, ballotABI.functions.vote.sighash, true);
  await rolesInstance.setUserRole(Ballot.address, GovernanceRole, true);
  await rolesInstance.setRoleCapability(GovernanceRole, Pool.address, poolABI.functions.setInterest.sighash, true);
  
};
