pragma solidity ^0.5.16;

contract Official {

    address owner=msg.sender;
    
    mapping(address => bool) officials;
    uint total_officals;
    modifier officialOnly {
        require(officials[msg.sender]==true || msg.sender==owner);
        _;
    }

    function addOfficial(address _add) public officialOnly{
        officials[_add]=true;
        total_officals++;
    }
    struct Project_Request{
        string Project_name;
        string document_url;
        string purpose;
        address requester;
        bool isComplete;
        uint voters;//this will keep count of positive vote count only
        mapping(address=>bool) voted_officials;
    }
    struct Money_Request{
        string subject;
        string document_url;
        address requester;
        bool isComplete;
        uint voters;//this will keep count of positive vote count only
        mapping(address=>bool) voted_officials;
    }
}

contract Project is Official{
    
    string Project_name;
    string document_url;
    string purpose;
    address[] deployedProjects;
    Central_Authority fatherbranch;
    //I cannot pass struct as an argument in the functions or constructors in cross contract calls
    constructor(string memory _Project_name,string memory _document_url,string memory _purpose,address _requester,Central_Authority _father) public{
        owner = _requester;
        Project_name = _Project_name;
        document_url = _document_url;
        purpose = _purpose;
        fatherbranch = _father;
    }
    
    
    function getDeployedProjects() public view returns (address[] memory){
        return deployedProjects;
    }
    
    string public verification_result;
    
    function verifyPending_Projects() public returns (string memory){
        //this will call the Central_Authority project evalution function and 
        //that function will check if the officials of Central_Authority has passed the project or not
        //if the project is been passed then list of projects is receieved and it is added to the deployedProjects[]
        Project  data = fatherbranch.verifyPending_Projects(msg.sender);
        Project empty;
        if(data == empty){
            verification_result = "No New Project added";
        }
        else{
            deployedProjects.push(address(data));
            verification_result = "new Project Added";
        }
        return verification_result;
    }
    
    function addNewProjectRequest(string memory _projectName,string memory _purpose,string memory _url) public{
        //In this function we will check that only Officials can make request and all the data is validity
        // we will pass data to addNewProjectRequest function of Central_Authority contract
        require(officials[msg.sender]);//check for Official
        bytes memory strBytes = bytes(_projectName);
        require(strBytes.length != 0);
        strBytes = bytes(_purpose);
        require(strBytes.length != 0);
        strBytes = bytes(_url);
        require(strBytes.length != 0);
        
        fatherbranch.addNewProjectRequest(_projectName,_url,_purpose,msg.sender);
        
    }
    
    function requestMoney(string memory _subject,string memory _document_url) public {
        require(msg.sender == owner);
        fatherbranch.requestMoney(_subject,_document_url,this);
    }
    
}

contract Central_Authority is Official{
    
    Project public central;
    function createProject(Project_Request memory _request) private returns (Project ){
        Project newProject = new Project(_request.Project_name,_request.document_url,_request.purpose,_request.requester,this);
        return newProject;
    }

    Project_Request[] requestedProjects;
    Money_Request[] requestQueue;
    constructor() public {
        Project_Request memory request = Project_Request({
            Project_name:"Central_Authority",
            document_url:"",
            purpose:'',
            requester:owner,
            isComplete:true,
            voters:0
        });
        central = createProject(request);
    }
    
    
    function addNewProjectRequest(string memory _Project_name,string memory _document_url,string memory _purpose,address _requester) public returns (string memory){
        //In this function we will make the struct of current request and add that to the list of requestedProjects[]
        Project_Request memory new_request = Project_Request({
            Project_name:_Project_name,
            document_url:_document_url,
            purpose:_purpose,
            requester:_requester,
            isComplete:false,
            voters:0
        });
        
        string memory res="";
        
        uint n = requestedProjects.length;
        for(uint i=0;i<n;i++){
            if(requestedProjects[i].requester == _requester){
                if(!requestedProjects[i].isComplete){
                    res = "There is already a request Added";
                    return res;
                }
            }
        }
        requestedProjects.push(new_request);
        res = "Request Added";
        return res;
    }
    
    function voteForProject(uint index,bool decision) public{
        require(officials[msg.sender]);//current person is Official
        Project_Request storage request = requestedProjects[index];
        
        require(!request.voted_officials[msg.sender]);//the person has not voted so far
        
        request.voted_officials[msg.sender]=true;
        if(decision)
            request.voters++;
        
    }
    
    function verifyPending_Projects(address curr_person) public returns(Project){
        
        Project newProject;
        uint n = requestedProjects.length;
        for(uint i=0;i<n;i++){
            if(requestedProjects[i].requester == curr_person){
                if(requestedProjects[i].voters >= total_officals && !requestedProjects[i].isComplete){
                    
                    newProject = createProject(requestedProjects[i]);
                    
                    requestedProjects[i].isComplete = true;
                }
            }
        }
        
        return newProject;
    }
    
    function requestMoney(string memory _subject,string memory _document_url,Project _requester) public{
        
        
        
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

}
