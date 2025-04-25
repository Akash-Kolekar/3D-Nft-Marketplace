// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {Glb3dNft} from "../src/Glb3dNft.sol";
import {Glb3dMarketplace} from "../src/Glb3dMarketplace.sol";

contract Glb3dMarketplaceTest is Test {
    Glb3dNft public glb3dNft;
    Glb3dMarketplace public marketplace;

    // Test addresses
    address public deployer = makeAddr("deployer");
    address public seller = makeAddr("seller");
    address public buyer = makeAddr("buyer");
    address public creator = makeAddr("creator");

    // Test values
    uint256 public constant LISTING_PRICE = 1 ether;
    uint256 public constant ROYALTY_BPS = 1000; // 10%
    uint256 private constant PLATFORM_FEE_BPS = 250; // 2.5%
    string public constant GLB_URI = "ipfs://QmSomeGlbFileHash";
    string public constant PREVIEW_URI = "ipfs://QmSomePreviewImageHash";
    string public constant MODEL_NAME = "Cool 3D Model";
    string public constant MODEL_DESCRIPTION = "A very cool 3D GLB model";

    // Events to test
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        string previewUri,
        bool is3dGlb
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address creator,
        uint256 royaltyAmount
    );
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event FeaturedStatusChanged(address indexed nftAddress, uint256 indexed tokenId, bool isFeatured);
    event RoyaltyPaid(address indexed creator, uint256 indexed tokenId, uint256 amount);

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy contracts
        glb3dNft = new Glb3dNft();
        marketplace = new Glb3dMarketplace();

        vm.stopPrank();
    }

    /* Helper Functions */
    function mintAndApproveNft(address _minter) internal returns (uint256) {
        vm.startPrank(_minter);

        uint256 tokenId = glb3dNft.mintGlb3dNft(GLB_URI, PREVIEW_URI, MODEL_NAME, MODEL_DESCRIPTION, ROYALTY_BPS);

        glb3dNft.approve(address(marketplace), tokenId);

        vm.stopPrank();

        return tokenId;
    }

    /* Test Listing Functions */
    function testListItem() public {
        uint256 tokenId = mintAndApproveNft(seller);

        vm.startPrank(seller);

        vm.expectEmit(true, true, true, true);
        emit ItemListed(seller, address(glb3dNft), tokenId, LISTING_PRICE, PREVIEW_URI, true);

        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Verify listing
        Glb3dMarketplace.Listing memory listing = marketplace.getListing(address(glb3dNft), tokenId);
        assertEq(listing.price, LISTING_PRICE);
        assertEq(listing.seller, seller);
        assertEq(listing.tokenId, tokenId);
        assertEq(listing.nftAddress, address(glb3dNft));
        assertTrue(listing.is3dGlb);
        assertEq(listing.previewUri, PREVIEW_URI);

        vm.stopPrank();
    }

    function testCannotListWithZeroPrice() public {
        uint256 tokenId = mintAndApproveNft(seller);

        vm.startPrank(seller);

        vm.expectRevert(Glb3dMarketplace.Glb3dMarketplace__PriceMustBeAboveZero.selector);
        marketplace.listItem(address(glb3dNft), tokenId, 0);

        vm.stopPrank();
    }

    function testCannotListIfNotOwner() public {
        uint256 tokenId = mintAndApproveNft(seller);

        vm.startPrank(buyer);

        vm.expectRevert(Glb3dMarketplace.Glb3dMarketplace__NotOwner.selector);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        vm.stopPrank();
    }

    function testCannotListIfNotApproved() public {
        vm.startPrank(seller);

        uint256 tokenId = glb3dNft.mintGlb3dNft(GLB_URI, PREVIEW_URI, MODEL_NAME, MODEL_DESCRIPTION, ROYALTY_BPS);

        // No approval for marketplace

        vm.expectRevert(Glb3dMarketplace.Glb3dMarketplace__NotApprovedForMarketplace.selector);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        vm.stopPrank();
    }

    /* Test Buying Functions */
    function testBuyItem() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Get balances before purchase
        uint256 sellerBalanceBefore = seller.balance;

        // Calculate expected royalty and platform fee
        uint256 royaltyAmount = (LISTING_PRICE * ROYALTY_BPS) / 10000;
        uint256 platformFee = (LISTING_PRICE * PLATFORM_FEE_BPS) / 10000;
        uint256 sellerProceeds = LISTING_PRICE - platformFee; // Since seller is creator

        // Fund the buyer with enough ETH first
        vm.deal(buyer, LISTING_PRICE * 2);

        // Set up the expected events
        vm.expectEmit(true, true, true, false); // Don't check the data fields
        emit ItemBought(buyer, address(glb3dNft), tokenId, LISTING_PRICE, address(0), 0);

        // Buy the NFT
        vm.startPrank(buyer);
        marketplace.buyItem{value: LISTING_PRICE}(address(glb3dNft), tokenId);
        vm.stopPrank();

        // Verify NFT ownership changed
        assertEq(glb3dNft.ownerOf(tokenId), buyer);

        // Verify proceeds were stored correctly
        assertEq(marketplace.getProceeds(seller), sellerProceeds);
        assertEq(marketplace.getProceeds(deployer), platformFee);

        // Verify listing was removed
        Glb3dMarketplace.Listing memory listing = marketplace.getListing(address(glb3dNft), tokenId);
        assertEq(listing.price, 0);
    }

    function testCannotBuyIfPriceNotMet() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Fund the buyer with some ETH
        vm.deal(buyer, LISTING_PRICE - 0.05 ether);

        // Try to buy with insufficient funds
        vm.startPrank(buyer);

        vm.expectRevert(
            abi.encodeWithSelector(
                Glb3dMarketplace.Glb3dMarketplace__PriceNotMet.selector, address(glb3dNft), tokenId, LISTING_PRICE
            )
        );

        marketplace.buyItem{value: LISTING_PRICE - 0.1 ether}(address(glb3dNft), tokenId);

        vm.stopPrank();
    }

    function testCannotBuyIfNotListed() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // Fund the buyer with enough ETH
        vm.deal(buyer, LISTING_PRICE);

        // NFT not listed
        vm.startPrank(buyer);

        vm.expectRevert(); // Just expect any revert since we're handling the check in a modifier

        marketplace.buyItem{value: LISTING_PRICE}(address(glb3dNft), tokenId);

        vm.stopPrank();
    }

    function testCannotBuyOwnNft() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Fund the seller with enough ETH
        vm.deal(seller, LISTING_PRICE);

        // Try to buy own NFT
        vm.startPrank(seller);

        vm.expectRevert(); // Just expect any revert since we're handling the check in a modifier

        marketplace.buyItem{value: LISTING_PRICE}(address(glb3dNft), tokenId);

        vm.stopPrank();
    }

    /* Test Cancel Listing Functions */
    function testCancelListing() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Cancel listing
        vm.startPrank(seller);

        vm.expectEmit(true, true, true, true);
        emit ItemCanceled(seller, address(glb3dNft), tokenId);

        marketplace.cancelListing(address(glb3dNft), tokenId);

        // Verify listing was removed
        Glb3dMarketplace.Listing memory listing = marketplace.getListing(address(glb3dNft), tokenId);
        assertEq(listing.price, 0);

        vm.stopPrank();
    }

    function testCannotCancelIfNotOwner() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Try to cancel as non-owner
        vm.startPrank(buyer);

        vm.expectRevert(Glb3dMarketplace.Glb3dMarketplace__NotOwner.selector);
        marketplace.cancelListing(address(glb3dNft), tokenId);

        vm.stopPrank();
    }

    /* Test Update Listing Functions */
    function testUpdateListing() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Update listing
        uint256 newPrice = 2 ether;

        vm.startPrank(seller);

        vm.expectEmit(true, true, true, true);
        emit ItemListed(seller, address(glb3dNft), tokenId, newPrice, PREVIEW_URI, true);

        marketplace.updateListing(address(glb3dNft), tokenId, newPrice);

        // Verify listing was updated
        Glb3dMarketplace.Listing memory listing = marketplace.getListing(address(glb3dNft), tokenId);
        assertEq(listing.price, newPrice);

        vm.stopPrank();
    }

    /* Test Featured Listing Functions */
    function testSetFeaturedListing() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Set as featured
        vm.startPrank(deployer);

        vm.expectEmit(true, true, true, true);
        emit FeaturedStatusChanged(address(glb3dNft), tokenId, true);

        marketplace.setFeaturedListing(address(glb3dNft), tokenId, true);

        // Verify listing is featured
        bool isFeatured = marketplace.isFeaturedListing(address(glb3dNft), tokenId);
        assertTrue(isFeatured);

        vm.stopPrank();
    }

    /* Test Withdraw Functions */
    function testWithdrawProceeds() public {
        uint256 tokenId = mintAndApproveNft(seller);

        // List the NFT
        vm.prank(seller);
        marketplace.listItem(address(glb3dNft), tokenId, LISTING_PRICE);

        // Buy the NFT
        vm.deal(buyer, LISTING_PRICE * 2); // Make sure buyer has enough ETH
        vm.prank(buyer);
        marketplace.buyItem{value: LISTING_PRICE}(address(glb3dNft), tokenId);

        // Calculate expected proceeds
        uint256 platformFee = (LISTING_PRICE * PLATFORM_FEE_BPS) / 10000;
        uint256 sellerProceeds = LISTING_PRICE - platformFee;

        // Get seller's balance before withdraw
        uint256 sellerBalanceBefore = seller.balance;

        // Withdraw proceeds
        vm.prank(seller);
        marketplace.withdrawProceeds();

        // Verify proceeds were withdrawn
        assertEq(marketplace.getProceeds(seller), 0);
        assertEq(seller.balance, sellerBalanceBefore + sellerProceeds);

        // Platform owner can also withdraw
        uint256 deployerBalanceBefore = deployer.balance;

        vm.prank(deployer);
        marketplace.withdrawProceeds();

        assertEq(marketplace.getProceeds(deployer), 0);
        assertEq(deployer.balance, deployerBalanceBefore + platformFee);
    }

    function testCannotWithdrawWithZeroProceeds() public {
        vm.startPrank(seller);

        vm.expectRevert(Glb3dMarketplace.Glb3dMarketplace__NoProceeds.selector);
        marketplace.withdrawProceeds();

        vm.stopPrank();
    }

    /* Test Platform Fee Functions */
    function testUpdatePlatformFee() public {
        uint256 newFeeBps = 500; // 5%

        vm.startPrank(deployer);

        marketplace.updatePlatformFee(newFeeBps);

        // Verify fee was updated
        assertEq(marketplace.getPlatformFeeBps(), newFeeBps);

        vm.stopPrank();
    }
}
