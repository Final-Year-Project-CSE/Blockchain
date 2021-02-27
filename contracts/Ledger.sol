pragma solidity ^0.5.16;

contract Official {

    address owner=msg.sender;
    
    mapping(address => bool) officials;
    uint total_officals;

    modifier officialOnly {
        require(officials[msg.sender]==true);
        _;
    }

    constructor() public {
        total_officals=0;
        addOfficial(owner);
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
    struct Grant_Request{
        string subject;
        string document_url;
        address project; // we must only need the address of the project for which the grant is requested, because the requester will obviously have to be an official in charge of that project (we will also make sure that a grant is requested only when a certain percentage of officials in charge of that project have voted for the request to be initiated, that has to be a part of Project contract)
        bool isAccepted; // true means grant has been sanctioned, and money has already been transfered to the corresponding project, false does not mean it is rejected, it may mean that it has not been reviewed yet, so we need to have a different variable to see if it is pending or has been reviewed
        bool isPending; // will be true initially, set to true when isAccepted is either set to true or false
        uint voters;//this will keep count of positive vote count only
        mapping(address=>bool) voted_officials;
    }
}

contract Project is Official{
    
    string Project_name;
    string document_url;
    string purpose;
    // need to find out a way to store the current progress status of the project, is it on time, behind schedule, how much work is done, etc.
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
    
    // string public verification_result; // what purpose does it solve?
    // verification result is the output that has to be returned to the official on the front end, need not be saved on the blockchain
    
    function verifyPending_Projects() public returns (string memory) { // as we wont be able to return a list, we can consider having an input of request ID, so that we can get the result for a particular request
        //this will call the Central_Authority project evalution function and 
        //that function will check if the officials of Central_Authority has passed its sub-project or not
        //if the project has been passed then list of projects is receieved and it is added to the deployedProjects[]
        
        string memory verification_result; // we can actually just return a string directly without saving it in any variable.

        Project  data = fatherbranch.verifyPending_Projects(msg.sender); // why do we explicitly need to pass msg.sender? 
        Project empty; // are we sure this wont waste memory? and are we sure the new project contract created and returned will persist?
        if(data == empty){
            verification_result = "No New Project added";
        }
        else{
            deployedProjects.push(address(data));
            verification_result = "New Project Added";
        }
        return verification_result;

        //if we have the list of requested projects for this project then we can check the request status of each project
    }
    
    function addNewSubProjectRequest(string memory _projectName,string memory _purpose,string memory _url) public officialOnly{
        //In this function we will check that only Officials can make request and all the data is valid
        // we will pass data to addNewProjectRequest function of Central_Authority contract
        bytes memory strBytes = bytes(_projectName);
        require(strBytes.length != 0);
        strBytes = bytes(_purpose);
        require(strBytes.length != 0);
        strBytes = bytes(_url);
        require(strBytes.length != 0);
        
        fatherbranch.addNewProjectRequest(_projectName,_url,_purpose,msg.sender);
        
    }
    
    function requestGrant(string memory _subject,string memory _document_url) public {
        require(msg.sender == owner);
        fatherbranch.requestGrant(_subject,_document_url,this);
    }
    
}

contract Central_Authority is Official{ // central authority has no direct access to the list of projects
    
    Project public central; // do we need this? it aint used anywhere. or maybe central can somehow include taxation
    function createProject(Project_Request memory _request) private returns (Project ){ // is it possible to create contracts like this?
        Project newProject = new Project(_request.Project_name,_request.document_url,_request.purpose,_request.requester,this);
        return newProject;
    }

    Project_Request[] requestedProjects;
    Grant_Request[] requestQueue;
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
    
    
    function addNewProjectRequest(string memory _Project_name,string memory _document_url,string memory _purpose, address _requester) public returns (string memory) {
        //In this function we will make the struct of current request and add that to the list of requestedProjects[]
        Project_Request memory new_request = Project_Request({
            Project_name:_Project_name,
            document_url:_document_url,
            purpose:_purpose,
            requester:_requester, // why not use msg.sender? (probable reason:-maybe msg.sender=contract address but that actually sounds fine, will help identify the parent project of the sub project)
            isComplete:false,
            voters:0
        });
        
        string memory res="";
        
        uint n = requestedProjects.length;
        for(uint i=0;i<n;i++){
            if(requestedProjects[i].requester == msg.sender){ // if this official has an already incomplete project request, first that has to be completed
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
    
    function voteForProject(uint _index,bool _decision) public officialOnly {
        Project_Request storage request = requestedProjects[index];
        
        require(!request.voted_officials[msg.sender]);//the person has not voted so far
        
        request.voted_officials[msg.sender]=true;
        if(decision)
            request.voters++;
        
    }
    
    function verifyPending_Projects(address _curr_person) public returns(Project){ // who is curr_person? why didnt you use msg.sender
        
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
    
    function requestGrant(string memory _subject,string memory _document_url,Project _requester) public{
        
        
        
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
        // check who pays wei here
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
        // check who pays wei here
        // call event;
    }

}
