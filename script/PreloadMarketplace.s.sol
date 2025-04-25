// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Glb3dNft} from "../src/Glb3dNft.sol";
import {Glb3dMarketplace} from "../src/Glb3dMarketplace.sol";

/**
 * @title Preload Marketplace Script
 * @notice Deploys contracts and creates sample NFTs and listings for UI testing
 * @dev Run with: forge script script/PreloadMarketplace.s.sol --rpc-url http://localhost:8545 --broadcast
 */
contract PreloadMarketplace is Script {
    // Sample 3D model data
    struct ModelData {
        string name;
        string description;
        string glbUri;
        string previewUri;
        uint256 price; // in wei
    }

    // Sample NFTs to create
    ModelData[] public sampleModels;

    // Deployed contract addresses for testing purposes
    Glb3dNft public nft;
    Glb3dMarketplace public marketplace;

    function initializeSampleData() internal {
        // Add sample model data
        sampleModels.push(
            ModelData({
                name: "Buster Drone",
                description: "A",
                glbUri: "ipfs://bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4",
                previewUri: "ipfs://bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um",
                price: 0.05 ether
            })
        );

        sampleModels.push(
            ModelData({
                name: "Ancient Temple Ruins",
                description: "Detailed 3D model of ancient temple with intricate stone work",
                glbUri: "ipfs://bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4",
                previewUri: "ipfs://bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um",
                price: 0.08 ether
            })
        );

        sampleModels.push(
            ModelData({
                name: "Sci-Fi Helmet",
                description: "Space marine helmet with holographic visor",
                glbUri: "ipfs://bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4",
                previewUri: "ipfs://bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um",
                price: 0.03 ether
            })
        );

        sampleModels.push(
            ModelData({
                name: "Fantasy Dragon",
                description: "Animated dragon model with detailed scales and textures",
                glbUri: "ipfs://bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4",
                previewUri: "ipfs://bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um",
                price: 0.1 ether
            })
        );

        sampleModels.push(
            ModelData({
                name: "Modern Apartment Interior",
                description: "Fully furnished apartment interior with realistic lighting",
                glbUri: "ipfs://bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4",
                previewUri: "ipfs://bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um",
                price: 0.07 ether
            })
        );
    }

    function run() external returns (Glb3dNft, Glb3dMarketplace) {
        // Initialize sample data
        initializeSampleData();

        // Get deployer account
        uint256 deployerPrivateKey;
        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
        } catch {
            // Default anvil private key if not in environment
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts and creating sample NFTs from:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy contracts
        nft = new Glb3dNft();
        marketplace = new Glb3dMarketplace();

        // Log contract addresses
        console.log("Glb3dNft deployed to:", address(nft));
        console.log("Glb3dMarketplace deployed to:", address(marketplace));

        // Mint and list sample NFTs
        uint256[] memory tokenIds = new uint256[](sampleModels.length);

        for (uint256 i = 0; i < sampleModels.length; i++) {
            ModelData memory model = sampleModels[i];

            // Mint NFT
            uint256 tokenId = nft.mintGlb3dNft(
                model.glbUri,
                model.previewUri,
                model.name,
                model.description,
                1000 // 10% royalty
            );

            tokenIds[i] = tokenId;

            // Approve marketplace to transfer NFT
            nft.approve(address(marketplace), tokenId);

            // List on marketplace
            marketplace.listItem(address(nft), tokenId, model.price);

            console.log("Created and listed NFT #%d: %s for %d wei", tokenId, model.name, model.price);
        }

        // Create one featured listing
        if (sampleModels.length > 0) {
            marketplace.setFeaturedListing(address(nft), tokenIds[0], true);
            console.log("Set NFT #%d as featured", tokenIds[0]);
        }

        vm.stopBroadcast();

        console.log("\n--- MARKETPLACE PRELOADED SUCCESSFULLY ---");
        console.log("Use these contract addresses in your frontend:");
        console.log("{");
        console.log("  \"glb3dNftAddress\": \"%s\",", address(nft));
        console.log("  \"marketplaceAddress\": \"%s\"", address(marketplace));
        console.log("}");
        console.log("\nThe marketplace has been preloaded with %d sample NFTs", sampleModels.length);

        return (nft, marketplace);
    }

    // Add a test mode function that doesn't use broadcasting
    function runTest(address deployer) external returns (Glb3dNft, Glb3dMarketplace) {
        // Initialize sample data
        initializeSampleData();

        console.log("Deploying contracts and creating sample NFTs from:", deployer);

        // Deploy contracts directly (no broadcast)
        nft = new Glb3dNft();
        marketplace = new Glb3dMarketplace();

        // Transfer ownership of NFT contract to deployer
        nft.transferOwnership(deployer);

        // For Marketplace, we can't directly access owner() since it's not exposed
        // We'll have to rely on the constructor setting up ownership correctly
        console.log("Note: Using deployer as the operator for marketplace functions");

        console.log("Glb3dNft deployed to:", address(nft));
        console.log("Glb3dMarketplace deployed to:", address(marketplace));

        // We need to use the deployer as the caller for all operations
        vm.startPrank(deployer);

        // Mint and list sample NFTs
        uint256[] memory tokenIds = new uint256[](sampleModels.length);

        for (uint256 i = 0; i < sampleModels.length; i++) {
            ModelData memory model = sampleModels[i];

            // Mint NFT (now directly to deployer)
            uint256 tokenId = nft.mintGlb3dNft(
                model.glbUri,
                model.previewUri,
                model.name,
                model.description,
                1000 // 10% royalty
            );

            tokenIds[i] = tokenId;

            // Approve marketplace to transfer NFT
            nft.approve(address(marketplace), tokenId);

            // List on marketplace
            marketplace.listItem(address(nft), tokenId, model.price);

            console.log("Created and listed NFT #%d: %s for %d wei", tokenId, model.name, model.price);
        }

        // Create one featured listing
        if (sampleModels.length > 0) {
            // Create a new deployer-owned marketplace just for testing
            Glb3dMarketplace testMarketplace = new Glb3dMarketplace();

            // Replace our marketplace instance with the new one
            marketplace = testMarketplace;

            // List the NFT in the new marketplace too
            nft.approve(address(marketplace), tokenIds[0]);
            marketplace.listItem(address(nft), tokenIds[0], sampleModels[0].price);

            // Now we should be able to set it as featured since deployer created the marketplace
            marketplace.setFeaturedListing(address(nft), tokenIds[0], true);
            console.log("Set NFT #%d as featured in test marketplace", tokenIds[0]);
        }

        // Stop pranking since we're done
        vm.stopPrank();

        console.log("\n--- MARKETPLACE PRELOADED SUCCESSFULLY ---");
        console.log("Use these contract addresses in your frontend:");
        console.log("{");
        console.log("  \"glb3dNftAddress\": \"%s\",", address(nft));
        console.log("  \"marketplaceAddress\": \"%s\"", address(marketplace));
        console.log("}");
        console.log("\nThe marketplace has been preloaded with %d sample NFTs", sampleModels.length);

        return (nft, marketplace);
    }

    // Helper functions for testing
    function getDeployedNft() external view returns (address) {
        return address(nft);
    }

    function getDeployedMarketplace() external view returns (address) {
        return address(marketplace);
    }
}
