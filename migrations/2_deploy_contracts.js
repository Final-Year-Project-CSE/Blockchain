var CentralAuthority = artifacts.require('./Central_Authority.sol');
var Official = artifacts.require('./Official.sol');
var TaxCollection = artifacts.require('./TaxCollection.sol');
// var Project = artifacts.require('./Project');

module.exports = async function(deployer){

	const accounts = await web3.eth.getAccounts();
	const centralAuthContract = await deployer.deploy(CentralAuthority, {from: accounts[0]});
	const taxCollectionContract = await deployer.deploy(TaxCollection, centralAuthContract.address, {from: accounts[0]});

}