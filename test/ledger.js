var Ledger = artifacts.require('./Ledger.sol')

contract("Project",(accounts)=>{
    
    it("addNewSubProjectRequest",()=>{
        return Ledger.deployed().then((instance)=>{
            return instance.addNewSubProjectRequest("Demo","Demo Purpose","demo.com");
        }).then((tokenNo)=>{
            assert.equal(tokenNo,1);
        })
    })

})