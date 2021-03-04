pragma solidity ^0.5.16;

import "./Official.sol";
import "./Project.sol";
import "./TaxCollection.sol";

contract Central_Authority is Official{

    struct Project_Request{
        string Project_name;
        string document_url;
        string purpose;
        address official_incharge;
        address payable parent_project;
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

    mapping(uint => Project_Request) requestedProjects;//mapping from token to project address 
    mapping(uint => address) public deployedProjectsAddresses; // may become costly otherwise, shouldnt overload blockchain
    uint token;

    constructor() public {
        Project_Request memory request = Project_Request({
            Project_name:"Central_Authority",
            document_url:"",
            purpose:'',
            official_incharge:owner,
            parent_project:address(this), // had to be a payable address
            isComplete:true,
            voters:0
        });
        token = 1;
        central = createProject(request);
        taxCollection = new TaxCollection(owner, address(this));
    }
    
    function() external payable {}
    
    function addNewProjectRequest(string memory _Project_name,string memory _document_url,string memory _purpose, address _official_incharge) public returns (uint) {
        //In this function we will make the struct of current request and add that to the list of requestedProjects[]
        
        Project_Request memory new_request = Project_Request({
            Project_name:_Project_name,
            document_url:_document_url,
            purpose:_purpose,
            official_incharge:_official_incharge,
            parent_project:msg.sender,
            isComplete:false,
            voters:0
        });

        requestedProjects[token] = new_request;
        token++;
        return token-1;
    }

    //here index reassemble token
    function voteForProject(uint _index,bool _decision) public officialOnly {
        Project_Request storage request = requestedProjects[_index];
        
        require(!request.voted_officials[msg.sender]);//the person has not voted so far
        
        request.voted_officials[msg.sender]=true;
        if(_decision)
            request.voters++;
    }
    
    function verifyPending_Projects(uint _token) public returns(Project){

        require(_token>=1 && _token<token); // checking token validity
        
        Project newProject;
        // uint n = requestedProjects.length;
        Project_Request storage current_req = requestedProjects[_token];
        //if value for some key doesn't exist the mapping will return the default value of that data type
        //as I have custom mapping so need to following below method
        // Project_Request memory cmp;
        // require(current_req != cmp);//case for invalid token

        require(current_req.parent_project == msg.sender);

        if(current_req.voters >= total_officals && !current_req.isComplete){ //currently it requires all of the officials to vote in favour
            
            newProject = createProject(current_req);
            
            current_req.isComplete = true;

            deployedProjectsAddresses[_token] = address(newProject);
        }
        
        return newProject;
    }

    function grantFundsToCentralProject(uint _amount) public ownerOnly {
        address(central).transfer(_amount); 
        // call event;
    }
}