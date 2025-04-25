//SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts//utils/ReentrancyGuard.sol";

/**
 * @title Nft Marketplace
 * @author Akash Kolekar
 * @notice This is a nft marketplace contract where user can trade nft with other users.
 *
 */
contract NftMarketplace is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
    error NftMarketplace__PriceMustBeAboveZero();
    error NftMarketplace__NotApprovedForMarketplace();
    error NftMarketplace__NotOwner();
    error NftMarketplace__AlreadyOwn(address nftAddress, uint256 tokenId, address spender);
    error NftMarketplace__NotListded(address nftAddress, uint256 tokenId);
    error NftMarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
    error NftMarketplace__NoProceeds();
    error NftMarketplace__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address nftAddress => mapping(uint256 tokenId => Listing nftInfo)) private s_nftListings;
    mapping(address seller => uint256 amountEarned) private s_proceeds;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event ItemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ItemCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_nftListings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_nftListings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace__NotListded(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(address tokenAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(tokenAddress);
        if (nft.ownerOf(tokenId) != spender) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    modifier isNotOwner(address nftAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);

        if (owner == spender) {
            revert NftMarketplace__AlreadyOwn(nftAddress, tokenId, spender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice List an NFT for sale
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param price The sale price of the NFT
     */
    function listItem(address nftAddress, uint256 tokenId, uint256 price)
        external
        notListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }

        s_nftListings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /**
     * @notice Buy an NFT
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     */
    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        isNotOwner(nftAddress, tokenId, msg.sender)
    {
        Listing memory listedItem = s_nftListings[nftAddress][tokenId];

        if (msg.value < listedItem.price) {
            revert NftMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price);
        }

        s_proceeds[listedItem.seller] += msg.value;
        delete s_nftListings[nftAddress][tokenId];

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    /**
     * @notice Cancel a listing
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     */
    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete s_nftListings[nftAddress][tokenId];
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    /**
     *
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param newPrice The new price of the NFT in Wei
     */
    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice)
        external
        isListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        s_nftListings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    /**
     * @notice Withdraw proceeds
     * @dev Withdraw proceeds from sales
     */
    function withdrawProceeds() external nonReentrant {
        uint256 amount = s_proceeds[msg.sender];

        if (amount <= 0) {
            revert NftMarketplace__NoProceeds();
        }

        s_proceeds[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert NftMarketplace__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
              PUBLIC AND EXTERNAL VIEW AND PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return s_nftListings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
