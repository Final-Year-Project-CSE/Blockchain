const Central_Authority = artifacts.require("./Central_Authority.sol");
const Project = artifacts.require("./Project.sol");
const Official = artifacts.require("./Official.sol");
const TaxCollection = artifacts.require("./TaxCollection.sol");

// require('chai')
//     .use(require('chai-as-promised'))
//     .should();

contract("Official", accounts => {
	let instance;
	const owner = accounts[0];

	beforeEach(async function() {
		try {
			instance = await Official.deployed({from: owner, value: 2}); // here passing value: 2 does not set balance to 2, it remains 0
		} catch (error) {
			assert.throws(() => { throw new Error(error) }, Error, "Official couldn't be deployed");
		}
	});

	it("Owner Adds Official", async function() {
		await instance.addOfficial(accounts[1], {from: owner});
		const totalOfficials = await instance.total_officals();
		assert.equal(totalOfficials, 2);
	});

	it("An Official Adds Another Official", async function () {
		await instance.addOfficial(accounts[1], {from: owner});
		await instance.addOfficial(accounts[2], {from: accounts[1]});
		const totalOfficials = await instance.total_officals();
		assert.equal(totalOfficials, 3);
	});

	it("A Non-Official tries to add Another Official", async function () {
		try {
			await instance.addOfficial(accounts[4], {from: accounts[3]});
		} catch (error) {
			const totalOfficials = await instance.total_officals();
			assert.equal(totalOfficials, 3);
		}
	});

	it("Adding an already existing Official", async function () {
		await instance.addOfficial(accounts[1], {from: owner});
		const totalOfficials = await instance.total_officals();
		assert.equal(totalOfficials, 3);
	});

	it("Removing an Official", async function () {
		await instance.removeOfficial(accounts[1], {from: owner});
		const totalOfficials = await instance.total_officals();
		assert.equal(totalOfficials, 2);
	});

	it("Checking Balance", async function () {
		const balance = await instance.getBalance();
		assert.equal(balance, 2);
	});
});

contract("Central_Authority", accounts => {

	it("Central Authority gets successfully deployed", async function() {
		try {
			await Central_Authority.deployed();
		} catch (error) {
			assert.throws(() => { throw new Error(error) }, Error, "Central Authority couldn't be deployed");
		}
	});

	// //define variables to be used

	// beforeEach(async function () {
	// 	// things to be done before each test case
	// });

	// it("What the test case tests", async () => {
	// 	// code for a single test case
	// });

	// // without using await
	// it("desc", function() {
	// 	return ContractName.deployed().then(function(instanceOfContractReturned) {
	// 		return instanceOfContractReturned.someMethod();
	// 	}).then(function(someVariableReturned) {
	// 		assert.equal(someVariableReturned, supposedValue);
	// 		// we can have multiple asserts
	// 	});
	// });

	// describe("Something", () => {

	// 	// this requires chai

 //        it("Something", async () => {
 //        	const instanceOfContract = await ContractName.deployed();
 //            // use the instance to call methods
 //            someVariable.should.equal(something);
 //        });
 //    });
});

// accounts is an array
// use await on async functions to use them in sync in code
// calling any function => f(params required, {from: account[x]});
// get an instance of a contract => await Contract.new({ from: account[x] });
// assert.equal(a,b,"some desc");
// try {
// 	//code
// } catch (error) {
// 	assert.throws(() => { throw new Error(error) }, Error, "Error Desc");
// }
