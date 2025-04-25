// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Glb3dNft} from "../src/Glb3dNft.sol";

contract DeployGlb3dNft is Script {
    function run() external returns (Glb3dNft) {
        vm.startBroadcast();

        Glb3dNft glb3dNft = new Glb3dNft();

        vm.stopBroadcast();

        // Log information for frontend integration
        console.log("Glb3dNft deployed to:", address(glb3dNft));

        return glb3dNft;
    }
}
