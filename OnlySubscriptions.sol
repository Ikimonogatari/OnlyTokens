// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OnlyPeople {
    uint public nextPlanId;
    struct Profile {
        string nickname;
        string bio;
        uint planId;
    }
    struct Plan {
        address creator;
        address token;
        uint amount;
        uint frequency;
    }
    struct Subscription {
        address subscriber;
        uint start;
        uint nextPayment;
    }
    mapping(uint => Plan) public plans;
    mapping(address => mapping(uint => Subscription)) public subscriptions;
    mapping(address => mapping(string => Profile)) public profiles;
    event PlanCreated(
        address creator,
        uint planId,
        uint date
    );
    event ProfileCreated(
        address creator,
        string name,
        string nickname,
        string bio,
        uint planId
    );
    event SubscriptionCreated(
        address subscriber,
        uint planId,
        uint date
    );

    event SubscriptionCancelled(
        address subscriber,
        uint planId,
        uint date
    );
    event PaymentSent(
        address from,
        address to,
        uint amount,
        uint planId,
        uint date
    );

// This createSubPlan func can be modified to be creators plan of sub
    function createSubPlan(address token, uint amount, uint frequency) external {
        require(token != address(0), 'address cannot be null address');
        require(amount > 0, 'amount needs to be greater than 0');
        require(frequency > 0, 'frequency needs to be > 0');
        plans[nextPlanId] = Plan(
            msg.sender,
            token,
            amount,
            frequency
        );
        nextPlanId++;
    }
    function createProfile(string memory name, string memory nickname, string memory bio, uint planId) external {
        profiles[msg.sender][name] = Profile(
            nickname,
            bio,
            planId
        );
        emit ProfileCreated(msg.sender, name, nickname, bio, planId);
    }
    function getProfile(address creator, string memory name) external view returns (string memory nickname, string memory bio, uint planId){
        return (profiles[creator][name].nickname, profiles[creator][name].bio, profiles[creator][name].planId);
    }
    function getSubscriptions(uint planId) external view returns (address, address, uint, uint) {
        return (plans[planId].creator, plans[planId].token, plans[planId].amount, plans[planId].frequency);
    }
    function subscribe(uint planId) external {
        IERC20 token = IERC20(plans[planId].token);
        Plan storage plan = plans[planId];
        require(plan.creator != address(0), 'this plan does not exist');

        token.transferFrom(msg.sender, plan.creator, plan.amount);
        emit PaymentSent(
            msg.sender,
            plan.creator,
            plan.amount,
            planId,
            block.timestamp
        );

        subscriptions[msg.sender][planId] = Subscription(
            msg.sender,
            block.timestamp,
            block.timestamp + plan.frequency
        );
        emit SubscriptionCreated(msg.sender, planId, block.timestamp);
    }

    function cancel(uint planId) external {
        Subscription storage subscription = subscriptions[msg.sender][planId];
        require(
            subscription.subscriber != address(0),
            'this subscription does not exist'
        );
        delete subscriptions[msg.sender][planId];
        emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
    }

    function pay(address subscriber, uint planId) external {
        Subscription storage subscription = subscriptions[msg.sender][planId];
        Plan storage plan = plans[planId];
        IERC20 token = IERC20(plan.token);
        require(
            subscription.subscriber != address(0), 'this subscription does not exist'
        );
        require(
            block.timestamp > subscription.nextPayment, 
            'not due yet'
        );

        token.transferFrom(subscriber, plan.creator, plan.amount);
        emit PaymentSent(
            subscriber,
            plan.creator,
            plan.amount,
            planId,
            block.timestamp
        );
        subscription.nextPayment = subscription.nextPayment + plan.frequency;
    }

}