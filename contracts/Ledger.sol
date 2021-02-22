pragma solidity ^0.5.16;

contract Official {

    address owner=msg.sender;

    mapping(address => bool) officials;

    modifier officialOnly {
        require(officials[msg.sender]==true || msg.sender==owner);
        _;
    }

    function addOfficial(address _add) public officialOnly{
        officials[_add]=true;
    }

}

contract TaxCollection is Official{

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

    constructor() public {
        taxPayerCount=0;
        bracketCount=0;
    }

    function getBudgetBalance() public view returns (uint) {
        return address(this).balance;
    }

    function() payable external {} // so that other accounts can send ether to the account of this smart contract

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
                if(taxBrackets[_i].lowerLimit>_income) { // gotta do this as taxBrackets is stored as a mapping and it may not be in sorted order; find some way to sort the mapping in solidity efficiently
                    if(taxBrackets[_i].upperLimit<=_income) {
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
        address(this).transfer(calculateTax()); // asynchronous; next statement should only execute once this has returned, make sure of that afterwards
        taxPayers[msg.sender].taxPaid=true;
        // call event;
    }

    function resetTaxPayments() public officialOnly { // will be scheduled somehow to yearly reset Tax Cycle
        for(uint _i=0; _i<taxPayerCount; ++_i) {
            taxPayers[taxPayersAddresses[_i]].taxPaid=false;
        }
    }

    function hasPaidTax(uint _id) public view returns (bool) { // solidity cannot return arrays of complex structures, to get a list we have to call for each individual
        return taxPayers[taxPayersAddresses[_id]].taxPaid;
    }

    function grantFunds(address payable _schemeContractAddress, uint _amount) public officialOnly {
        _schemeContractAddress.transfer(_amount); // not correct, make sure money is transferred from the contract account, not from the account of the official calling this function
        // call event;
    }

contract RationScheme is Official{

    struct Item {
        uint code;
        string name;
        uint pricePerUnit;
    }

    mapping(uint => Item) items;
    uint itemCount;

    struct Beneficiary {
        bool exists;
        uint id;
        string name;
        address benfAddress;
        mapping(uint => uint) itemUnitsConsumed; // mapping from item code to units of item consumed;
    }

    mapping(uint => Beneficiary) beneficiaries;
    mapping(address => uint) beneficiariesByAddress;
    uint benfCount;

    modifier BeneficiaryOnly {
        require(beneficiaries[beneficiariesByAddress[msg.sender]].exists);
        _;   
    }

    struct Agent {
        uint id;
        string name;
        uint areaCode;
        string area;
        // other factors
        address wallet;
        /* keep track of items distributed too
        {
            units in stock
            units distributed
            bare minimum required
            when stock falls down below bare minimum, buy more units using balance in wallet..


            // come up with an idea to fill stock using ether in wallet
        }
        */
        uint fundsGranted;
        uint fundsUsed;
    }

    mapping(uint => Agent) agents;
    uint agentCount;

    constructor() public {
        benfCount=0;
        agentCount=0;
        itemCount=0;
    }

    function getSchemeFundsBalance() public view returns (uint) {
        return address(this).balance;;
    }

    function() payable {} // so that other accounts can send ether to the account of this smart contract

    function addItem(string _itemName, uint _unitPrice) public {
        items[itemCount]=Item(itemCount, _itemName, _unitPrice);
        for(uint _i=0; _i<benfCount; _i++) {
            beneficiaries[_i].itemUnitsConsumed[itemCount]=0;
        }
        ++itemCount;
    }

    function addBeneficiary(string _name, address _address) {
        beneficiaries[benfCount].exists=true;
        beneficiaries[benfCount].id=benfCount;
        beneficiaries[benfCount].name=_name;
        beneficiaries[benfCount].benfAddress=_address;
        for(uint _i=0; _i<itemCount; _i++) {
            beneficiaries[benfCount].itemUnitsConsumed[_i]=0; // initially no units consumed
        }
        beneficiariesByAddress[_address]=benfCount;
        ++benfCount;
    }

    function addAgent() {
        //figure out all parameters
    }

    function grantFundsToAgent(uint _agentID, uint _amount) public /* payable */ officialOnly {

        // before alloting further funds, check for prior transactions of the agent, check if distribution was fairly done 

        agents[_agentID].wallet.transfer(_amount);
        agents[_agentID].fundsGranted+=_amount;
    }

    function getRation() public BeneficiaryOnly{
        // we want a list of item codes with quantity
        // figure out a generic way to do that

        // then for each item code
        // beneficiaries[beneficiariesByAddress[msg.sender]].itemUnitsConsumed[code]+=quantity
    }

    function stockUpItem(uint _itemCode, uint _quantity) { // modifier by agent
        uint _totalAmount = items[_itemCode].pricePerUnit*_quantity;
        // access agents by address too

        //required that fundsGranted-fundsUsed>=_totalAmount
        // fundsUsed+=_totalAmount

        // stock[_itemCode]+=_quantity
    }
    // check every time amount of funds is equal to food amount distributed, if not terminate agent rights
    // agent cancelled, will not recieve any more funds.
}


// normal variable name => state variable; starting from underscore => local variable
// web3, web3.eth


/* Arrays
type[] name;
name.push(value);
*/