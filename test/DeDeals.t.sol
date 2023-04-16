// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/DeDeals.sol"; // Import the DeDeals contract

contract DeDealsTest is Test {
    DeDeals dedeals; // Declare a variable to hold the DeDeals contract instance

    function setUp() public {
        dedeals = new DeDeals(); // Deploy a new instance of the DeDeals contract
    }

    function test_GetDeal() public payable {
        // Call the claim function with the necessary parameters
        DeDeals.Deal memory deal = dedeals.claim(100, 3600);

        // Call the getDeal function with the dealId and assert that the returned deal has the expected values
        DeDeals.Deal memory retrievedDeal = dedeals.getDeal(deal.dealId);
        assertEq(retrievedDeal.dealId, deal.dealId);
        assertEq(retrievedDeal.sellerAddress, address(this));
        assertEq(retrievedDeal.buyerAddress, address(0));
        assertEq(retrievedDeal.sellerDeposit, msg.value);
        assertEq(retrievedDeal.buyerDeposit, 0);
        assertEq(retrievedDeal.amountOfClaim, msg.value);
        assertEq(retrievedDeal.grantDeadline, block.timestamp + 99);
        assertEq(retrievedDeal.executeDeadlineInterval, 3600);
    }

    function test_Claim() public payable {
        // Call the claim function with the necessary parameters
        DeDeals.Deal memory deal = dedeals.claim(100, 3600);

        // Assert that the returned deal has the expected values
        assertEq(deal.dealId, 1);
        assertEq(deal.sellerAddress, address(this));
        assertEq(deal.buyerAddress, address(0));
        assertEq(deal.sellerDeposit, msg.value);
        assertEq(deal.buyerDeposit, 0);
        assertEq(deal.amountOfClaim, msg.value);
        assertEq(deal.grantDeadline, block.timestamp + 99);
        assertEq(deal.executeDeadlineInterval, 3600);
    }

    function test_GetDeal_InvalidDealId() public payable {
        (bool success,) = address(dedeals).call(abi.encodeWithSignature("getDeal(uint256)", 100));
        vm.expectRevert("INVALID_DEAL_ID");
        dedeals.getDeal(101);
    }

    function test_Claim_InsufficientDeposit() public payable {
        // Call the claim function with an insufficient deposit and assert that it reverts
        (bool success,) = address(dedeals).call{value: 50}(abi.encodeWithSignature("claim(uint256,uint256)", 100, 3600));
        assertTrue(success, "claim should revert with insufficient deposit");
        vm.expectRevert("Insufficient deposit for claim");
        address(dedeals).call{value: 50}(abi.encodeWithSignature("claim(uint256,uint256)", 100, 3600));
    }

    function test_Claim_ExceededGrantDeadline() public payable {
        vm.roll(10);

        // Call the claim function and assert that it reverts
        (bool success,) =
            address(dedeals).call{value: 100}(abi.encodeWithSignature("claim(uint256,uint256)", 100, 3600));
        assertTrue(success, "claim should revert after grant deadline");
    }

    function test_Claim_WithExistingDeal() public payable {
        // Call the claim function with the necessary parameters
        DeDeals.Deal memory deal1 = dedeals.claim(100, 3600);

        // Call the claim function again and assert that it reverts
        (bool success,) =
            address(dedeals).call{value: 100}(abi.encodeWithSignature("claim(uint256,uint256)", 100, 3600));
        assertTrue(success, "claim should revert with existing deal");
    }
}
