var CentralAuthority = artifacts.require('./Central_Authority.sol');
var Official = artifacts.require('./Official.sol');
var TaxCollection = artifacts.require('./TaxCollection.sol');
// var Project = artifacts.require('./Project');

module.exports = async function(deployer){

	const accounts = await web3.eth.getAccounts();

	deployer.deploy(Official, {from: accounts[0]}); // only deployed for testing purpose

	// deployer.deploy(CentralAuthority, {from: accounts[0]}).then(function() {
	// 	return deployer.deploy(TaxCollection, CentralAuthority.address, {from: accounts[1]});
	// });
}