// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Glb3dNft} from "../src/Glb3dNft.sol";

/**
 * @title Mint Test NFT Script
 * @notice Mints a test NFT for development purposes
 */
contract MintTestNft is Script {
    // Contract address
    address public glb3dNftAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    
    // Test data
    string public constant GLB_URI = "https://market-assets.fra1.cdn.digitaloceanspaces.com/market-assets/assets/Astronaut.glb";
    string public constant PREVIEW_URI = "https://market-assets.fra1.cdn.digitaloceanspaces.com/market-assets/assets/Astronaut_preview.png";
    string public constant NAME = "Test Astronaut 3D Model";
    string public constant DESCRIPTION = "This is a test 3D model of an astronaut for demonstration purposes.";
    uint256 public constant ROYALTY_BPS = 1000; // 10%
    
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        if (privateKey == 0) {
            // Use default Anvil private key if none provided
            privateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }
        
        vm.startBroadcast(privateKey);
        
        Glb3dNft nft = Glb3dNft(glb3dNftAddress);
        uint256 tokenId = nft.mintGlb3dNft(
            GLB_URI,
            PREVIEW_URI,
            NAME,
            DESCRIPTION,
            ROYALTY_BPS
        );
        
        console.log("Minted NFT with token ID:", tokenId);
        
        vm.stopBroadcast();
    }
}
