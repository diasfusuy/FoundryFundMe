// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
// import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "./mocks/MockV3Aggregator.sol";
contract FundMeTest is Test {
  FundMe fundMe;

  address USER = makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;
  uint8 constant DECIMALS = 8;
  int256 constant INITIAL_PRICE = 2000e8;

  MockV3Aggregator mockPriceFeed;

  function setUp() external {
    mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    fundMe = new FundMe(address(mockPriceFeed));
    vm.deal(USER, STARTING_BALANCE);
  }

  function testMinimunDollarIsFive() public {
    assertEq (fundMe.MINIMUM_USD(), 5e18);
  }

  function testOwnerIsMsgSender() public {
    assertEq(fundMe.getOwner(), address(this));
  }

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

  function testAddsFunderToArrayOfFunders() public {
    vm.prank(USER);
    fundMe.fund {value: SEND_VALUE}();

    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
  }
 
  modifier funded() {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    _;
  }

  function testOnlyOwnerCnaWithdraw() public funded {
    vm.prank(USER);
    vm.expectRevert();
    fundMe.withdraw();
  } 

  function testWithdrawWithASingleFunder() public funded {
    // Arrange
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();

    // Assert
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    uint256 endingFndMeBalance = address(fundMe).balance;
    assertEq(endingFndMeBalance, 0);
    assertEq(
      startingFundMeBalance + startingOwnerBalance,
      endingOwnerBalance
    );
  }

  function testWithdrawFromMultipleFunders() public funded {
    uint160 numberOfFudnders = 10;
    uint160 startingFunderIndex = 1;
    for(uint160 i = startingFunderIndex; i < numberOfFudnders; i++) {
      // vm.prank new address
      //v.default new address
      hoax(address(i), SEND_VALUE); // hoax is used to combine vm.prank and vm.deal
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    assert(address(fundMe).balance == 0);
    assert(
      startingFundMeBalance + startingOwnerBalance ==
      fundMe.getOwner().balance
    );
  }

  receive() external payable {}
}

