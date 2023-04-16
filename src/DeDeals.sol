/**
 * Submitted for verification at polygonscan.com on 2023-04-15
 */

// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.19;

contract DeDeals {
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

    mapping(uint256 => Deal) dealIdMap;
    uint256 dealIdMapCount;

    event CreateDeal(Deal _deal);

    event eventMsgValue(uint256 _msgValue);

    function createDeal(
        uint256 _dealDeadline,
        uint256 _executeDeadlineInterval
    ) public payable returns (Deal memory) {
        require(
            msg.value >= dealIdMap[0].dealAmount,
            "Insufficient deposit for claim"
        );
        dealIdMapCount = dealIdMapCount + 1;
        address sellerAddress = msg.sender;
        address buyerAddress;
        uint256 sellerDeposit = msg.value;
        uint256 buyerDeposit = 0;
        uint256 dealAmount = msg.value;
        uint256 depositReleaseTime = block.timestamp + _dealDeadline;

        dealIdMap[dealIdMapCount] = Deal(
            dealIdMapCount,
            sellerAddress,
            buyerAddress,
            sellerDeposit,
            buyerDeposit,
            dealAmount,
            depositReleaseTime,
            _dealDeadline,
            _executeDeadlineInterval
        );

        emit CreateDeal(dealIdMap[dealIdMapCount]);
        return dealIdMap[dealIdMapCount];
    }

    function fundDeal(uint256 _dealId) public payable returns (Deal memory) {
        //Check if msg.value matches the claimAmount of the corresponding deal.
        requireMsgValueEqualClaimAmount(
            msg.value,
            dealIdMap[_dealId].dealAmount
        );
        //Check to see if the current time has not exceeded the depositReleaseTime.
        requireDepositReleaseTimeNotPassed(_dealId);

        dealIdMap[_dealId].buyerAddress = msg.sender;
        dealIdMap[_dealId].sellerDeposit += msg.value;
        dealIdMap[_dealId].depositReleaseTime += dealIdMap[_dealId]
            .executeDeadlineInterval;

        emit CreateDeal(dealIdMap[_dealId]);

        return dealIdMap[_dealId];
    }

    function executeBuyer(uint256 _dealId) public payable {
        //Check if msg.sender is the buyer of the corresponding deal.
        requireMsgSenderEqualbuyer(_dealId, msg.sender);
        //Check if msg.value is exactly twice the claimAmount.
        requireMsgValueEqualDoubleClaimAmount(_dealId, msg.value);
        //Check if dealIdMap[_dealId].sellerDeposit is not empty.
        requiresellerDepositNotEqualZero(_dealId);
        //Check to see if the current time has not exceeded the depositReleaseTime.
        requireDepositReleaseTimeNotPassed(_dealId);

        executedBalance += dealIdMap[_dealId].sellerDeposit;
        dealIdMap[_dealId].sellerDeposit = 0;
        dealIdMap[_dealId].buyerDeposit += msg.value;
        dealIdMap[_dealId].depositReleaseTime += dealIdMap[_dealId]
            .executeDeadlineInterval;

        emit CreateDeal(dealIdMap[_dealId]);
    }

    function executeSeller(uint256 _dealId) public payable {
        //Check if msg.sender is the seller of the corresponding deal.
        requireMsgSenderEqualseller(_dealId, msg.sender);
        //Check if msg.value is exactly twice the claimAmount
        requireMsgValueEqualDoubleClaimAmount(_dealId, msg.value);
        //Check if dealIdMap[_dealId].buyerDeposit is not empty.
        requirebuyerDepositNotEqualZero(_dealId);
        //Check if the current time has not exceeded the depositReleaseTime.
        requireDepositReleaseTimeNotPassed(_dealId);

        executedBalance += dealIdMap[_dealId].buyerDeposit;
        dealIdMap[_dealId].buyerDeposit = 0;
        dealIdMap[_dealId].sellerDeposit += msg.value;
        dealIdMap[_dealId].depositReleaseTime += dealIdMap[_dealId]
            .executeDeadlineInterval;

        emit CreateDeal(dealIdMap[_dealId]);
    }

    function releaseDeposits(
        uint256 _dealId
    ) public returns (Deal memory, uint256, uint256) {
        //Check if the current time has not exceeded the depositReleaseTime.
        requireDepositReleaseTimePassed(_dealId);

        payable(dealIdMap[_dealId].buyerAddress).transfer(
            dealIdMap[_dealId].buyerDeposit
        );
        dealIdMap[_dealId].buyerDeposit = 0;

        payable(dealIdMap[_dealId].sellerAddress).transfer(
            dealIdMap[_dealId].sellerDeposit
        );
        dealIdMap[_dealId].sellerDeposit = 0;

        emit CreateDeal(dealIdMap[_dealId]);

        return (
            dealIdMap[_dealId],
            block.timestamp,
            dealIdMap[_dealId].depositReleaseTime
        );
    }

    function getDeal(uint _dealId) public view returns (Deal memory) {
        require(_dealId > 0 && _dealId <= dealIdMapCount, "INVALID_DEAL_ID");
        return dealIdMap[_dealId];
    }

    function requireDepositReleaseTimeNotPassed(uint256 _dealId) public view {
        require(
            block.timestamp < dealIdMap[_dealId].depositReleaseTime,
            "DepositReleaseTime already passed."
        );
    }

    function requireDepositReleaseTimePassed(uint256 _dealId) public view {
        require(
            block.timestamp >= dealIdMap[_dealId].depositReleaseTime,
            "DepositReleaseTime has not yet passed."
        );
    }

    function requireMsgValueEqualDoubleClaimAmount(
        uint256 _dealId,
        uint256 _msgValue
    ) public view {
        require(
            _msgValue == 2 * dealIdMap[_dealId].dealAmount,
            "The amount transferred is not exactly twice the amount of claim."
        );
    }

    function requireMsgValueEqualClaimAmount(
        uint256 _msgValue,
        uint256 _dealAmount
    ) public pure {
        require(
            _msgValue == _dealAmount,
            "The amount transferred is not exactly the amount of claim."
        );
    }

    function requireMsgSenderEqualseller(
        uint256 _dealId,
        address _msgSender
    ) public view {
        require(
            _msgSender == dealIdMap[_dealId].sellerAddress,
            "MsgSender does not match the specified deal seller."
        );
    }

    function requireMsgSenderEqualbuyer(
        uint256 _dealId,
        address _msgSender
    ) public view {
        require(
            _msgSender == dealIdMap[_dealId].buyerAddress,
            "MsgSender does not match the specified deal buyer."
        );
    }

    function requiresellerDepositNotEqualZero(uint256 _dealId) public view {
        require(
            dealIdMap[_dealId].sellerDeposit != 0,
            "seller's deposit is empty."
        );
    }

    function requirebuyerDepositNotEqualZero(uint256 _dealId) public view {
        require(
            dealIdMap[_dealId].buyerDeposit != 0,
            "buyer's deposit is empty."
        );
    }
}
