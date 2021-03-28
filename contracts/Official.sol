pragma solidity ^0.5.16;

contract Official {

    address public owner;
    
    mapping(address => bool) officials;
    uint public total_officals;

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
        officials[owner]=true;
        total_officals=1;
    }

    function addOfficial(address _add) public officialOnly {
        if(officials[_add]==true) // Already an official
            return;
        officials[_add]=true;
        total_officals++;
    }

    function removeOfficial(address _add) public officialOnly {
        if(officials[_add]==true) {
            officials[_add]=false;
            total_officals--;
        }
    }

    function getBalance() public view returns (uint) { // did not return balance during testing
        return address(this).balance;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }
}