pragma solidity ^0.5.16;

import "./Official.sol";

contract TaxCollection is Official{

    address payable public centralAuthorityAddress;

    struct TaxBracket {
        uint code;
        uint lowerLimit;
        uint upperLimit;
        uint percentage;
        bool validity;
    }

    mapping(uint => TaxBracket) taxBrackets;
    uint bracketCount;

    struct TaxPayer {
        uint id;
        string name;
        bool taxPaid;
        uint annualIncome;
    }

    mapping(address => TaxPayer) taxPayers;
    mapping(uint => address) taxPayersAddresses;
    uint taxPayerCount;

    modifier taxNotPaid {
        require(taxPayers[msg.sender].taxPaid==false);
        _;
    }

    constructor(address payable _address) public {
        owner=msg.sender;
        taxPayerCount=0;
        bracketCount=0;
        centralAuthorityAddress=_address;
    }

    function() payable external {}

    function addTaxPayer(string memory _name, address _address, uint _annualIncome) public officialOnly {
        taxPayers[_address]=TaxPayer(taxPayerCount, _name, false, _annualIncome);
        taxPayersAddresses[taxPayerCount]=_address;
        ++taxPayerCount;
    }

    function addTaxBracket(uint _lowerLimit, uint _upperLimit, uint _percentage) public officialOnly {
        taxBrackets[bracketCount]=TaxBracket(bracketCount, _lowerLimit, _upperLimit, _percentage, true);
        ++bracketCount;
    }

    function updateLowerLimitOfBracket(uint _code, uint _newLimit) public officialOnly {
        taxBrackets[_code].lowerLimit=_newLimit;
    }

    function updateUpperLimitOfBracket(uint _code, uint _newLimit) public officialOnly {
        taxBrackets[_code].upperLimit=_newLimit;
    }

    function updateTaxPercentageOfBracket(uint _code, uint _newPercentage) public officialOnly {
        taxBrackets[_code].percentage=_newPercentage;
    }

    function disableTaxBracket(uint _code) public officialOnly {
        taxBrackets[_code].validity=false;
    }

    function enableTaxBracket(uint _code) public officialOnly {
        taxBrackets[_code].validity=true;
    }

    function calculateTax() public view returns (uint) {
        if(taxPayers[msg.sender].taxPaid==true)
            return 0;
        uint _income=taxPayers[msg.sender].annualIncome;
        uint _tax=0;
        for(uint _i=0; _i<bracketCount; ++_i) {
            if(taxBrackets[_i].validity==true) {
                if(taxBrackets[_i].lowerLimit<_income) { // gotta do this as taxBrackets is stored as a mapping and it may not be in sorted order; find some way to sort the mapping in solidity efficiently
                    if(taxBrackets[_i].upperLimit>=_income) {
                        _tax+=taxBrackets[_i].percentage*(_income-taxBrackets[_i].lowerLimit)/100;
                    }
                    else {
                        _tax+=taxBrackets[_i].percentage*(taxBrackets[_i].upperLimit-taxBrackets[_i].lowerLimit)/100;
                    }
                }
            }
        }
        return _tax;
    }

    function payTax() public taxNotPaid payable {
        taxPayers[msg.sender].taxPaid=true;
        // call event;
    }

    function resetTaxPayments() public officialOnly { // will be scheduled somehow to yearly reset Tax Cycle
        for(uint _i=0; _i<taxPayerCount; ++_i) {
            taxPayers[taxPayersAddresses[_i]].taxPaid=false;
        }
    }

    function hasPaidTax(address _address) public view returns (bool) { // solidity cannot return arrays of complex structures, to get a list we have to call for each individual
        return taxPayers[_address].taxPaid;
    }

    function grantFundsToCentralAuthority(uint _amount) public ownerOnly {
        centralAuthorityAddress.transfer(_amount); 
        // call event;
    }

    function getTaxBracket(uint _code) public view returns (uint, uint, uint, uint, bool) {
        return (taxBrackets[_code].code, taxBrackets[_code].lowerLimit, taxBrackets[_code].upperLimit, taxBrackets[_code].percentage, taxBrackets[_code].validity);
    }

    function getTotalTaxBrackets() public view returns (uint) {
        return bracketCount;
    }

    function getTaxPayerWithAddress(address _address) public view returns (uint, string memory, bool, uint) {
        return (taxPayers[_address].id, taxPayers[_address].name, taxPayers[_address].taxPaid, taxPayers[_address].annualIncome);
    }

    function getTaxPayerWithID(uint _id) public view returns (uint, string memory, bool, uint) {
        return getTaxPayerWithAddress(taxPayersAddresses[_id]);
    }

    function getTotalTaxPayers() public view returns (uint) {
        return taxPayerCount;
    }
}