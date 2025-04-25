//SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts//utils/ReentrancyGuard.sol";
import {Glb3dNft} from "./Glb3dNft.sol";

/**
 * @title 3D GLB NFT Marketplace
 * @author Akash Kolekar
 * @notice This is a specialized marketplace for 3D GLB format NFTs
 */
contract Glb3dMarketplace is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Glb3dMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
    error Glb3dMarketplace__PriceMustBeAboveZero();
    error Glb3dMarketplace__NotApprovedForMarketplace();
    error Glb3dMarketplace__NotOwner();
    error Glb3dMarketplace__AlreadyOwn(address nftAddress, uint256 tokenId, address spender);
    error Glb3dMarketplace__NotListed(address nftAddress, uint256 tokenId);
    error Glb3dMarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
    error Glb3dMarketplace__NoProceeds();
    error Glb3dMarketplace__TransferFailed();
    error Glb3dMarketplace__NotGlb3dNft();
    error Glb3dMarketplace__RoyaltyPaymentFailed();
    error Glb3dMarketplace__OfferTooLow();
    error Glb3dMarketplace__OfferNotFound();
    error Glb3dMarketplace__OfferExpired();
    error Glb3dMarketplace__NotOfferCreator();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    struct Listing {
        uint256 price;
        address seller;
        uint256 tokenId;
        address nftAddress;
        bool is3dGlb; // Flag to indicate if this is a 3D GLB NFT
        string previewUri; // Preview image for the 3D model
    }

    struct Offer {
        address buyer;
        uint256 offerPrice;
        uint256 expirationTime; // Unix timestamp when the offer expires
        bool isActive;
    }

    // Main listings mapping: nftAddress => tokenId => listing details
    mapping(address nftAddress => mapping(uint256 tokenId => Listing nftInfo)) private s_nftListings;

    // Proceeds mapping for sellers and creators
    mapping(address payee => uint256 amountEarned) private s_proceeds;

    // Featured 3D NFTs (curated list)
    mapping(uint256 listingId => bool isFeatured) private s_featuredListings;

    // Offers mapping: nftAddress => tokenId => buyer => offer details
    mapping(address nftAddress => mapping(uint256 tokenId => mapping(address buyer => Offer offerDetails))) private
        s_offers;

    // Track all offers for an NFT: nftAddress => tokenId => array of buyer addresses
    mapping(address nftAddress => mapping(uint256 tokenId => address[] offerCreators)) private s_offerCreators;

    // Listing counter for featured listings
    uint256 private s_listingCounter;

    // Platform fee in basis points (default 2.5%)
    uint256 private s_platformFeeBps = 250;

    // Minimum offer duration in seconds (1 day)
    uint256 private constant MIN_OFFER_DURATION = 86400;

    // Maximum offer duration in seconds (30 days)
    uint256 private constant MAX_OFFER_DURATION = 2592000;

    // Contract owner
    address private immutable i_owner;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
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
    event PlatformFeeUpdated(uint256 newFeeBps);
    event RoyaltyPaid(address indexed creator, uint256 indexed tokenId, uint256 amount);

    // Offer events
    event OfferCreated(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 offerPrice,
        uint256 expirationTime
    );

    event OfferCanceled(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId);

    event OfferAccepted(
        address indexed seller, address indexed buyer, address indexed nftAddress, uint256 tokenId, uint256 offerPrice
    );

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_nftListings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert Glb3dMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_nftListings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert Glb3dMarketplace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(address tokenAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(tokenAddress);
        if (nft.ownerOf(tokenId) != spender) {
            revert Glb3dMarketplace__NotOwner();
        }
        _;
    }

    modifier isNotOwner(address nftAddress, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);

        if (owner == spender) {
            revert Glb3dMarketplace__AlreadyOwn(nftAddress, tokenId, spender);
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not authorized");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        i_owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice List a 3D GLB NFT for sale
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
            revert Glb3dMarketplace__PriceMustBeAboveZero();
        }

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert Glb3dMarketplace__NotApprovedForMarketplace();
        }

        // Check if this is a GLB 3D NFT contract
        bool is3dGlb = isGlb3dNft(nftAddress);
        string memory previewUri = "";

        // If it's a GLB 3D NFT, get the preview URI using low-level call instead of try-catch
        if (is3dGlb) {
            Glb3dNft glbNft = Glb3dNft(nftAddress);

            // Use low-level call to get metadata
            (bool success, bytes memory returnData) =
                address(glbNft).staticcall(abi.encodeWithSelector(glbNft.getGlbMetadata.selector, tokenId));

            if (success && returnData.length > 0) {
                // Decode the return data to get the metadata
                Glb3dNft.GlbMetadata memory metadata = abi.decode(returnData, (Glb3dNft.GlbMetadata));
                previewUri = metadata.previewUri;
            }
            // If call fails, we'll continue with empty previewUri
        }

        s_listingCounter++;

        // Create and store the listing
        s_nftListings[nftAddress][tokenId] = Listing({
            price: price,
            seller: msg.sender,
            tokenId: tokenId,
            nftAddress: nftAddress,
            is3dGlb: is3dGlb,
            previewUri: previewUri
        });

        emit ItemListed(msg.sender, nftAddress, tokenId, price, previewUri, is3dGlb);
    }

    /**
     * @notice Buy a 3D NFT
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     */
    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        isNotOwner(nftAddress, tokenId, msg.sender)
        nonReentrant
    {
        Listing memory listedItem = s_nftListings[nftAddress][tokenId];

        if (msg.value < listedItem.price) {
            revert Glb3dMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price);
        }

        // Process proceeds distribution (royalties, platform fee, seller payment)
        (uint256 sellerProceeds, address creator, uint256 royaltyAmount) =
            _processProceeds(nftAddress, tokenId, listedItem);

        // Add remaining proceeds to seller
        s_proceeds[listedItem.seller] += sellerProceeds;

        // Remove listing
        delete s_nftListings[nftAddress][tokenId];

        // Transfer NFT to buyer
        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price, creator, royaltyAmount);
    }

    /**
     * @notice Process the distribution of proceeds from a sale
     * @param nftAddress The NFT contract address
     * @param tokenId The token ID being sold
     * @param listedItem The listing information
     * @return sellerProceeds The amount that goes to the seller
     * @return creator The creator address (for royalties)
     * @return royaltyAmount The amount paid as royalty
     */
    function _processProceeds(address nftAddress, uint256 tokenId, Listing memory listedItem)
        internal
        returns (uint256 sellerProceeds, address creator, uint256 royaltyAmount)
    {
        uint256 salePrice = listedItem.price;
        sellerProceeds = salePrice;
        creator = address(0);
        royaltyAmount = 0;

        // Handle royalties for 3D GLB NFTs
        if (listedItem.is3dGlb) {
            // Get creator address
            Glb3dNft glbNft = Glb3dNft(nftAddress);

            // Safe way to get creator without try-catch
            address potentialCreator;
            bool success;

            // Call getCreator manually without try-catch
            (success,) = address(glbNft).call(abi.encodeWithSelector(glbNft.getCreator.selector, tokenId));

            if (success) {
                // If we successfully got the creator
                potentialCreator = glbNft.getCreator(tokenId);
                creator = potentialCreator;

                // Get royalty percentage safely
                uint256 royaltyBps;
                (success,) = address(glbNft).call(abi.encodeWithSelector(glbNft.getRoyaltyBps.selector, tokenId));

                if (success) {
                    royaltyBps = glbNft.getRoyaltyBps(tokenId);
                    // Calculate royalty amount
                    royaltyAmount = (salePrice * royaltyBps) / 10000;

                    // If royalty is due, add to creator's proceeds
                    if (royaltyAmount > 0 && creator != listedItem.seller) {
                        s_proceeds[creator] += royaltyAmount;
                        sellerProceeds -= royaltyAmount;
                        emit RoyaltyPaid(creator, tokenId, royaltyAmount);
                    }
                }
            }
        }

        // Calculate platform fee
        uint256 platformFee = (salePrice * s_platformFeeBps) / 10000;
        sellerProceeds -= platformFee;

        // Add platform fee to owner's proceeds
        s_proceeds[i_owner] += platformFee;

        return (sellerProceeds, creator, royaltyAmount);
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
     * @notice Update listing price
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param newPrice The new price of the NFT in Wei
     */
    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice)
        external
        isListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (newPrice <= 0) {
            revert Glb3dMarketplace__PriceMustBeAboveZero();
        }

        s_nftListings[nftAddress][tokenId].price = newPrice;

        string memory previewUri = s_nftListings[nftAddress][tokenId].previewUri;
        bool is3dGlb = s_nftListings[nftAddress][tokenId].is3dGlb;

        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice, previewUri, is3dGlb);
    }

    /**
     * @notice Set a listing as featured (only owner)
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param isFeatured Whether the listing should be featured
     */
    function setFeaturedListing(address nftAddress, uint256 tokenId, bool isFeatured)
        external
        onlyOwner
        isListed(nftAddress, tokenId)
    {
        // Calculate a unique listing ID for the featured mapping
        uint256 listingId = uint256(keccak256(abi.encodePacked(nftAddress, tokenId)));
        s_featuredListings[listingId] = isFeatured;

        emit FeaturedStatusChanged(nftAddress, tokenId, isFeatured);
    }

    /**
     * @notice Update platform fee (only owner)
     * @param newFeeBps New platform fee in basis points (100 = 1%)
     */
    function updatePlatformFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 1000, "Fee too high"); // Max 10%
        s_platformFeeBps = newFeeBps;
        emit PlatformFeeUpdated(newFeeBps);
    }

    /**
     * @notice Withdraw proceeds
     * @dev Withdraw proceeds from sales
     */
    function withdrawProceeds() external nonReentrant {
        uint256 amount = s_proceeds[msg.sender];

        if (amount <= 0) {
            revert Glb3dMarketplace__NoProceeds();
        }

        s_proceeds[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert Glb3dMarketplace__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                       INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if an NFT contract is a GLB 3D NFT
     * @param nftAddress The address of the NFT contract to check
     * @return True if it's a GLB 3D NFT contract
     */
    function isGlb3dNft(address nftAddress) internal view returns (bool) {
        // Use low-level call instead of try-catch to check if this is a Glb3dNft
        (bool success, bytes memory returnData) =
            nftAddress.staticcall(abi.encodeWithSignature("getDefaultRoyaltyBps()"));

        // If the call was successful and we got a valid response, it's a Glb3dNft contract
        return success && returnData.length > 0;
    }

    /*//////////////////////////////////////////////////////////////
              PUBLIC AND EXTERNAL VIEW AND PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get a listing by NFT address and token ID
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @return The listing details
     */
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return s_nftListings[nftAddress][tokenId];
    }

    /**
     * @notice Get the proceeds available for withdrawal
     * @param seller The address to check proceeds for
     * @return Amount of proceeds available
     */
    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }

    /**
     * @notice Check if a listing is featured
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @return Whether the listing is featured
     */
    function isFeaturedListing(address nftAddress, uint256 tokenId) external view returns (bool) {
        uint256 listingId = uint256(keccak256(abi.encodePacked(nftAddress, tokenId)));
        return s_featuredListings[listingId];
    }

    /**
     * @notice Get the current platform fee
     * @return Platform fee in basis points
     */
    function getPlatformFeeBps() external view returns (uint256) {
        return s_platformFeeBps;
    }

    /**
     * @notice Get all active listings (for frontend pagination)
     * @param startIndex Where to start in the listings
     * @param count How many listings to return
     * @param onlyGlb Whether to only return GLB 3D NFTs
     * @param onlyFeatured Whether to only return featured listings
     * @return Array of listings
     */
    function getActiveListings(uint256 startIndex, uint256 count, bool onlyGlb, bool onlyFeatured)
        public
        view
        returns (Listing[] memory)
    {
        // First, count how many listings match our criteria
        uint256 totalMatchingListings = 0;
        uint256 totalScanned = 0;

        // We'll use a mapping to track which NFT contracts we've seen
        // This is a memory mapping that will only exist during this function call
        address[] memory seenContracts = new address[](100); // Assuming max 100 different contracts
        uint256 seenContractsCount = 0;

        // First pass: count matching listings
        for (uint256 i = 0; i < seenContractsCount; i++) {
            address nftAddress = seenContracts[i];

            // We need to iterate through all token IDs, but we don't have a direct way to do this
            // In a production environment, you would maintain an array of active listings
            // For this implementation, we'll limit our search to a reasonable range
            for (uint256 tokenId = 1; tokenId <= 1000; tokenId++) {
                Listing memory listing = s_nftListings[nftAddress][tokenId];

                // Skip if not listed (price = 0)
                if (listing.price == 0) continue;

                // Apply filters
                if (onlyGlb && !listing.is3dGlb) continue;

                if (onlyFeatured) {
                    uint256 listingId = uint256(keccak256(abi.encodePacked(nftAddress, tokenId)));
                    if (!s_featuredListings[listingId]) continue;
                }

                // This listing matches our criteria
                totalMatchingListings++;
            }
        }

        // If no matching listings or startIndex is beyond our range, return empty array
        if (totalMatchingListings == 0 || startIndex >= totalMatchingListings) {
            return new Listing[](0);
        }

        // Calculate how many items to return (might be less than count if we're near the end)
        uint256 itemsToReturn = count;
        if (startIndex + count > totalMatchingListings) {
            itemsToReturn = totalMatchingListings - startIndex;
        }

        // Create result array
        Listing[] memory results = new Listing[](itemsToReturn);
        uint256 resultIndex = 0;
        totalScanned = 0;

        // Second pass: collect matching listings
        for (uint256 i = 0; i < seenContractsCount && resultIndex < itemsToReturn; i++) {
            address nftAddress = seenContracts[i];

            for (uint256 tokenId = 1; tokenId <= 1000 && resultIndex < itemsToReturn; tokenId++) {
                Listing memory listing = s_nftListings[nftAddress][tokenId];

                // Skip if not listed
                if (listing.price == 0) continue;

                // Apply filters
                if (onlyGlb && !listing.is3dGlb) continue;

                if (onlyFeatured) {
                    uint256 listingId = uint256(keccak256(abi.encodePacked(nftAddress, tokenId)));
                    if (!s_featuredListings[listingId]) continue;
                }

                // This listing matches our criteria
                if (totalScanned >= startIndex) {
                    results[resultIndex] = listing;
                    resultIndex++;
                }

                totalScanned++;
            }
        }

        return results;
    }

    /**
     * @notice Get featured listings
     * @param count How many featured listings to return
     * @return Array of featured listings
     */
    function getFeaturedListings(uint256 count) external view returns (Listing[] memory) {
        return getActiveListings(0, count, false, true);
    }

    /**
     * @notice Get 3D GLB listings
     * @param count How many 3D GLB listings to return
     * @return Array of 3D GLB listings
     */
    function get3dGlbListings(uint256 count) external view returns (Listing[] memory) {
        return getActiveListings(0, count, true, false);
    }

    /*//////////////////////////////////////////////////////////////
                           OFFER SYSTEM FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create an offer for an NFT
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param offerDuration Duration of the offer in seconds
     */
    function createOffer(address nftAddress, uint256 tokenId, uint256 offerDuration)
        external
        payable
        isNotOwner(nftAddress, tokenId, msg.sender)
    {
        // Ensure offer price is greater than zero
        if (msg.value <= 0) {
            revert Glb3dMarketplace__PriceMustBeAboveZero();
        }

        // Validate offer duration
        if (offerDuration < MIN_OFFER_DURATION || offerDuration > MAX_OFFER_DURATION) {
            offerDuration = MIN_OFFER_DURATION; // Default to minimum if invalid
        }

        // Calculate expiration time
        uint256 expirationTime = block.timestamp + offerDuration;

        // Create or update the offer
        Offer memory existingOffer = s_offers[nftAddress][tokenId][msg.sender];

        // If there's an existing active offer, add the new value to it
        if (existingOffer.isActive) {
            // Extend the expiration time
            expirationTime = block.timestamp + offerDuration;

            // Update the offer with the new price and expiration
            s_offers[nftAddress][tokenId][msg.sender] = Offer({
                buyer: msg.sender,
                offerPrice: existingOffer.offerPrice + msg.value,
                expirationTime: expirationTime,
                isActive: true
            });
        } else {
            // Create a new offer
            s_offers[nftAddress][tokenId][msg.sender] =
                Offer({buyer: msg.sender, offerPrice: msg.value, expirationTime: expirationTime, isActive: true});

            // Add buyer to the list of offer creators for this NFT
            s_offerCreators[nftAddress][tokenId].push(msg.sender);
        }

        emit OfferCreated(msg.sender, nftAddress, tokenId, msg.value, expirationTime);
    }

    /**
     * @notice Cancel an offer and withdraw funds
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     */
    function cancelOffer(address nftAddress, uint256 tokenId) external nonReentrant {
        Offer memory offer = s_offers[nftAddress][tokenId][msg.sender];

        // Check if offer exists and is active
        if (!offer.isActive) {
            revert Glb3dMarketplace__OfferNotFound();
        }

        // Check if caller is the offer creator
        if (offer.buyer != msg.sender) {
            revert Glb3dMarketplace__NotOfferCreator();
        }

        // Get the offer amount
        uint256 offerAmount = offer.offerPrice;

        // Mark offer as inactive
        s_offers[nftAddress][tokenId][msg.sender].isActive = false;

        // Return funds to the buyer
        (bool success,) = payable(msg.sender).call{value: offerAmount}("");
        if (!success) {
            revert Glb3dMarketplace__TransferFailed();
        }

        emit OfferCanceled(msg.sender, nftAddress, tokenId);
    }

    /**
     * @notice Accept an offer for an NFT
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param buyer The address of the buyer who made the offer
     */
    function acceptOffer(address nftAddress, uint256 tokenId, address buyer)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        nonReentrant
    {
        Offer memory offer = s_offers[nftAddress][tokenId][buyer];

        // Check if offer exists and is active
        if (!offer.isActive) {
            revert Glb3dMarketplace__OfferNotFound();
        }

        // Check if offer has expired
        if (block.timestamp > offer.expirationTime) {
            revert Glb3dMarketplace__OfferExpired();
        }

        // Get the offer amount
        uint256 offerAmount = offer.offerPrice;

        // Mark offer as inactive
        s_offers[nftAddress][tokenId][buyer].isActive = false;

        // Process proceeds distribution (royalties, platform fee, seller payment)
        bool is3dGlb = isGlb3dNft(nftAddress);
        address creator = address(0);
        uint256 royaltyAmount = 0;
        uint256 sellerProceeds = offerAmount;

        // Handle royalties for 3D GLB NFTs
        if (is3dGlb) {
            Glb3dNft glbNft = Glb3dNft(nftAddress);

            // Safe way to get creator without try-catch
            bool success;

            // Call getCreator manually without try-catch
            (success,) = address(glbNft).call(abi.encodeWithSelector(glbNft.getCreator.selector, tokenId));

            if (success) {
                // If we successfully got the creator
                creator = glbNft.getCreator(tokenId);

                // Get royalty percentage safely
                (success,) = address(glbNft).call(abi.encodeWithSelector(glbNft.getRoyaltyBps.selector, tokenId));

                if (success) {
                    uint256 royaltyBps = glbNft.getRoyaltyBps(tokenId);
                    // Calculate royalty amount
                    royaltyAmount = (offerAmount * royaltyBps) / 10000;

                    // If royalty is due, add to creator's proceeds
                    if (royaltyAmount > 0 && creator != msg.sender) {
                        s_proceeds[creator] += royaltyAmount;
                        sellerProceeds -= royaltyAmount;
                        emit RoyaltyPaid(creator, tokenId, royaltyAmount);
                    }
                }
            }
        }

        // Calculate platform fee
        uint256 platformFee = (offerAmount * s_platformFeeBps) / 10000;
        sellerProceeds -= platformFee;

        // Add platform fee to owner's proceeds
        s_proceeds[i_owner] += platformFee;

        // Add remaining proceeds to seller
        s_proceeds[msg.sender] += sellerProceeds;

        // Transfer NFT to buyer
        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(msg.sender, buyer, tokenId);

        // If the NFT was listed, remove the listing
        if (s_nftListings[nftAddress][tokenId].price > 0) {
            delete s_nftListings[nftAddress][tokenId];
        }

        // Cancel all other offers for this NFT
        _cancelAllOtherOffers(nftAddress, tokenId, buyer);

        emit OfferAccepted(msg.sender, buyer, nftAddress, tokenId, offerAmount);
    }

    /**
     * @notice Get all active offers for an NFT
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @return offerCreators Array of addresses that have made offers
     * @return offerPrices Array of offer prices
     * @return expirationTimes Array of expiration times
     */
    function getOffers(address nftAddress, uint256 tokenId)
        external
        view
        returns (address[] memory offerCreators, uint256[] memory offerPrices, uint256[] memory expirationTimes)
    {
        address[] memory creators = s_offerCreators[nftAddress][tokenId];
        uint256 activeOfferCount = 0;

        // First, count active offers
        for (uint256 i = 0; i < creators.length; i++) {
            Offer memory offer = s_offers[nftAddress][tokenId][creators[i]];
            if (offer.isActive && block.timestamp <= offer.expirationTime) {
                activeOfferCount++;
            }
        }

        // Initialize return arrays
        offerCreators = new address[](activeOfferCount);
        offerPrices = new uint256[](activeOfferCount);
        expirationTimes = new uint256[](activeOfferCount);

        // Fill return arrays with active offers
        uint256 index = 0;
        for (uint256 i = 0; i < creators.length && index < activeOfferCount; i++) {
            Offer memory offer = s_offers[nftAddress][tokenId][creators[i]];
            if (offer.isActive && block.timestamp <= offer.expirationTime) {
                offerCreators[index] = creators[i];
                offerPrices[index] = offer.offerPrice;
                expirationTimes[index] = offer.expirationTime;
                index++;
            }
        }

        return (offerCreators, offerPrices, expirationTimes);
    }

    /**
     * @notice Get a specific offer for an NFT
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param buyer The address of the buyer who made the offer
     * @return offer The offer details
     */
    function getOffer(address nftAddress, uint256 tokenId, address buyer) external view returns (Offer memory) {
        return s_offers[nftAddress][tokenId][buyer];
    }

    /**
     * @notice Internal function to cancel all other offers when an offer is accepted
     * @param nftAddress The address of the NFT contract
     * @param tokenId The token ID of the NFT
     * @param acceptedBuyer The address of the buyer whose offer was accepted
     */
    function _cancelAllOtherOffers(address nftAddress, uint256 tokenId, address acceptedBuyer) internal {
        address[] memory creators = s_offerCreators[nftAddress][tokenId];

        for (uint256 i = 0; i < creators.length; i++) {
            address buyer = creators[i];

            // Skip the accepted buyer
            if (buyer == acceptedBuyer) {
                continue;
            }

            Offer memory offer = s_offers[nftAddress][tokenId][buyer];

            // Only refund active offers
            if (offer.isActive) {
                // Mark as inactive
                s_offers[nftAddress][tokenId][buyer].isActive = false;

                // Refund the buyer
                (bool success,) = payable(buyer).call{value: offer.offerPrice}("");
                if (!success) {
                    // If refund fails, add to their proceeds instead
                    s_proceeds[buyer] += offer.offerPrice;
                }

                emit OfferCanceled(buyer, nftAddress, tokenId);
            }
        }
    }
}
