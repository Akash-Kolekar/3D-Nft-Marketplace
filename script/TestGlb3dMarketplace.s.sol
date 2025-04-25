// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Glb3dNft} from "../src/Glb3dNft.sol";
import {Glb3dMarketplace} from "../src/Glb3dMarketplace.sol";

/**
 * @title Test Glb3d Marketplace Script
 * @notice Tests the functionality of the Glb3dNft and Glb3dMarketplace contracts
 */
contract TestGlb3dMarketplace is Script {
    // Contract addresses
    address public glb3dNftAddress;
    address public glb3dMarketplaceAddress;

    // Test accounts
    address public seller;
    address public buyer;
    uint256 public sellerKey;
    uint256 public buyerKey;

    // Test data
    string public constant GLB_URI = "ipfs://QmXxxx/model.glb";
    string public constant PREVIEW_URI = "ipfs://QmXxxx/preview.png";
    string public constant NAME = "Test 3D Model";
    string public constant DESCRIPTION = "This is a test 3D model";
    uint256 public constant ROYALTY_BPS = 1000; // 10%
    uint256 public constant LISTING_PRICE = 1 ether;
    uint256 public constant OFFER_PRICE = 0.8 ether;
    uint256 public constant OFFER_DURATION = 86400; // 1 day

    function setUp() public {
        // Set up test accounts
        sellerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        buyerKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        seller = vm.addr(sellerKey);
        buyer = vm.addr(buyerKey);

        // We need to deploy new contracts since both were deployed to the same address
        // Deploy Glb3dNft
        vm.startBroadcast(sellerKey);
        Glb3dNft nft = new Glb3dNft();
        glb3dNftAddress = address(nft);
        vm.stopBroadcast();

        // Deploy Glb3dMarketplace
        vm.startBroadcast(sellerKey);
        Glb3dMarketplace marketplace = new Glb3dMarketplace();
        glb3dMarketplaceAddress = address(marketplace);
        vm.stopBroadcast();

        console.log("Glb3dNft deployed to:", glb3dNftAddress);
        console.log("Glb3dMarketplace deployed to:", glb3dMarketplaceAddress);
    }

    function run() external {
        setUp();

        // 1. Mint a 3D GLB NFT
        console.log("1. Minting a 3D GLB NFT...");
        uint256 tokenId = mintNft();
        console.log("   NFT minted with token ID:", tokenId);

        // 2. List the NFT on the marketplace
        console.log("2. Listing the NFT on the marketplace...");
        listNft(tokenId);
        console.log("   NFT listed successfully");

        // 3. Make an offer on the NFT
        console.log("3. Making an offer on the NFT...");
        makeOffer(tokenId);
        console.log("   Offer made successfully");

        // 4. Accept the offer
        console.log("4. Accepting the offer...");
        acceptOffer(tokenId);
        console.log("   Offer accepted successfully");

        console.log("All tests completed successfully!");
    }

    function mintNft() internal returns (uint256) {
        vm.startBroadcast(sellerKey);

        Glb3dNft nft = Glb3dNft(glb3dNftAddress);
        uint256 tokenId = nft.mintGlb3dNft(GLB_URI, PREVIEW_URI, NAME, DESCRIPTION, ROYALTY_BPS);

        vm.stopBroadcast();

        return tokenId;
    }

    function listNft(uint256 tokenId) internal {
        vm.startBroadcast(sellerKey);

        Glb3dNft nft = Glb3dNft(glb3dNftAddress);
        Glb3dMarketplace marketplace = Glb3dMarketplace(glb3dMarketplaceAddress);

        // Approve the marketplace to transfer the NFT
        nft.approve(glb3dMarketplaceAddress, tokenId);

        // List the NFT
        marketplace.listItem(glb3dNftAddress, tokenId, LISTING_PRICE);

        vm.stopBroadcast();
    }

    function makeOffer(uint256 tokenId) internal {
        vm.startBroadcast(buyerKey);

        Glb3dMarketplace marketplace = Glb3dMarketplace(glb3dMarketplaceAddress);

        // Make an offer
        marketplace.createOffer{value: OFFER_PRICE}(glb3dNftAddress, tokenId, OFFER_DURATION);

        vm.stopBroadcast();
    }

    function acceptOffer(uint256 tokenId) internal {
        vm.startBroadcast(sellerKey);

        Glb3dMarketplace marketplace = Glb3dMarketplace(glb3dMarketplaceAddress);

        // Accept the offer
        marketplace.acceptOffer(glb3dNftAddress, tokenId, buyer);

        vm.stopBroadcast();
    }
}
