// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "../src/BasicNft.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {NftMarketplace} from "../src/NftMarketplace.sol";
import {console2} from "forge-std/Test.sol";

contract MintApproveAndListNft is Script {
    string public constant PUG_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("BasicNft", block.chainid);
        address mostRecentlyDeployedNftMarkeplace =
            DevOpsTools.get_most_recent_deployment("NftMarketplace", block.chainid);

        console2.log("Minting NFT on contract: ", mostRecentlyDeployed);
        mintNftOnContract(mostRecentlyDeployed);

        console2.log("Approving NFT on contract: ", mostRecentlyDeployed);
        approveNft(mostRecentlyDeployed, mostRecentlyDeployedNftMarkeplace, 0);

        console2.log("Listing NFT on marketplace: ", mostRecentlyDeployedNftMarkeplace);
        listNftOnMarketplace(mostRecentlyDeployedNftMarkeplace, mostRecentlyDeployed, 0, 1e18);
    }

    function mintNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        BasicNft(contractAddress).mintNft(PUG_URI);
        vm.stopBroadcast();
    }

    function approveNft(address nftContractAddr, address marketplace, uint256 tokenId) public {
        vm.startBroadcast();
        BasicNft(nftContractAddr).approve(marketplace, tokenId);
        vm.stopBroadcast();
    }

    function listNftOnMarketplace(address marketplace, address nftContractAddr, uint256 tokenId, uint256 price)
        public
    {
        vm.startBroadcast();
        NftMarketplace(marketplace).listItem(nftContractAddr, tokenId, price);
        vm.stopBroadcast();
    }
}
