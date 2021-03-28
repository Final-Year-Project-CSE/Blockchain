pragma solidity ^0.5.16;

import "./Official.sol";
import "./Central_Authority.sol";

contract Project is Official{

    struct Grant_Request{
        string subject;
        string document_url;
        uint weiRequested;
        address payable project; // we must only need the address of the project for which the grant is requested, because the requester will obviously have to be an official in charge of that project (we will also make sure that a grant is requested only when a certain percentage of officials in charge of that project have voted for the request to be initiated, that has to be a part of Project contract)
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
    address payable parent_project;
    // need to find out a way to store the current progress status of the project, is it on time, behind schedule, how much work is done, etc.
    mapping(uint=>address) public subProjectAddress;//mapping from token to project if created, not possible to traverse this without creating a different array to store tokens in order
    uint[] tokenNoForSubProject;
    address payable fatherbranch;

    Grant_Request[] grantRequestsQueue;

    //I cannot pass struct as an argument in the functions or constructors in cross contract calls
    constructor(string memory _Project_name,
            string memory _document_url,
            string memory _purpose,
            address _official_incharge,
            address payable _father,
            address payable _parent_project) public
            {
        owner = _official_incharge;
        parent_project = _parent_project;
        Project_name = _Project_name;
        document_url = _document_url;
        purpose = _purpose;
        fatherbranch = _father;
    }

    function() payable external {}

    function getProjectInfo() public view returns (string memory, string memory, string memory, address, address) {
        return (Project_name, document_url, purpose, parent_project, fatherbranch);
    }
    
    // string public verification_result; // what purpose does it solve?
    // verification result is the output that has to be returned to the official on the front end, need not be saved on the blockchain
    
    function verifyPending_Projects(uint token_no) public returns (string memory) { // as we wont be able to return a list, we can consider having an input of request ID, so that we can get the result for a particular request
        //this will call the Central_Authority project evalution function and 
        //that function will check if the officials of Central_Authority has passed its sub-project or not
        //if the project has been passed then list of projects is receieved and it is added to the deployedProjects[]

        bool isDeployed;
        address payable projectAddress;

        (isDeployed, projectAddress) = Central_Authority(fatherbranch).verifyPending_Projects(token_no);

        if(isDeployed) {
            subProjectAddress[token_no] = projectAddress;
            tokenNoForSubProject.push(token_no);
            return "New Project Added";
        } else {
            return "No New Project added";
        }
    }
    
    
    function addNewSubProjectRequest(string memory _projectName,string memory _purpose,string memory _url) public ownerOnly returns (uint){
        //In this function we will check that only Officials can make request and all the data is valid
        // we will pass data to addNewProjectRequest function of Central_Authority contract
        bytes memory strBytes = bytes(_projectName);
        require(strBytes.length != 0);
        strBytes = bytes(_purpose);
        require(strBytes.length != 0);
        strBytes = bytes(_url);
        require(strBytes.length != 0);
        
        return Central_Authority(fatherbranch).addNewProjectRequest(_projectName,_url,_purpose,msg.sender);
        //returning the token no.
    }
    
    function requestGrant(string memory _subject,string memory _document_url,uint _weiAmountRequested) public ownerOnly returns (string memory, int) {
        return Project(parent_project).handleGrantRequest(_subject, _document_url, _weiAmountRequested); // gotta make sure the instance parent project created here is not permanently stored on blockchain, it has to be just a storage pointer to the already deployed project and should be removed from memory when this function is returned
    }

    function checkRequestStatus(uint _requestID) public view returns (bool, bool) {
        return Project(parent_project).grantApprovalCheck(_requestID);
    }

    function handleGrantRequest(string memory _subject,string memory _document_url, uint _weiAmountRequested) public returns (string memory, int) {

        // check if the requesting project is a sub project
        uint n = tokenNoForSubProject.length;
        for(uint i=0; i<n; ++i){
            if(subProjectAddress[tokenNoForSubProject[i]]==msg.sender) {
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
                return ("Request Added", int(grantRequestsQueue.length-1));
            }
        }
        return ("Request Inapplicable", -1);
    }

    function grantApprovalCheck(uint _index) external view returns (bool, bool) { // a function to be called by a sub project to check status of request thats why external
        Grant_Request storage request = grantRequestsQueue[_index];
        return (request.isPending, request.isAccepted);
    }

    function haveSufficientFunds(uint _weiAmount) private view returns (bool) {
        if(address(this).balance > (2 ether + _weiAmount)) { // 2 ether is added to maintain a minimum balance in contract to perform other necessary operations, amount can be changed as required
            return true;
        } return false;
    }

    function grantFunds(address payable _projectAddress, uint _weiRequested) private {
        _projectAddress.transfer(_weiRequested);
    }

    function voteForGrant(uint _index,bool _decision) public officialOnly {
        Grant_Request storage request = grantRequestsQueue[_index];
        
        require(!request.voted_officials[msg.sender]);
        
        request.voted_officials[msg.sender]=true;
        request.totalVotes++;
        if(_decision)
            request.positiveVotes++;

        // vote from the head of the project is a must in addition to the voting limit to be met
        if(msg.sender==owner)
            request.ownerApproved=true;

        if(request.ownerApproved==true && request.positiveVotes > (7*total_officals)/10)
        {
            request.isPending=false;
            request.isAccepted=true;
        } else if (request.totalVotes - request.positiveVotes >= (3*total_officals)/10) {
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