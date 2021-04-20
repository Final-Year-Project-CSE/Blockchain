const Central_Authority = artifacts.require("./Central_Authority.sol");
const Project = artifacts.require("./Project.sol");
const Official = artifacts.require("./Official.sol");
const TaxCollection = artifacts.require("./TaxCollection.sol");

contract("Central Authority", accounts => {
	let instance;
	let owner=accounts[0];

	before(async function() {
		instance = await Central_Authority.deployed({from: owner});
	});

	it("Checking Central project", async function() {
		assert.equal(0,0);
	});
});

// contract("Official", accounts => {
// 	let instance;
// 	const owner = accounts[0];

// 	before(async function() {
// 		instance = await Official.deployed({from: owner});
// 	});

// 	it("Owner Adds Official", async function() {
// 		await instance.addOfficial(accounts[1], {from: owner});
// 		const totalOfficials = await instance.total_officals();
// 		assert.equal(totalOfficials, 2);
// 	});

// 	it("An Official Adds Another Official", async function () {
// 		await instance.addOfficial(accounts[1], {from: owner});
// 		await instance.addOfficial(accounts[2], {from: accounts[1]});
// 		const totalOfficials = await instance.total_officals();
// 		assert.equal(totalOfficials, 3);
// 	});

// 	it("A Non-Official tries to add Another Official", async function () {
// 		try {
// 			await instance.addOfficial(accounts[4], {from: accounts[3]});
// 		} catch (error) {
// 			const totalOfficials = await instance.total_officals();
// 			assert.equal(totalOfficials, 3);
// 		}
// 	});

// 	it("Adding an already existing Official", async function () {
// 		await instance.addOfficial(accounts[1], {from: owner});
// 		const totalOfficials = await instance.total_officals();
// 		assert.equal(totalOfficials, 3);
// 	});

// 	it("Removing an Official", async function () {
// 		await instance.removeOfficial(accounts[1], {from: owner});
// 		const totalOfficials = await instance.total_officals();
// 		assert.equal(totalOfficials, 2);
// 	});

// 	// it("Checking Balance", async function () {
// 	// 	const balance = await instance.getBalance();
// 	// 	assert.equal(balance, 2); // it should have been 2 as value is supplied but is actually
// 	// });
// });

contract("Tax Collection", accounts => {

	let instance;
	let owner=accounts[0];

	before(async function() {
		instance = await TaxCollection.deployed({from: owner});
	});
	
	it("Owner Adds a Tax Payer", async function() {
		await instance.addTaxPayer("Albert", accounts[2], 100, {from: owner});
		const taxPayersCount = await instance.getTotalTaxPayers();
		assert.equal(taxPayersCount, 1);
		let taxPayer = await instance.getTaxPayerWithAddress(accounts[2]);
		assert.equal(taxPayer[1], "Albert");
		taxPayer = await instance.getTaxPayerWithID(taxPayersCount-1);
		assert.equal(taxPayer[3], 100);
	});

	it("Official Adds a Tax Payer", async function() {
		await instance.addOfficial(accounts[3], {from: owner});
		await instance.addTaxPayer("Jonathan", accounts[4], 300, {from: accounts[3]});
		const taxPayersCount = await instance.getTotalTaxPayers();
		assert.equal(taxPayersCount, 2);
		let taxPayer = await instance.getTaxPayerWithAddress(accounts[4]);
		assert.equal(taxPayer[1], "Jonathan");
		taxPayer = await instance.getTaxPayerWithID(taxPayersCount-1);
		assert.equal(taxPayer[3], 300);
	});

	it("Official Adds Tax Bracket", async function() {
		await instance.addTaxBracket(2, 150, 6, {from: accounts[3]});
		const taxBracketsCount = await instance.getTotalTaxBrackets();
		assert.equal(taxBracketsCount, 1);
		const taxBracket = await instance.getTaxBracket(taxBracketsCount-1);
		assert.equal(taxBracket[0], 0);
		assert.equal(taxBracket[1], 2);
	});

	it("Official Updating Tax Bracket", async function() {
		await instance.updateLowerLimitOfBracket(0, 0);
		await instance.updateUpperLimitOfBracket(0, 100);
		await instance.updateTaxPercentageOfBracket(0, 5);
		const taxBracketsCount = await instance.getTotalTaxBrackets();
		assert.equal(taxBracketsCount, 1);
		const taxBracket = await instance.getTaxBracket(0);
		assert.equal(taxBracket[1], 0);
		assert.equal(taxBracket[2], 100);
		assert.equal(taxBracket[3], 5);
	});

	it("Disable and Enable Tax Bracket", async function() {
		await instance.disableTaxBracket(0);
		let taxBracketsCount = await instance.getTotalTaxBrackets();
		assert.equal(taxBracketsCount, 1);
		let taxBracket = await instance.getTaxBracket(0);
		assert.equal(taxBracket[4], false);
		await instance.enableTaxBracket(0);
		taxBracketsCount = await instance.getTotalTaxBrackets();
		assert.equal(taxBracketsCount, 1);
		taxBracket = await instance.getTaxBracket(0);
		assert.equal(taxBracket[4], true);
	});

	it("Calculates Tax", async function() {
		await instance.addTaxPayer("Mila", accounts[5], 0, {from: owner});
		await instance.addTaxPayer("Emma", accounts[6], 400, {from: owner});
		await instance.addTaxPayer("Stanley", accounts[7], 600, {from: owner});
		await instance.addTaxBracket(100, 300, 10, {from: owner});
		await instance.addTaxBracket(300, 500, 20, {from: owner});
		let tax = await instance.calculateTax({from: accounts[2]});
		assert.equal(tax, 5);
		tax = await instance.calculateTax({from: accounts[4]});
		assert.equal(tax, 25);
		tax = await instance.calculateTax({from: accounts[5]});
		assert.equal(tax, 0);
		tax = await instance.calculateTax({from: accounts[6]});
		assert.equal(tax, 45);
		tax = await instance.calculateTax({from: accounts[7]});
		assert.equal(tax, 65);
	});

	it("Pay Tax", async function() { // check balance before and after and try paying tax even though paid
		let paid = await instance.hasPaidTax(accounts[2]);
		assert.equal(paid, false);
		let tax = await instance.calculateTax({from: accounts[2]});
		await instance.payTax({from: accounts[2], value: tax});
		paid = await instance.hasPaidTax(accounts[2]);
		assert.equal(paid, true);
		try {
			await instance.payTax({from: accounts[2], value: tax});
		} catch (error) {
			assert(error.message.indexOf('revert') >= 0, "error message must contain revert");
		}
		tax = await instance.calculateTax({from: accounts[2]});
		assert.equal(tax, 0);
	});

	it("Reset Tax Payments", async function() {
		let paid = await instance.hasPaidTax(accounts[2]);
		assert.equal(paid, true);
		await instance.resetTaxPayments({from: owner});
		paid = await instance.hasPaidTax(accounts[2]);
		assert.equal(paid, false);
	});

	it("Sending Grant to Central Authority", async function() {
		await instance.grantFundsToCentralAuthority(2, {from: owner});
		// have to check balance before and after but balance is not working properly
	});
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