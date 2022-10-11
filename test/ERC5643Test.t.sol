// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC5643.sol";
import "../src/mocks/ERC5643Mock.sol";

contract ERC5643Test is Test {
    event SubscriptionUpdate(uint256 indexed tokenId, uint64 expiration);

    address user1 = address(0x1);
    address user2 = address(0x2);
    uint256 tokenId = 1;
    uint256 tokenId2 = 2;
    ERC5643Mock erc5643;

    function setUp() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);

        erc5643 = new ERC5643Mock("erc5369", "ERC5643");
        erc5643.mint(user1, tokenId);
    }

    function testRenewalInvalidTokenId() public {
        vm.prank(user1);
        vm.expectRevert("ERC721: invalid token ID");
        erc5643.renewSubscription{value: 0.1 ether}(tokenId + 10, 30 days);
    }

    function testRenewalNotOwner() public {
        vm.expectRevert("Caller is not owner nor approved");
        erc5643.renewSubscription(tokenId, 2000);
    }

    function testRenewalDurationTooShort() public {
        erc5643.setMinimumRenewalDuration(1000);
        vm.prank(user1);
        vm.expectRevert(RenewalTooShort.selector);
        erc5643.renewSubscription{value: 0.1 ether}(tokenId, 999);
    }

    function testRenewalDurationTooLong() public {
        erc5643.setMaximumRenewalDuration(1000);
        vm.prank(user1);
        vm.expectRevert(RenewalTooLong.selector);
        erc5643.renewSubscription{value: 0.1 ether}(tokenId, 1001);
    }

    function testRenewalInsufficientPayment() public {
        vm.prank(user1);
        vm.expectRevert(InsufficientPayment.selector);
        erc5643.renewSubscription{value: 0.09 ether}(tokenId, 30 days);
    }

    function testRenewalNewSubscription() public {
        vm.warp(1000);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 30 days + 1000);
        erc5643.renewSubscription{value: 0.1 ether}(tokenId, 30 days);
    }

    function testRenewalExistingSubscription() public {
        vm.warp(1000);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId2, 60 days + 1000);
        erc5643.mintWithSubscription(user2, tokenId2, 60 days);

        // This renewal should fail because the subscription is not renewable
        vm.prank(user2);
        vm.expectRevert(SubscriptionNotRenewable.selector);
        erc5643.renewSubscription{value: 0.1 ether}(tokenId2, 30 days);

        erc5643.setRenewable(true);

        // This renewal will succeed because the subscription is renewable
        vm.prank(user2);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId2, 90 days + 1000);
        erc5643.renewSubscription{value: 0.1 ether}(tokenId2, 30 days);
    }

    function testCancelValid() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit SubscriptionUpdate(tokenId, 0);
        erc5643.cancelSubscription(tokenId);
    }

    function testCancelNotOwner() public {
        vm.expectRevert("Caller is not owner nor approved");
        erc5643.cancelSubscription(tokenId);
    }

    function testExpiresAt() public {
        vm.warp(1000);

        assertEq(erc5643.expiresAt(tokenId), 0);
        vm.startPrank(user1);
        erc5643.renewSubscription{value: 0.1 ether}(tokenId, 2000);
        assertEq(erc5643.expiresAt(tokenId), 3000);

        erc5643.cancelSubscription(tokenId);
        assertEq(erc5643.expiresAt(tokenId), 0);
    }

    function testExtendSubscriptionInvalidToken() public {
        vm.expectRevert(InvalidTokenId.selector);
        erc5643.extendSubscription(tokenId + 100, 30 days);
    }
}
