pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/BikeChain.sol";

contract TestBikeChain {
  BikeChain bc = BikeChain(DeployedAddresses.BikeChain());

  function testAddCompany(){
  uint returnedId = bc.addCompany(0, 0x0);

  uint expected = 1;

  Assert.equal(returnedId, expected, "cID of 1 should be recoreded.");
  }

}
