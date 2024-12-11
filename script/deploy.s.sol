// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {FactCheckToken} from "../src/FactCheckToken.sol";
import {ContentVerification} from "../src/ContentVerification.sol";
import {FactCheckingPlatform} from "../src/FactCheckingPlatform.sol";

contract DeployFactCheckPlatform is Script {
    function run() external returns (
        FactCheckToken token, 
        ContentVerification contentVerification, 
        FactCheckingPlatform platform
    ) {
        vm.startBroadcast();
        
        // Deploy Token Contract
        token = new FactCheckToken();
        
        // Deploy Content Verification Contract
        contentVerification = new ContentVerification(address(token));
        
        // Deploy Fact-Checking Platform Contract
        platform = new FactCheckingPlatform(
            address(token), 
            address(contentVerification)
        );
        
        // Transfer ownership of minting to Platform contract
        token.transferOwnership(address(platform));
        
        vm.stopBroadcast();
        
        return (token, contentVerification, platform);
    }
}