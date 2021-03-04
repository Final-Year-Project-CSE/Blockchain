var Ledger = artifacts.require('./Ledger.sol');

module.exports = function(deployer){
    deployer.deploy(Election);
}