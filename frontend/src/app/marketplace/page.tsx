'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt, usePublicClient } from 'wagmi';
import { formatEther, parseEther } from 'viem';
import { contractAddresses } from '../../contracts/contractAddresses';
import Glb3dMarketplaceAbi from '../../contracts/Glb3dMarketplace.json';
import Glb3dNftAbi from '../../contracts/Glb3dNft.json';
import Link from 'next/link';

// Define the Listing type based on the contract
interface Listing {
  price: bigint;
  seller: string;
  tokenId: bigint;
  nftAddress: string;
  is3dGlb: boolean;
  previewUri: string;
}

// Define the NFT metadata type
interface NftMetadata {
  name: string;
  description: string;
  glbUri: string;
  previewUri: string;
  creator: string;
}

export default function MarketplacePage() {
  const { address, isConnected } = useAccount();
  const [activeListings, setActiveListings] = useState<Listing[]>([]);
  const [selectedListing, setSelectedListing] = useState<Listing | null>(null);
  const [nftMetadata, setNftMetadata] = useState<Record<string, NftMetadata>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [purchaseSuccess, setPurchaseSuccess] = useState(false);
  const [purchaseLoading, setPurchaseLoading] = useState(false);
  const [offerAmount, setOfferAmount] = useState('');
  const [offerDuration, setOfferDuration] = useState(86400); // 1 day in seconds

  // Get the contract addresses based on the chain ID (default to localhost/Anvil)
  const chainId = 31337; // Anvil local chain ID
  const marketplaceAddress = contractAddresses[chainId]?.glb3dMarketplace;
  const nftAddress = contractAddresses[chainId]?.glb3dNft;

  // Get the public client for contract reads
  const publicClient = usePublicClient();

  // Function to fetch active listings from the marketplace
  const refetchListings = async () => {
    if (!publicClient) return;

    console.log('Fetching active listings...');
    setIsLoading(true);

    try {
      // Call the getActiveListings function on the marketplace contract
      const listings = await publicClient.readContract({
        address: marketplaceAddress as `0x${string}`,
        abi: Glb3dMarketplaceAbi,
        functionName: 'getActiveListings',
        args: [0, 100, false, false], // Start index, count, onlyGlb, onlyFeatured
      }) as Listing[];

      console.log('Fetched listings:', listings);

      if (listings && listings.length > 0) {
        setActiveListings(listings);

        // Fetch metadata for each listing
        fetchNftMetadata(listings);
      } else {
        console.log('No active listings found, using mock data');
        // Use mock data if no listings are found
        createMockListings();
      }
    } catch (err) {
      console.error('Error fetching listings:', err);
      // Use mock data if there's an error
      createMockListings();
    }
  };

  // Function to create mock listings for testing
  const createMockListings = () => {
    const mockListings: Listing[] = [];

    for (let i = 1; i <= 5; i++) {
      mockListings.push({
        price: BigInt(i) * BigInt('10000000000000000'), // 0.01-0.05 ETH
        seller: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', // First Anvil account
        tokenId: BigInt(i),
        nftAddress: nftAddress as string,
        is3dGlb: true,
        previewUri: 'https://gateway.pinata.cloud/ipfs/bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um'
      });
    }

    console.log('Created mock listings:', mockListings);
    setActiveListings(mockListings);

    // Create mock metadata for each listing
    const metadataMap: Record<string, NftMetadata> = {};

    mockListings.forEach((listing) => {
      metadataMap[listing.tokenId.toString()] = {
        name: `3D Model #${listing.tokenId.toString()}`,
        description: `This is a 3D GLB model NFT with ID ${listing.tokenId.toString()}`,
        glbUri: 'https://gateway.pinata.cloud/ipfs/bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4',
        previewUri: listing.previewUri,
        creator: listing.seller
      };
    });

    setNftMetadata(metadataMap);
    setIsLoading(false);
  };

  // Contract write function for buying an NFT and making offers
  const { writeContract } = useWriteContract();

  // State for transaction hashes
  const [buyTxHash, setBuyTxHash] = useState<`0x${string}` | null>(null);
  const [offerTxHash, setOfferTxHash] = useState<`0x${string}` | null>(null);

  // Wait for buy transaction to be mined
  const { isLoading: isBuyTxLoading, isSuccess: isBuyTxSuccess } = useWaitForTransactionReceipt({
    hash: buyTxHash || undefined,
  });

  // Wait for offer transaction to be mined
  const { isLoading: isOfferTxLoading, isSuccess: isOfferTxSuccess } = useWaitForTransactionReceipt({
    hash: offerTxHash || undefined,
  });

  // Function to fetch NFT metadata for each listing
  const fetchNftMetadata = async (listings: Listing[]) => {
    if (!publicClient) return;

    try {
      const metadataMap: Record<string, NftMetadata> = {};

      // Process each listing to get metadata
      const metadataPromises = listings.map(async (listing) => {
        try {
          // Get token metadata from the NFT contract
          const glbUri = await publicClient.readContract({
            address: nftAddress as `0x${string}`,
            abi: Glb3dNftAbi,
            functionName: 'glbURI',
            args: [listing.tokenId],
          });

          const name = await publicClient.readContract({
            address: nftAddress as `0x${string}`,
            abi: Glb3dNftAbi,
            functionName: 'name',
            args: [listing.tokenId],
          });

          const description = await publicClient.readContract({
            address: nftAddress as `0x${string}`,
            abi: Glb3dNftAbi,
            functionName: 'description',
            args: [listing.tokenId],
          });

          const creator = await publicClient.readContract({
            address: nftAddress as `0x${string}`,
            abi: Glb3dNftAbi,
            functionName: 'creator',
            args: [listing.tokenId],
          });

          // Format IPFS URIs
          const formattedGlbUri = (glbUri as string).replace('ipfs://', 'https://gateway.pinata.cloud/ipfs/');
          const formattedPreviewUri = listing.previewUri.replace('ipfs://', 'https://gateway.pinata.cloud/ipfs/');

          return {
            tokenId: listing.tokenId.toString(),
            metadata: {
              name: (name as string) || `NFT #${listing.tokenId}`,
              description: (description as string) || 'No description available',
              glbUri: formattedGlbUri,
              previewUri: formattedPreviewUri,
              creator: (creator as string) || listing.seller
            }
          };
        } catch (err) {
          console.error(`Error fetching metadata for token ${listing.tokenId}:`, err);
          return {
            tokenId: listing.tokenId.toString(),
            metadata: {
              name: `NFT #${listing.tokenId}`,
              description: 'Metadata unavailable',
              glbUri: 'https://gateway.pinata.cloud/ipfs/bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4',
              previewUri: listing.previewUri,
              creator: listing.seller
            }
          };
        }
      });

      const metadataResults = await Promise.all(metadataPromises);

      // Create metadata map
      metadataResults.forEach(({ tokenId, metadata }) => {
        metadataMap[tokenId] = metadata;
      });

      console.log('Fetched metadata:', metadataMap);
      setNftMetadata(metadataMap);
      setIsLoading(false);
    } catch (err) {
      console.error('Error fetching NFT metadata:', err);
      setIsLoading(false);
    }
  };

  // Fetch listings when component mounts
  useEffect(() => {
    if (publicClient) {
      refetchListings();
    }
  }, [publicClient]);

  // Add transaction success effects
  useEffect(() => {
    if (isBuyTxSuccess) {
      setPurchaseSuccess(true);
      refetchListings();
      setPurchaseLoading(false);
    }
  }, [isBuyTxSuccess, refetchListings]);

  useEffect(() => {
    if (isOfferTxSuccess) {
      setOfferAmount('');
      refetchListings();
      setError('');
      alert('Offer made successfully!');
      setPurchaseLoading(false);
    }
  }, [isOfferTxSuccess, refetchListings]);

  // Handle buying an NFT
  const handleBuyNft = async () => {
    if (!isConnected) {
      setError('Please connect your wallet first');
      return;
    }

    if (!selectedListing) {
      setError('No NFT selected');
      return;
    }

    try {
      setPurchaseLoading(true);
      setError('');

      // Call the buyItem function on the marketplace contract
      writeContract({
        address: marketplaceAddress as `0x${string}`,
        abi: Glb3dMarketplaceAbi,
        functionName: 'buyItem',
        args: [selectedListing.nftAddress, selectedListing.tokenId],
        value: selectedListing.price
      }, {
        onSuccess: (hash) => {
          console.log('Buy transaction submitted:', hash);
          setBuyTxHash(hash);
        },
        onError: (error) => {
          console.error('Error buying NFT:', error);
          setError('Error buying NFT: ' + error.message);
          setPurchaseLoading(false);
        }
      });
    } catch (err) {
      console.error('Error buying NFT:', err);
      setError('Error buying NFT: ' + (err instanceof Error ? err.message : String(err)));
      setPurchaseLoading(false);
    }
  };

  // Handle making an offer on an NFT
  const handleMakeOffer = async () => {
    if (!isConnected) {
      setError('Please connect your wallet first');
      return;
    }

    if (!selectedListing) {
      setError('No NFT selected');
      return;
    }

    if (!offerAmount || parseFloat(offerAmount) <= 0) {
      setError('Please enter a valid offer amount');
      return;
    }

    try {
      setPurchaseLoading(true);
      setError('');

      // Call the createOffer function on the marketplace contract
      writeContract({
        address: marketplaceAddress as `0x${string}`,
        abi: Glb3dMarketplaceAbi,
        functionName: 'createOffer',
        args: [selectedListing.nftAddress, selectedListing.tokenId, BigInt(offerDuration)],
        value: parseEther(offerAmount)
      }, {
        onSuccess: (hash) => {
          console.log('Offer transaction submitted:', hash);
          setOfferTxHash(hash);
        },
        onError: (error) => {
          console.error('Error making offer:', error);
          setError('Error making offer: ' + error.message);
          setPurchaseLoading(false);
        }
      });
    } catch (err) {
      console.error('Error making offer:', err);
      setError('Error making offer: ' + (err instanceof Error ? err.message : String(err)));
      setPurchaseLoading(false);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">NFT Marketplace</h1>

      {isLoading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      ) : activeListings.length === 0 ? (
        <div className="text-center p-8 bg-gray-100 rounded-lg">
          <h2 className="text-xl font-semibold mb-4">No NFTs Listed</h2>
          <p className="mb-4">There are currently no NFTs listed in the marketplace.</p>
          <Link href="/mint" className="text-blue-600 hover:text-blue-800">
            Mint a new NFT
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {activeListings.map((listing) => (
            <div
              key={`${listing.nftAddress}-${listing.tokenId.toString()}`}
              className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-300"
            >
              <div className="relative h-48 bg-gray-200">
                {listing.previewUri && (
                  <img
                    src={listing.previewUri.replace('ipfs://', 'https://ipfs.io/ipfs/')}
                    alt={nftMetadata[listing.tokenId.toString()]?.name || `NFT #${listing.tokenId}`}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = '/placeholder-image.png';
                    }}
                  />
                )}
              </div>
              <div className="p-4">
                <h3 className="text-lg font-semibold mb-2">
                  {nftMetadata[listing.tokenId.toString()]?.name || `NFT #${listing.tokenId}`}
                </h3>
                <p className="text-sm text-gray-600 mb-3 line-clamp-2">
                  {nftMetadata[listing.tokenId.toString()]?.description || 'No description available'}
                </p>
                <div className="flex justify-between items-center mb-3">
                  <span className="text-sm text-gray-500">
                    Token ID: {listing.tokenId.toString()}
                  </span>
                  <span className="text-sm text-gray-500">
                    {listing.is3dGlb ? '3D GLB' : 'NFT'}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="font-bold text-lg">
                    {formatEther(listing.price)} ETH
                  </span>
                  <div className="flex space-x-2">
                    <Link
                      href={`/view-nft/${listing.tokenId}`}
                      className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm"
                    >
                      View 3D Model
                    </Link>
                    <button
                      onClick={() => setSelectedListing(listing)}
                      className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm"
                    >
                      Buy / Offer
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* NFT Detail Modal */}
      {selectedListing && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-start mb-4">
                <h2 className="text-2xl font-bold">
                  {nftMetadata[selectedListing.tokenId.toString()]?.name || `NFT #${selectedListing.tokenId}`}
                </h2>
                <button
                  onClick={() => {
                    setSelectedListing(null);
                    setError('');
                    setPurchaseSuccess(false);
                  }}
                  className="text-gray-500 hover:text-gray-700"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-gray-100 rounded-lg overflow-hidden">
                  {selectedListing.previewUri && (
                    <img
                      src={selectedListing.previewUri.replace('ipfs://', 'https://ipfs.io/ipfs/')}
                      alt={nftMetadata[selectedListing.tokenId.toString()]?.name || `NFT #${selectedListing.tokenId}`}
                      className="w-full h-full object-contain"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src = '/placeholder-image.png';
                      }}
                    />
                  )}
                </div>

                <div>
                  <div className="mb-4">
                    <h3 className="text-sm font-medium text-gray-500">Description</h3>
                    <p className="mt-1 text-sm text-gray-900">
                      {nftMetadata[selectedListing.tokenId.toString()]?.description || 'No description available'}
                    </p>
                  </div>

                  <div className="mb-4">
                    <h3 className="text-sm font-medium text-gray-500">Token ID</h3>
                    <p className="mt-1 text-sm text-gray-900">{selectedListing.tokenId.toString()}</p>
                  </div>

                  <div className="mb-4">
                    <h3 className="text-sm font-medium text-gray-500">Seller</h3>
                    <p className="mt-1 text-sm text-gray-900">
                      {selectedListing.seller.substring(0, 6)}...{selectedListing.seller.substring(selectedListing.seller.length - 4)}
                    </p>
                  </div>

                  <div className="mb-4">
                    <h3 className="text-sm font-medium text-gray-500">Creator</h3>
                    <p className="mt-1 text-sm text-gray-900">
                      {nftMetadata[selectedListing.tokenId.toString()]?.creator
                        ? `${nftMetadata[selectedListing.tokenId.toString()]?.creator.substring(0, 6)}...${nftMetadata[selectedListing.tokenId.toString()]?.creator.substring(nftMetadata[selectedListing.tokenId.toString()]?.creator.length - 4)}`
                        : 'Unknown'
                      }
                    </p>
                  </div>

                  <div className="mb-6">
                    <h3 className="text-sm font-medium text-gray-500">Price</h3>
                    <p className="mt-1 text-xl font-bold text-gray-900">{formatEther(selectedListing.price)} ETH</p>
                  </div>

                  {purchaseSuccess ? (
                    <div className="bg-green-50 p-4 rounded-md mb-4">
                      <p className="text-green-700 font-medium">NFT purchased successfully!</p>
                      <p className="text-sm text-green-600 mt-1">The NFT has been transferred to your wallet.</p>
                    </div>
                  ) : (
                    <>
                      {error && (
                        <div className="bg-red-50 p-4 rounded-md mb-4">
                          <p className="text-red-700">{error}</p>
                        </div>
                      )}

                      <div className="flex flex-col space-y-4">
                        <button
                          onClick={handleBuyNft}
                          disabled={purchaseLoading || selectedListing.seller === address}
                          className={`w-full py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 ${
                            (purchaseLoading || selectedListing.seller === address) && 'opacity-50 cursor-not-allowed'
                          }`}
                        >
                          {purchaseLoading ? 'Processing...' : 'Buy Now'}
                        </button>

                        <div className="relative">
                          <div className="absolute inset-0 flex items-center">
                            <div className="w-full border-t border-gray-300"></div>
                          </div>
                          <div className="relative flex justify-center text-sm">
                            <span className="px-2 bg-white text-gray-500">Or make an offer</span>
                          </div>
                        </div>

                        <div className="flex space-x-2">
                          <input
                            type="number"
                            value={offerAmount}
                            onChange={(e) => setOfferAmount(e.target.value)}
                            placeholder="ETH Amount"
                            className="flex-1 px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            min="0"
                            step="0.01"
                          />
                          <button
                            onClick={handleMakeOffer}
                            disabled={purchaseLoading || !offerAmount || parseFloat(offerAmount) <= 0 || selectedListing.seller === address}
                            className={`py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 ${
                              (purchaseLoading || !offerAmount || parseFloat(offerAmount) <= 0 || selectedListing.seller === address) && 'opacity-50 cursor-not-allowed'
                            }`}
                          >
                            {purchaseLoading ? 'Processing...' : 'Make Offer'}
                          </button>
                        </div>

                        <select
                          value={offerDuration}
                          onChange={(e) => setOfferDuration(parseInt(e.target.value))}
                          className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                        >
                          <option value="86400">1 Day</option>
                          <option value="259200">3 Days</option>
                          <option value="604800">1 Week</option>
                          <option value="2592000">30 Days</option>
                        </select>
                      </div>
                    </>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
