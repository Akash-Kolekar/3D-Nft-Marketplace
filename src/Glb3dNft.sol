//SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title 3D GLB NFT Contract
 * @author Akash Kolekar
 * @notice This contract enables minting and management of 3D model NFTs in GLB format
 * @dev Implements ERC721 with URI storage, ERC2981 for royalties, and custom metadata for 3D models
 */
contract Glb3dNft is ERC721URIStorage, ERC2981, Ownable {
    // Replace Counters with a simple uint256 counter
    uint256 private s_tokenIdCounter;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Glb3dNft__InvalidGlbUri();
    error Glb3dNft__InvalidPreviewUri();
    error Glb3dNft__TokenDoesNotExist();
    error Glb3dNft__NotAuthorized();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    struct GlbMetadata {
        string glbUri; // URI to the GLB file
        string previewUri; // URI to a preview image/thumbnail
        string name; // Name of the 3D model
        string description; // Description of the 3D model
        address creator; // Original creator of the 3D model
    }

    // Mapping from tokenId to 3D metadata
    mapping(uint256 => GlbMetadata) private s_glbMetadata;

    // Mapping for creator royalties (in basis points - 100 = 1%)
    mapping(uint256 => uint256) private s_royaltyBps;

    // Default royalty in basis points (10%)
    uint256 private s_defaultRoyaltyBps = 1000;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Glb3dNftMinted(uint256 indexed tokenId, address indexed creator, string glbUri, string previewUri);
    event RoyaltyUpdated(uint256 indexed tokenId, uint256 royaltyBps);
    event MetadataUpdated(uint256 indexed tokenId, string glbUri, string previewUri);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC721("3D GLB NFT", "GLB3D") Ownable(msg.sender) {
        // Set default royalty receiver to contract creator with default royalty
        _setDefaultRoyalty(msg.sender, uint96(s_defaultRoyaltyBps));
    }

    /**
     * @notice Override supportsInterface to handle ERC2981
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint a new 3D NFT with GLB file
     * @param glbUri URI to the GLB file (IPFS recommended)
     * @param previewUri URI to a preview image
     * @param name Name of the 3D model
     * @param description Description of the 3D model
     * @param royaltyBps Royalty in basis points (100 = 1%)
     * @return tokenId The ID of the newly minted token
     */
    function mintGlb3dNft(
        string memory glbUri,
        string memory previewUri,
        string memory name,
        string memory description,
        uint256 royaltyBps
    ) external returns (uint256) {
        if (bytes(glbUri).length == 0) {
            revert Glb3dNft__InvalidGlbUri();
        }
        if (bytes(previewUri).length == 0) {
            revert Glb3dNft__InvalidPreviewUri();
        }

        // Increment counter directly
        s_tokenIdCounter++;
        uint256 tokenId = s_tokenIdCounter;

        // Store 3D metadata
        s_glbMetadata[tokenId] = GlbMetadata({
            glbUri: glbUri,
            previewUri: previewUri,
            name: name,
            description: description,
            creator: msg.sender
        });

        // Set royalty if specified, otherwise use default
        uint256 finalRoyaltyBps = royaltyBps > 0 ? royaltyBps : s_defaultRoyaltyBps;
        s_royaltyBps[tokenId] = finalRoyaltyBps;

        // Set ERC2981 royalty info for this token
        _setTokenRoyalty(tokenId, msg.sender, uint96(finalRoyaltyBps));

        // Generate token URI JSON metadata and mint the token
        string memory tokenURI = generateTokenURI(tokenId);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit Glb3dNftMinted(tokenId, msg.sender, glbUri, previewUri);
        return tokenId;
    }

    /**
     * @notice Batch mint multiple 3D NFTs with GLB files
     * @param glbUris Array of URIs to the GLB files
     * @param previewUris Array of URIs to preview images
     * @param names Array of names for the 3D models
     * @param descriptions Array of descriptions for the 3D models
     * @param royaltyBpsArray Array of royalty percentages in basis points
     * @return tokenIds Array of the newly minted token IDs
     */
    function batchMintGlb3dNft(
        string[] memory glbUris,
        string[] memory previewUris,
        string[] memory names,
        string[] memory descriptions,
        uint256[] memory royaltyBpsArray
    ) external returns (uint256[] memory) {
        // Check array lengths match
        uint256 batchSize = glbUris.length;
        require(
            previewUris.length == batchSize && names.length == batchSize && descriptions.length == batchSize
                && royaltyBpsArray.length == batchSize,
            "Array lengths must match"
        );

        uint256[] memory tokenIds = new uint256[](batchSize);

        for (uint256 i = 0; i < batchSize; i++) {
            // Validate URIs
            if (bytes(glbUris[i]).length == 0) {
                revert Glb3dNft__InvalidGlbUri();
            }
            if (bytes(previewUris[i]).length == 0) {
                revert Glb3dNft__InvalidPreviewUri();
            }

            // Increment counter
            s_tokenIdCounter++;
            uint256 tokenId = s_tokenIdCounter;
            tokenIds[i] = tokenId;

            // Store metadata
            s_glbMetadata[tokenId] = GlbMetadata({
                glbUri: glbUris[i],
                previewUri: previewUris[i],
                name: names[i],
                description: descriptions[i],
                creator: msg.sender
            });

            // Set royalty
            uint256 finalRoyaltyBps = royaltyBpsArray[i] > 0 ? royaltyBpsArray[i] : s_defaultRoyaltyBps;
            s_royaltyBps[tokenId] = finalRoyaltyBps;
            _setTokenRoyalty(tokenId, msg.sender, uint96(finalRoyaltyBps));

            // Generate token URI and mint
            string memory tokenURI = generateTokenURI(tokenId);
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, tokenURI);

            emit Glb3dNftMinted(tokenId, msg.sender, glbUris[i], previewUris[i]);
        }

        return tokenIds;
    }

    /**
     * @notice Update the GLB file and preview URI for an existing token
     * @param tokenId Token ID to update
     * @param newGlbUri New GLB file URI
     * @param newPreviewUri New preview image URI
     */
    function updateGlbMetadata(uint256 tokenId, string memory newGlbUri, string memory newPreviewUri) external {
        if (!_tokenExists(tokenId)) {
            revert Glb3dNft__TokenDoesNotExist();
        }

        // Only creator or owner can update metadata
        if (s_glbMetadata[tokenId].creator != msg.sender && ownerOf(tokenId) != msg.sender) {
            revert Glb3dNft__NotAuthorized();
        }

        if (bytes(newGlbUri).length > 0) {
            s_glbMetadata[tokenId].glbUri = newGlbUri;
        }

        if (bytes(newPreviewUri).length > 0) {
            s_glbMetadata[tokenId].previewUri = newPreviewUri;
        }

        // Update token URI
        string memory tokenURI = generateTokenURI(tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit MetadataUpdated(tokenId, newGlbUri, newPreviewUri);
    }

    /**
     * @notice Set the default royalty for new tokens
     * @param royaltyBps New default royalty in basis points
     */
    function setDefaultRoyalty(uint256 royaltyBps) external onlyOwner {
        s_defaultRoyaltyBps = royaltyBps;
        _setDefaultRoyalty(owner(), uint96(royaltyBps));
    }

    /**
     * @notice Update royalty for a specific token (only creator can do this)
     * @param tokenId Token ID to update
     * @param royaltyBps New royalty in basis points
     */
    function updateRoyalty(uint256 tokenId, uint256 royaltyBps) external {
        if (!_tokenExists(tokenId)) {
            revert Glb3dNft__TokenDoesNotExist();
        }

        if (s_glbMetadata[tokenId].creator != msg.sender) {
            revert Glb3dNft__NotAuthorized();
        }

        // Update both our custom mapping and ERC2981
        s_royaltyBps[tokenId] = royaltyBps;
        _setTokenRoyalty(tokenId, s_glbMetadata[tokenId].creator, uint96(royaltyBps));

        emit RoyaltyUpdated(tokenId, royaltyBps);
    }

    /*//////////////////////////////////////////////////////////////
                      INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generate the token URI JSON metadata
     * @param tokenId Token ID to generate URI for
     * @return Full token URI JSON string
     */
    function generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        GlbMetadata memory metadata = s_glbMetadata[tokenId];

        // Create JSON metadata string
        string memory json = string(
            abi.encodePacked(
                '{"name":"',
                metadata.name,
                '", "description":"',
                metadata.description,
                '", "image":"',
                metadata.previewUri,
                '", "animation_url":"',
                metadata.glbUri,
                '", "attributes": [{"trait_type": "Creator", "value": "',
                addressToString(metadata.creator),
                '"}, {"trait_type": "Model Type", "value": "3D GLB"}]}'
            )
        );

        // Base64 encode the JSON string and return as data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @notice Helper function to convert an address to a string
     */
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @notice Check if a token exists
     * @param tokenId Token ID to check
     * @return True if the token exists
     */
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        // We'll check if the tokenId is within range and has been minted
        if (tokenId == 0 || tokenId > s_tokenIdCounter) {
            return false;
        }

        // Use a low-level call to check if ownerOf reverts
        bool success;
        bytes memory returnData;

        // Use a low-level call to check if ownerOf reverts
        (success, returnData) = address(this).staticcall(abi.encodeWithSignature("ownerOf(uint256)", tokenId));

        return success && returnData.length > 0;
    }

    /*//////////////////////////////////////////////////////////////
              PUBLIC AND EXTERNAL VIEW AND PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the GLB metadata for a token
     * @param tokenId Token ID to query
     * @return GLB metadata struct
     */
    function getGlbMetadata(uint256 tokenId) external view returns (GlbMetadata memory) {
        if (!_tokenExists(tokenId)) {
            revert Glb3dNft__TokenDoesNotExist();
        }
        return s_glbMetadata[tokenId];
    }

    /**
     * @notice Get the royalty percentage for a token
     * @param tokenId Token ID to query
     * @return Royalty in basis points
     */
    function getRoyaltyBps(uint256 tokenId) external view returns (uint256) {
        if (!_tokenExists(tokenId)) {
            revert Glb3dNft__TokenDoesNotExist();
        }
        return s_royaltyBps[tokenId];
    }

    /**
     * @notice Get the default royalty percentage
     * @return Default royalty in basis points
     */
    function getDefaultRoyaltyBps() external view returns (uint256) {
        return s_defaultRoyaltyBps;
    }

    /**
     * @notice Get the creator of a token
     * @param tokenId Token ID to query
     * @return Creator address
     */
    function getCreator(uint256 tokenId) external view returns (address) {
        if (!_tokenExists(tokenId)) {
            revert Glb3dNft__TokenDoesNotExist();
        }
        return s_glbMetadata[tokenId].creator;
    }

    /**
     * @notice Get the total supply of tokens
     * @return Current token count
     */
    function getTotalSupply() external view returns (uint256) {
        return s_tokenIdCounter;
    }
}
