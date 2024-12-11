// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FactCheckToken} from "../src/FactCheckToken.sol";

contract FactCheckTokenTest is Test {
    FactCheckToken token;
    address user1;
    address user2;

    function setUp() public {
        token = new FactCheckToken();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1_000_000 * 10**18);
    }

    function testMintTokens() public {
        vm.prank(user1);
        token.mint(user1, 500 * 10**18);
        assertEq(token.balanceOf(user1), 500 * 10**18);
    }

    function testMintTokenLimit() public {
        vm.startPrank(user1);
        
        // Mint tokens multiple times
        for (uint i = 0; i < 10; i++) {
            token.mint(user1, 100 * 10**18);
        }
        
        // This should revert due to exceeding max mint limit
        vm.expectRevert("Exceeds max token mint limit");
        token.mint(user1, 100 * 10**18);
        
        vm.stopPrank();
    }

    function testBurnTokens() public {
        vm.prank(user1);
        token.mint(user1, 500 * 10**18);
        
        vm.startPrank(user1);
        token.burn(250 * 10**18);
        assertEq(token.balanceOf(user1), 250 * 10**18);
        vm.stopPrank();
    }
}