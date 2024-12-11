// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FactCheckToken.sol";

contract ContentVerification {
    struct Content {
        address submitter;
        string contentHash;
        uint256 upvotes;
        uint256 downvotes;
        bool isVerified;
        mapping(address => bool) hasVoted;
    }

    FactCheckToken public token;
    
    uint256 public constant VERIFICATION_THRESHOLD = 10;
    uint256 public constant VOTE_REWARD = 5 * 10**18;
    uint256 public constant VERIFICATION_REWARD = 20 * 10**18;

    mapping(uint256 => Content) public contents;
    uint256 public contentCount;

    event ContentSubmitted(uint256 contentId, address submitter, string contentHash);
    event ContentVoted(uint256 contentId, address voter, bool isUpvote);
    event ContentVerified(uint256 contentId);

    constructor(address _tokenAddress) {
        token = FactCheckToken(_tokenAddress);
    }

    function submitContent(string memory _contentHash) external returns (uint256) {
        contentCount++;
        Content storage newContent = contents[contentCount];
        
        newContent.submitter = msg.sender;
        newContent.contentHash = _contentHash;
        
        emit ContentSubmitted(contentCount, msg.sender, _contentHash);
        return contentCount;
    }

    function voteOnContent(uint256 _contentId, bool _isUpvote) external {
        Content storage content = contents[_contentId];
        
        require(!content.hasVoted[msg.sender], "Already voted");
        require(_contentId <= contentCount, "Invalid content");
        
        content.hasVoted[msg.sender] = true;
        
        if (_isUpvote) {
            content.upvotes++;
        } else {
            content.downvotes++;
        }
        
        // Reward voter with tokens
        token.mint(msg.sender, VOTE_REWARD);
        
        emit ContentVoted(_contentId, msg.sender, _isUpvote);
        
        // Check if content is verified
        if (content.upvotes >= VERIFICATION_THRESHOLD) {
            content.isVerified = true;
            
            // Reward submitter
            token.mint(content.submitter, VERIFICATION_REWARD);
            
            emit ContentVerified(_contentId);
        }
    }

    function isContentVerified(uint256 _contentId) external view returns (bool) {
        return contents[_contentId].isVerified;
    }
}