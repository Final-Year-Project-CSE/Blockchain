pragma solidity ^0.5.16;

contract Official {

    address owner;
    
    mapping(address => bool) officials;
    uint total_officals;

    modifier officialOnly {
        require(officials[msg.sender]==true);
        _;
    }

    modifier ownerOnly {
        require(msg.sender==owner);
        _;
    }

    constructor() public {
        owner=msg.sender;
        total_officals=0;
        addOfficial(owner);
    }

    function addOfficial(address _add) public officialOnly{
        officials[_add]=true;
        total_officals++;
    }
}

contract

contract Project is Official{

    struct Grant_Request{
        string subject;
        string document_url;
        uint weiRequested;
        address project; // we must only need the address of the project for which the grant is requested, because the requester will obviously have to be an official in charge of that project (we will also make sure that a grant is requested only when a certain percentage of officials in charge of that project have voted for the request to be initiated, that has to be a part of Project contract)
        bool isAccepted; // true means grant has been sanctioned, and money has already been transfered to the corresponding project, false does not mean it is rejected, it may mean that it has not been reviewed yet, so we need to have a different variable to see if it is pending or has been reviewed
        bool isPending; // will be true initially, set to true when isAccepted is either set to true or false
        bool isOpen; // after the request is granted it needs to be closed
        uint totalVotes;
        uint positiveVotes;
        mapping(address=>bool) voted_officials;
        bool ownerApproved;
    }
    
    string Project_name;
    string document_url;
    string purpose;
    address parent_project;
    // need to find out a way to store the current progress status of the project, is it on time, behind schedule, how much work is done, etc.
    address[] deployedProjects;
    Central_Authority fatherbranch;

    Grant_Request[] grantRequestsQueue;

    //I cannot pass struct as an argument in the functions or constructors in cross contract calls
    constructor(string memory _Project_name,
            string memory _document_url,
            string memory _purpose,
            address _official_incharge,
            Central_Authority _father,
            address _parent_project) public{
        owner = _official_incharge;
        parent_project = _parent_project;
        Project_name = _Project_name;
        document_url = _document_url;
        purpose = _purpose;
        fatherbranch = _father;
    }

    function() payable external {}

    function getAddress() public view returns (address) {
        return this.address;
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
    
    function addNewSubProjectRequest(string memory _projectName,string memory _purpose,string memory _url) public ownerOnly {
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
    
    function requestGrant(string memory _subject,string memory _document_url,uint _weiAmountRequested) public ownerOnly returns (string, int) {
        return Project(parent_project).handleGrantRequest(_subject, _document_url, _weiAmountRequested); // gotta make sure the instance parent project created here is not permanently stored on blockchain, it has to be just a storage pointer to the already deployed project and should be removed from memory when this function is returned
    }

    function checkRequestStatus(uint _requestID) public returns (bool, bool) {
        return Project(parent_project).grantApprovalCheck(_requestID);
    }

    function handleGrantRequest(string memory _subject,string memory _document_url, uint _weiAmountRequested) external returns (string, int) {

        // check if the requesting project is a sub project
        uint n = deployedProjects.length;
        for(uint i=0; i<n; ++i){
            if(deployedProjects[i]==msg.sender) {
                grantRequestsQueue.push( Grant_Request ({
                    subject: _subject,
                    document_url: _document_url,
                    weiRequested: _weiAmountRequested,
                    project: msg.sender,
                    isAccepted: false,
                    isPending: true,
                    isOpen: true,
                    totalVotes: 0,
                    positiveVotes: 0,
                    ownerApproved: false
                }));
                return ("Request Added", grantRequestsQueue.length-1);
            }
        }
        return ("Request Inapplicable", -1);
    }

    function grantApprovalCheck(uint _index) external view returns (bool, bool) { // a function to be called by a sub project to check status of request thats why external
        Grant_Request storage request = grantRequestsQueue[_index];
        return (request.isPending, request.isAccepted);
    }

    function haveSufficientFunds(uint _weiAmount) private returns (bool) {
        if(this.balance > (2 ether + _weiAmount)) { // 2 ether is added to maintain a minimum balance in contract to perform other necessary operations, amount can be changed as required
            return true;
        } return false;
    }

    function grantFunds(address _projectAddress, uint _weiRequested) private {
        _projectAddress.transfer(_weiRequested);
    }

    function voteForGrant(uint _index,bool _decision) public officialOnly {
        Grant_Request storage request = grantRequestsQueue[_index];
        
        require(!request.voted_officials[msg.sender]);
        
        request.voted_officials[msg.sender]=true;
        request.totalVotes++;
        if(decision)
            request.positiveVotes++;

        // vote from the head of the project is a must in addition to the voting limit to be met
        if(msg.sender==owner)
            request.ownerApproved=true;

        if(request.ownerApproved==true && request.positiveVotes > 0.7*total_officals)
        {
            request.isPending=false;
            request.isAccepted=true;
        } else if (request.totalVotes - request.positiveVotes >= 0.3*total_officals) {
            request.isPending=false;
            request.isAccepted=false;
        }
    }
    
    function initiatePeriodicDistribution() public ownerOnly {

        // for now the distribution rule is that the older requests are given higher priority
        // each project is given at max a limited ether (which can be decided) so that all funds are not assigned to a single project

        uint maxFunds = 2 ether; // will be assigned value in wei not ether
        uint weiToBeGranted;

        uint n = grantRequestsQueue.length;
        for(uint i = 0; i<n; ++i) {
            Grant_Request storage request = grantRequestsQueue[i];
            if(request.isOpen && request.isAccepted) {
                weiToBeGranted = request.weiRequested<maxFunds ? request.weiRequested : maxFunds;
                if(haveSufficientFunds(weiToBeGranted)) {
                    grantFunds(request.project, weiToBeGranted);
                    // emit an event to notify the project that it has been granted funds. the event can be somehow used in the front end to generate some email notification
                    request.weiRequested = request.weiRequested - weiToBeGranted;
                    if(request.weiRequested==0) // if all requested funds granted, close request
                        request.isOpen=false;
                }
                else // if funds were not enough for this request, we obviously dont have sufficient funds for further requests too as requests after this are relatively newer and are most probably having wei demands even higher therefore no point of checking further
                    break;
            }
        }
    }

}

contract Central_Authority is Official{

    // not only central but central authority also needs money so as to provide gas for its operations tax collection has to grant funds to central authority too

    struct Project_Request{
        string Project_name;
        string document_url;
        string purpose;
        address official_incharge;
        address parent_project;
        bool isComplete;
        uint voters;//this will keep count of positive vote count only
        mapping(address=>bool) voted_officials;
    }
    
    Project public central;

    TaxCollection taxCollection;

    function createProject(Project_Request memory _request) private returns (Project ) {
        Project newProject = new Project(_request.Project_name,_request.document_url,_request.purpose,_request.official_incharge,this,_request.parent_project);
        return newProject;
    }

    Project_Request[] requestedProjects;
    
    constructor() public {
        Project_Request memory request = Project_Request({
            Project_name:"Central_Authority",
            document_url:"",
            purpose:'',
            official_incharge:owner,
            parent_project:owner,
            isComplete:true,
            voters:0
        });
        central = createProject(request);
        taxCollection = new TaxCollection(owner, central.getAddress());
    }
    
    
    function addNewProjectRequest(string memory _Project_name,string memory _document_url,string memory _purpose, address _official_incharge,address _parent_project) public returns (string memory) {
        //In this function we will make the struct of current request and add that to the list of requestedProjects[]
        Project_Request memory new_request = Project_Request({
            Project_name:_Project_name,
            document_url:_document_url,
            purpose:_purpose,
            official_incharge:_official_incharge,
            parent_project:_parent_project, // why not use msg.sender? (probable reason:-maybe msg.sender=contract address but that actually sounds fine, will help identify the parent project of the sub project)
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

}

contract TaxCollection is Official{

    address centralProjectAddress;

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

    constructor(address _owner, address _centralProjectAddress) public {
        owner=_owner;
        taxPayerCount=0;
        bracketCount=0;
        centralProjectAddress=_centralProjectAddress;
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

    function grantFundsToCentralProject(uint _amount) public ownerOnly {
        centralProjectAddress.transfer(_amount); 
        // call event;
    }

}
