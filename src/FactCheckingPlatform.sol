// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FactCheckToken.sol";
import "./ContentVerification.sol";

contract FactCheckingPlatform {
    FactCheckToken public token;
    ContentVerification public contentVerification;

    struct Contributor {
        uint256 totalSubmissions;
        uint256 verifiedSubmissions;
        uint256 totalVotes;
    }

    mapping(address => Contributor) public contributors;
    mapping(uint256 => address) public contentSubmitters;
    
    uint256 public constant REPUTATION_MULTIPLIER = 2;

    event ContributorUpdated(address contributor, uint256 submissions, uint256 verifiedSubmissions);

    constructor(address _tokenAddress, address _contentVerificationAddress) {
        token = FactCheckToken(_tokenAddress);
        contentVerification = ContentVerification(_contentVerificationAddress);
    }

    function submitAndTrackContent(string memory _contentHash) external returns (uint256) {
        uint256 contentId = contentVerification.submitContent(_contentHash);
        
        contributors[msg.sender].totalSubmissions++;
        contentSubmitters[contentId] = msg.sender;
        
        return contentId;
    }

    function updateContributorReputation(uint256 _contentId) external {
        require(contentVerification.isContentVerified(_contentId), "Content not verified");
        require(msg.sender == contentSubmitters[_contentId], "Not content submitter");
        
        Contributor storage contributor = contributors[msg.sender];
        contributor.verifiedSubmissions++;
        
        // Bonus token reward for verified submissions
        uint256 bonusTokens = contributor.verifiedSubmissions * REPUTATION_MULTIPLIER * 10**18;
        token.mint(msg.sender, bonusTokens);
        
        emit ContributorUpdated(
            msg.sender, 
            contributor.totalSubmissions, 
            contributor.verifiedSubmissions
        );
    }

    function getContributorStats(address _contributor) external view returns (
        uint256 totalSubmissions, 
        uint256 verifiedSubmissions
    ) {
        Contributor memory contributor = contributors[_contributor];
        return (
            contributor.totalSubmissions,
            contributor.verifiedSubmissions
        );
    }
}