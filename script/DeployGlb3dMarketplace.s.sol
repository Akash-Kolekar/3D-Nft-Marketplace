// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {Glb3dMarketplace} from "../src/Glb3dMarketplace.sol";

contract DeployGlb3dMarketplace is Script {
    function run() external returns (Glb3dMarketplace) {
        vm.startBroadcast();

        Glb3dMarketplace marketplace = new Glb3dMarketplace();

        vm.stopBroadcast();

        // Log information for frontend integration
        console.log("Glb3dMarketplace deployed to:", address(marketplace));

        return marketplace;
    }
}
