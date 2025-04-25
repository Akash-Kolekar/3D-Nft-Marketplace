// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Glb3dNft} from "../src/Glb3dNft.sol";
import {Glb3dMarketplace} from "../src/Glb3dMarketplace.sol";
import {DeployGlb3dNft} from "./DeployGlb3dNft.s.sol";
import {DeployGlb3dMarketplace} from "./DeployGlb3dMarketplace.s.sol";

/**
 * @title Deploy All Script
 * @notice Deploys all contracts needed for the Glb3d NFT marketplace
 * @dev Run with: forge script script/DeployAll.s.sol --rpc-url http://localhost:8545 --broadcast
 */
contract DeployAll is Script {
    function run() external {
        DeployGlb3dNft deployNft = new DeployGlb3dNft();
        DeployGlb3dMarketplace deployMarketplace = new DeployGlb3dMarketplace();

        Glb3dNft glb3dNft = deployNft.run();
        Glb3dMarketplace marketplace = deployMarketplace.run();

        // Print out deployment information in JSON format for easy parsing
        console.log("\n--- DEPLOYMENT SUMMARY ---");
        console.log("Copy these addresses for your frontend:");
        console.log("{");
        console.log("  \"glb3dNftAddress\": \"%s\",", address(glb3dNft));
        console.log("  \"marketplaceAddress\": \"%s\"", address(marketplace));
        console.log("}");

        // Helpful information for manual testing
        console.log("\n--- VERIFICATION INFO ---");
        console.log("NFT Contract: %s", address(glb3dNft));
        console.log("Marketplace Contract: %s", address(marketplace));
        console.log("\n--- NEXT STEPS ---");
        console.log("1. Update your frontend with these contract addresses");
        console.log("2. Import ABIs from your artifacts directory");
    }
}
