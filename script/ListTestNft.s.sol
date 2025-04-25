// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Glb3dNft} from "../src/Glb3dNft.sol";
import {Glb3dMarketplace} from "../src/Glb3dMarketplace.sol";

/**
 * @title List Test NFT Script
 * @notice Lists a test NFT on the marketplace for development purposes
 */
contract ListTestNft is Script {
    // Contract addresses
    address public glb3dNftAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address public glb3dMarketplaceAddress = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    
    // Test data
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant LISTING_PRICE = 0.1 ether;
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        if (privateKey == 0) {
            // Use default Anvil private key if none provided
            privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }
        
        vm.startBroadcast(privateKey);
        
        Glb3dNft nft = Glb3dNft(glb3dNftAddress);
        Glb3dMarketplace marketplace = Glb3dMarketplace(glb3dMarketplaceAddress);
        
        // First, approve the marketplace to transfer the NFT
        nft.approve(glb3dMarketplaceAddress, TOKEN_ID);
        
        // Then list the NFT
        marketplace.listItem(glb3dNftAddress, TOKEN_ID, LISTING_PRICE);
        
        console.log("Listed NFT with token ID:", TOKEN_ID);
        console.log("Listing price:", LISTING_PRICE);
        
        vm.stopBroadcast();
    }
}
