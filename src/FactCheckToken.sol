// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract FactCheckToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    uint256 public constant MAX_MINT_PER_CONTRIBUTOR = 1000 * 10**18;

    mapping(address => uint256) public contributorMintedTokens;

    constructor() ERC20("FactCheckToken", "FCT") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 amount) external {
        require(
            contributorMintedTokens[to] + amount <= MAX_MINT_PER_CONTRIBUTOR, 
            "Exceeds max token mint limit"
        );
        
        contributorMintedTokens[to] += amount;
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}