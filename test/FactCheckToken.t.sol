// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FactCheckToken} from "../src/FactCheckToken.sol";
import {ContentVerification} from "../src/ContentVerification.sol";

contract ContentVerificationTest is Test {
    FactCheckToken token;
    ContentVerification contentVerification;
    
    address user1;
    address user2;
    address user3;

    function setUp() public {
        token = new FactCheckToken();
        contentVerification = new ContentVerification(address(token));
        
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
    }

    function testSubmitContent() public {
        vm.prank(user1);
        uint256 contentId = contentVerification.submitContent("test_hash_1");
        
        assertEq(contentId, 1);
    }

    function testVoteOnContent() public {
        // Submit content first
        vm.prank(user1);
        uint256 contentId = contentVerification.submitContent("test_hash_1");
        
        // Multiple users vote
        vm.prank(user2);
        contentVerification.voteOnContent(contentId, true);
        
        vm.prank(user3);
        contentVerification.voteOnContent(contentId, true);
        
        // Check vote counts
        (,,uint256 upvotes,,) = contentVerification.contents(contentId);
        assertEq(upvotes, 2);
    }

    function testContentVerification() public {
        // Submit content
        vm.prank(user1);
        uint256 contentId = contentVerification.submitContent("test_hash_1");
        
        // Simulate voting to reach verification threshold
        address[] memory voters = new address[](10);
        for (uint i = 0; i < 10; i++) {
            address voter = makeAddr(string(abi.encodePacked("voter", i)));
            vm.prank(voter);
            contentVerification.voteOnContent(contentId, true);
        }
        
        // Check content is verified
        assertTrue(contentVerification.isContentVerified(contentId));
    }

    function testPreventDoubleVoting() public {
        vm.prank(user1);
        uint256 contentId = contentVerification.submitContent("test_hash_1");
        
        vm.prank(user2);
        contentVerification.voteOnContent(contentId, true);
        
        vm.prank(user2);
        vm.expectRevert("Already voted");
        contentVerification.voteOnContent(contentId, false);
    }
}