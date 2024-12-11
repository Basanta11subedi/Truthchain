// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FactCheckToken} from "../src/FactCheckToken.sol";
import {ContentVerification} from "../src/ContentVerification.sol";
import {FactCheckingPlatform} from "../src/FactCheckingPlatform.sol";

contract FactCheckingPlatformTest is Test {
    FactCheckToken token;
    ContentVerification contentVerification;
    FactCheckingPlatform platform;
    
    address user1;
    address user2;
    address user3;

    function setUp() public {
        token = new FactCheckToken();
        contentVerification = new ContentVerification(address(token));
        platform = new FactCheckingPlatform(address(token), address(contentVerification));
        
        // Transfer token ownership to platform
        token.transferOwnership(address(platform));
        
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
    }

    function testSubmitAndTrackContent() public {
        vm.prank(user1);
        uint256 contentId = platform.submitAndTrackContent("test_hash_1");
        console.log(contentId);
        
        (uint256 totalSubmissions, ) = platform.getContributorStats(user1);
        assertEq(totalSubmissions, 1);
    }

    function testMultipleContentSubmissions() public {
        vm.startPrank(user1);
        platform.submitAndTrackContent("test_hash_1");
        platform.submitAndTrackContent("test_hash_2");
        platform.submitAndTrackContent("test_hash_3");
        vm.stopPrank();
        
        (uint256 totalSubmissions, ) = platform.getContributorStats(user1);
        assertEq(totalSubmissions, 3);
    }

    function testUpdateContributorReputation() public {
        // Submit content
        vm.prank(user1);
        uint256 contentId = platform.submitAndTrackContent("test_hash_1");
        console.log(contentId);
        
        // Simulate verification
        address[] memory voters = new address[](10);
        for (uint i = 0; i < 10; i++) {
            address voter = makeAddr(string(abi.encodePacked("voter", i)));
            vm.prank(voter);
            contentVerification.voteOnContent(contentId, true);
        }
        
        // Update reputation
        vm.prank(user1);
        platform.updateContributorReputation(contentId);
        
        (uint256 totalSubmissions, uint256 verifiedSubmissions) = platform.getContributorStats(user1);
        assertEq(totalSubmissions, 1);
        assertEq(verifiedSubmissions, 1);
    }

    function testReputationTokenReward() public {
        // Submit content
        vm.prank(user1);
        uint256 contentId = platform.submitAndTrackContent("test_hash_1");
        console.log(contentId);
        
        // Simulate verification
        address[] memory voters = new address[](10);
        for (uint i = 0; i < 10; i++) {
            address voter = makeAddr(string(abi.encodePacked("voter", i)));
            vm.prank(voter);
            contentVerification.voteOnContent(contentId, true);
        }
        
        // Check initial token balance
        uint256 initialBalance = token.balanceOf(user1);
        
        // Update reputation
        vm.prank(user1);
        platform.updateContributorReputation(contentId);
        
        // Check token balance increased
        uint256 finalBalance = token.balanceOf(user1);
        assertTrue(finalBalance > initialBalance, "Token balance should increase");
    }

    function testUpdateReputationForUnverifiedContent() public {
        // Submit content
        vm.prank(user1);
        uint256 contentId = platform.submitAndTrackContent("test_hash_1");
        console.log(contentId);
        
        // Try to update reputation for unverified content
        vm.prank(user1);
        vm.expectRevert("Content not verified");
        platform.updateContributorReputation(contentId);
    }

    function testContributorStatsAcrossMultipleSubmissions() public {
        // Submit multiple contents with varying verification
        vm.startPrank(user1);
        uint256 contentId1 = platform.submitAndTrackContent("test_hash_1");
        uint256 contentId2 = platform.submitAndTrackContent("test_hash_2");
        uint256 contentId3 = platform.submitAndTrackContent("test_hash_3");
        console.log(contentId1);
        console.log(contentId2);
        console.log(contentId3);
        vm.stopPrank();
        
        // Verify some contents
        address[] memory voters = new address[](10);
        for (uint i = 0; i < 10; i++) {
            address voter = makeAddr(string(abi.encodePacked("voter", i)));
            
            // Verify first two contents
            vm.prank(voter);
            contentVerification.voteOnContent(contentId1, true);
            
            vm.prank(voter);
            contentVerification.voteOnContent(contentId2, true);
        }
        
        // Update reputation for verified contents
        vm.startPrank(user1);
        platform.updateContributorReputation(contentId1);
        platform.updateContributorReputation(contentId2);
        vm.stopPrank();
        
        // Check contributor stats
        (uint256 totalSubmissions, uint256 verifiedSubmissions) = platform.getContributorStats(user1);
        
        assertEq(totalSubmissions, 3, "Total submissions should be 3");
        assertEq(verifiedSubmissions, 2, "Verified submissions should be 2");
    }

    function testCannotUpdateReputationForOtherUserContent() public {
        // Submit content by user1
        vm.prank(user1);
        uint256 contentId = platform.submitAndTrackContent("test_hash_1");
        console.log(contentId);
        
        // Simulate verification
        address[] memory voters = new address[](10);
        for (uint i = 0; i < 10; i++) {
            address voter = makeAddr(string(abi.encodePacked("voter", i)));
            vm.prank(voter);
            contentVerification.voteOnContent(contentId, true);
        }
        
        // Try to update reputation by user2 (not the content submitter)
        vm.prank(user2);
        vm.expectRevert("Not content submitter");
        platform.updateContributorReputation(contentId);
    }
}