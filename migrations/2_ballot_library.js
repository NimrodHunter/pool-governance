const DLL = artifacts.require("./DLL.sol");
const Ballot = artifacts.require("./Ballot.sol");

module.exports = function(deployer){
  deployer.deploy(DLL);
  deployer.link(DLL, Ballot);
};
