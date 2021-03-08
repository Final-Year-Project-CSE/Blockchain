var CentralAuthority = artifacts.require('./Central_Authority.sol');
var Official = artifacts.require('./Official.sol');
var TaxCollection = artifacts.require('./TaxCollection.sol');


// // FOR ACTUAL EXECUTION
// module.exports = function(deployer){ 
//     deployer.deploy(CentralAuthority);
// }


// FOR TESTING PURPOSE
module.exports = async function(deployer){ //we need to only deploye Central Authority here as other contracts are deployed by Central Authority only
	deployer.deploy(Official); // only deployed for testing purpose

	const accounts = await web3.eth.getAccounts();

	deployer.deploy(TaxCollection, accounts[0], accounts[1]); // only deployed for testing purpose
    deployer.deploy(CentralAuthority);
}