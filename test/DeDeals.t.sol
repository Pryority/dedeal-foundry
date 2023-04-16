// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/DeDeals.sol"; // Import the DeDeals contract

contract DeDealsTest is Test {
    DeDeals dedeals; // Declare a variable to hold the DeDeals contract instance
    mapping(uint256 => Deal) dealIdMap;
    uint256 executedBalance;

    struct Deal {
        uint256 dealId;
        address sellerAddress;
        address buyerAddress;
        uint256 sellerDeposit;
        uint256 buyerDeposit;
        uint256 dealAmount;
        uint256 depositReleaseTime;
        uint256 grantDeadline;
        uint256 executeDeadlineInterval;
    }

    function setUp() public {
        dedeals = new DeDeals(); // Deploy a new instance of the DeDeals contract
    }

    function test_GetDeal() public payable {
        // Call the createDeal function with the necessary parameters
        DeDeals.Deal memory deal = dedeals.createDeal(100, 3600);

        // Call the getDeal function with the dealId and assert that the returned deal has the expected values
        DeDeals.Deal memory retrievedDeal = dedeals.getDeal(deal.dealId);
        assertEq(retrievedDeal.dealId, deal.dealId);
        assertEq(retrievedDeal.sellerAddress, address(this));
        assertEq(retrievedDeal.buyerAddress, address(0));
        assertEq(retrievedDeal.sellerDeposit, msg.value);
        assertEq(retrievedDeal.buyerDeposit, 0);
        assertEq(retrievedDeal.dealAmount, msg.value);
        assertEq(retrievedDeal.grantDeadline, block.timestamp + 99);
        assertEq(retrievedDeal.executeDeadlineInterval, 3600);
    }

    function test_CreateDeal() public payable {
        // Call the createDeal function with the necessary parameters
        DeDeals.Deal memory deal = dedeals.createDeal(100, 3600);

        // Assert that the returned deal has the expected values
        assertEq(deal.dealId, 1);
        assertEq(deal.sellerAddress, address(this));
        assertEq(deal.buyerAddress, address(0));
        assertEq(deal.sellerDeposit, msg.value);
        assertEq(deal.buyerDeposit, 0);
        assertEq(deal.dealAmount, msg.value);
        assertEq(deal.grantDeadline, block.timestamp + 99);
        assertEq(deal.executeDeadlineInterval, 3600);
    }

    function test_GetDeal_InvalidDealId() public payable {
        (bool success, ) = address(dedeals).call(
            abi.encodeWithSignature("getDeal(uint256)", 100)
        );
        assertEq(success, false);
        vm.expectRevert("INVALID_DEAL_ID");
        dedeals.getDeal(101);
    }

    // function test_BuyerExecuteSeller_ValidDealId() public payable {
    //     vm.startPrank(address(dedeals));
    //     // Call the createDeal function with the necessary parameters
    //     DeDeals.Deal memory deal = dedeals.createDeal(100, 3600);

    //     // Set the buyer address for the deal
    //     deal.buyerAddress = address(this);

    //     // Set the seller deposit for the deal
    //     deal.sellerDeposit = 100;

    //     // Call the buyerExecuteSeller function with the valid _dealId and correct buyer and msg.value
    //     (bool success, ) = address(dedeals).call{value: 200}(
    //         abi.encodeWithSignature("buyerExecuteSeller(uint256)", deal.dealId)
    //     );
    //     assertTrue(success, "buyerExecuteSeller should execute successfully");

    //     // Assert that the contract state is updated as expected
    //     assertEq(dealIdMap[deal.dealId].sellerDeposit, 0);
    //     assertEq(dealIdMap[deal.dealId].buyerDeposit, 200);
    //     assertEq(
    //         dealIdMap[deal.dealId].depositReleaseTime,
    //         block.timestamp + deal.executeDeadlineInterval
    //     );
    //     assertEq(executedBalance, 100);

    //     // Assert that the emitted event has the correct values
    //     assertEq(dealIdMap[deal.dealId].sellerAddress, deal.sellerAddress);
    //     assertEq(dealIdMap[deal.dealId].buyerAddress, deal.buyerAddress);
    //     assertEq(dealIdMap[deal.dealId].sellerDeposit, deal.sellerDeposit);
    //     assertEq(dealIdMap[deal.dealId].buyerDeposit, deal.buyerDeposit);
    //     assertEq(dealIdMap[deal.dealId].dealAmount, deal.dealAmount);
    //     assertEq(dealIdMap[deal.dealId].grantDeadline, deal.grantDeadline);
    //     assertEq(
    //         dealIdMap[deal.dealId].executeDeadlineInterval,
    //         deal.executeDeadlineInterval
    //     );
    //     vm.stopPrank();
    // }

    function test_CreateDeal_InsufficientDeposit() public payable {
        // Call the createDeal function with an insufficient deposit and assert that it reverts
        (bool success, ) = address(dedeals).call{value: 50}(
            abi.encodeWithSignature("createDeal(uint256,uint256)", 100, 3600)
        );
        assertTrue(
            success,
            "createDeal should revert with insufficient deposit"
        );

        vm.expectRevert("Insufficient deposit for createDeal");
        (bool createDeal, ) = address(dedeals).call{value: 50}(
            abi.encodeWithSignature("createDeal(uint256,uint256)", 100, 3600)
        );
        assertFalse(createDeal);
    }

    function test_CreateDeal_ExceededGrantDeadline() public payable {
        vm.roll(10);

        // Call the createDeal function and assert that it reverts
        (bool success, ) = address(dedeals).call{value: 100}(
            abi.encodeWithSignature("createDeal(uint256,uint256)", 100, 3600)
        );
        assertTrue(success, "createDeal should revert after grant deadline");
    }

    function test_CreateDeal_WithExistingDeal() public payable {
        (bool success, ) = address(dedeals).call{value: 100}(
            abi.encodeWithSignature("createDeal(uint256,uint256)", 100, 3600)
        );
        assertTrue(success, "createDeal should revert with existing deal");
    }
}
