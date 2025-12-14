// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
contract FundMeTest is Test {
  FundMe fundMe;

  address USER = makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;
  function setUp() external{
    // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.deployForTest();
    vm.deal(USER, STARTING_BALANCE);
  }

  function testMinimunDollarIsFive() public {
    assertEq (fundMe.MINIMUM_USD(), 5e18);
  }

  // function testOwnerIsMsgSender() public {
  //   assertEq(fundMe.i_owner(), address(this));
  // }

// What can we do to work with addresses outside our system?
// 1. Unit 
//    - Testing a specific part of our code
// 2. Integration
//    - Testing how our code works with other parts of our code
// 3. Forked
//    - Testing our code on a simulated real environment
// 4. Staging
//    - Testing our code in real environment that is not prod 

  function testPriceFeedVersionIsAccurate() public {
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
  }

  function testFundFailsWithoutEnoughEth() public {
    vm.expectRevert(); // next line should revert
    // assert(this tx fails/reverts)
    fundMe.fund();
  }
  
  function testFundUpdatedDataStructure() public {
   vm.prank(USER);
   fundMe.fund {value: SEND_VALUE}();

   uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
   assertEq(amountFunded, SEND_VALUE);
  }

  
}

