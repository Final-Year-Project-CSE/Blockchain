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

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}