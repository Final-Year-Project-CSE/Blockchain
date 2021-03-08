var CentralAuthority = artifacts.require('./Central_Authority.sol');
var Official = artifacts.require('./Official.sol');

module.exports = function(deployer){
	deployer.deploy(Official);
    deployer.deploy(CentralAuthority);
}