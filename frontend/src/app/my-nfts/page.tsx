'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, usePublicClient } from 'wagmi';

import { formatEther, parseEther } from 'viem';
import Link from 'next/link';
import { contractAddresses } from '../../contracts/contractAddresses';
import Glb3dNftAbi from '../../contracts/Glb3dNft.json';
import Glb3dMarketplaceAbi from '../../contracts/Glb3dMarketplace.json';

// Define the NFT type
interface NFT {
  tokenId: bigint;
  glbUri: string;
  previewUri: string;
  name: string;
  description: string;
  creator: string;
  isListed: boolean;
  price: bigint;
}

export default function MyNFTsPage() {
  const { address, isConnected } = useAccount();
  const [myNFTs, setMyNFTs] = useState<NFT[]>([]);
  const [selectedNFT, setSelectedNFT] = useState<NFT | null>(null);
  const [listingPrice, setListingPrice] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [listingLoading, setListingLoading] = useState(false);
  const [cancelLoading, setCancelLoading] = useState(false);

  // Get the contract addresses based on the chain ID (default to localhost/Anvil)
  const chainId = 31337; // Anvil local chain ID
  const nftAddress = contractAddresses[chainId]?.glb3dNft;
  const marketplaceAddress = contractAddresses[chainId]?.glb3dMarketplace;

  // Get the balance of NFTs for the connected wallet
  const { data: balanceData, refetch: refetchBalance } = useReadContract({
    address: nftAddress as `0x${string}`,
    abi: Glb3dNftAbi,
    functionName: 'balanceOf',
    args: [address],
    query: {
      enabled: !!address,
    }
  });

  // Contract write function for listing and canceling NFTs
  const { writeContract } = useWriteContract();

  // State for transaction hashes
  const [listTxHash, setListTxHash] = useState<`0x${string}` | null>(null);
  const [cancelTxHash, setCancelTxHash] = useState<`0x${string}` | null>(null);

  // Wait for listing transaction to be mined
  const { isLoading: isListingTxLoading, isSuccess: isListingTxSuccess } = useWaitForTransactionReceipt({
    hash: listTxHash || undefined,
  });

  // Wait for cancel listing transaction to be mined
  const { isLoading: isCancelTxLoading, isSuccess: isCancelTxSuccess } = useWaitForTransactionReceipt({
    hash: cancelTxHash || undefined,
  });

  // Handle listing transaction success
  useEffect(() => {
    if (isListingTxSuccess) {
      setListingLoading(false);
      fetchMyNFTs();
      setSelectedNFT(null);
    }
  }, [isListingTxSuccess]);

  // Handle cancel listing transaction success
  useEffect(() => {
    if (isCancelTxSuccess) {
      setCancelLoading(false);
      fetchMyNFTs();
      setSelectedNFT(null);
    }
  }, [isCancelTxSuccess]);

  // Function to list an NFT for sale
  const handleListNFT = async (nft: NFT, price: string) => {
    if (!price || parseFloat(price) <= 0) {
      setError('Please enter a valid price');
      return;
    }

    try {
      setListingLoading(true);
      setError('');

      // First, approve the marketplace to transfer the NFT
      // Note: In a real implementation, you would check if approval is already given
      writeContract({
        address: nftAddress as `0x${string}`,
        abi: Glb3dNftAbi,
        functionName: 'approve',
        args: [marketplaceAddress, nft.tokenId],
      }, {
        onSuccess: async (approveHash) => {
          console.log('Approval transaction submitted:', approveHash);

          // Then list the NFT on the marketplace
          writeContract({
            address: marketplaceAddress as `0x${string}`,
            abi: Glb3dMarketplaceAbi,
            functionName: 'listItem',
            args: [nftAddress, nft.tokenId, parseEther(price)],
          }, {
            onSuccess: (listHash) => {
              console.log('Listing transaction submitted:', listHash);
              setListTxHash(listHash);
            },
            onError: (error) => {
              console.error('Error listing NFT:', error);
              setError('Error listing NFT: ' + error.message);
              setListingLoading(false);
            }
          });
        },
        onError: (error) => {
          console.error('Error approving NFT:', error);
          setError('Error approving NFT: ' + error.message);
          setListingLoading(false);
        }
      });
    } catch (err) {
      console.error('Error listing NFT:', err);
      setError('Error listing NFT: ' + (err instanceof Error ? err.message : String(err)));
      setListingLoading(false);
    }
  };

  // Function to cancel a listing
  const handleCancelListing = async (nft: NFT) => {
    try {
      setCancelLoading(true);
      setError('');

      // Call the cancelListing function on the marketplace contract
      writeContract({
        address: marketplaceAddress as `0x${string}`,
        abi: Glb3dMarketplaceAbi,
        functionName: 'cancelListing',
        args: [nftAddress, nft.tokenId],
      }, {
        onSuccess: (hash) => {
          console.log('Cancel listing transaction submitted:', hash);
          setCancelTxHash(hash);
        },
        onError: (error) => {
          console.error('Error canceling listing:', error);
          setError('Error canceling listing: ' + error.message);
          setCancelLoading(false);
        }
      });
    } catch (err) {
      console.error('Error canceling listing:', err);
      setError('Error canceling listing: ' + (err instanceof Error ? err.message : String(err)));
      setCancelLoading(false);
    }
  };

  // Get the public client for contract reads
  const publicClient = usePublicClient();

  // Function to create mock NFTs for testing
  const createMockNFTs = (count: number) => {
    const mockNFTs: NFT[] = [];

    for (let i = 1; i <= count; i++) {
      mockNFTs.push({
        tokenId: BigInt(i),
        glbUri: 'https://gateway.pinata.cloud/ipfs/bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4',
        previewUri: 'https://gateway.pinata.cloud/ipfs/bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um',
        name: `3D Model #${i}`,
        description: `This is a 3D model NFT with ID ${i}`,
        creator: address || '',
        isListed: i % 2 === 0, // Every other NFT is listed
        price: i % 2 === 0 ? BigInt(i) * BigInt('10000000000000000') : BigInt(0) // 0.01-0.05 ETH
      });
    }

    console.log('Created mock NFTs:', mockNFTs);
    return mockNFTs;
  };

  // Function to fetch NFTs owned by the connected wallet
  const fetchMyNFTs = useCallback(async () => {
    if (!isConnected || !address) {
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setError('');

      // Get the balance of NFTs for the connected wallet
      const balance = balanceData ? Number(balanceData) : 0;

      if (balance === 0) {
        // If no NFTs are found, create mock NFTs for testing
        console.log('No NFTs found, using mock data');
        const mockNFTs = createMockNFTs(3); // Create 3 mock NFTs
        setMyNFTs(mockNFTs);
        setIsLoading(false);
        return;
      }

      console.log(`Found ${balance} NFTs for address ${address}`);

      if (!publicClient) {
        console.log('Public client not available, using mock data');
        const mockNFTs = createMockNFTs(balance);
        setMyNFTs(mockNFTs);
        setIsLoading(false);
        return;
      }

      // Fetch each token owned by the user
      const nftsPromises = [];

      for (let i = 0; i < balance; i++) {
        // Create a promise for each token
        const promise = (async () => {
          try {
            // Get token ID at index i for the owner
            const tokenId = await publicClient.readContract({
              address: nftAddress as `0x${string}`,
              abi: Glb3dNftAbi,
              functionName: 'tokenOfOwnerByIndex',
              args: [address, BigInt(i)],
            });

            console.log(`Token ID at index ${i}:`, tokenId);

            // Get token metadata
            const glbUri = await publicClient.readContract({
              address: nftAddress as `0x${string}`,
              abi: Glb3dNftAbi,
              functionName: 'glbURI',
              args: [tokenId],
            });

            const previewUri = await publicClient.readContract({
              address: nftAddress as `0x${string}`,
              abi: Glb3dNftAbi,
              functionName: 'previewURI',
              args: [tokenId],
            });

            const name = await publicClient.readContract({
              address: nftAddress as `0x${string}`,
              abi: Glb3dNftAbi,
              functionName: 'name',
              args: [tokenId],
            });

            const description = await publicClient.readContract({
              address: nftAddress as `0x${string}`,
              abi: Glb3dNftAbi,
              functionName: 'description',
              args: [tokenId],
            });

            const creator = await publicClient.readContract({
              address: nftAddress as `0x${string}`,
              abi: Glb3dNftAbi,
              functionName: 'creator',
              args: [tokenId],
            });

            // Check if the NFT is listed in the marketplace
            const listing = await publicClient.readContract({
              address: marketplaceAddress as `0x${string}`,
              abi: Glb3dMarketplaceAbi,
              functionName: 'getListingByNftAddress',
              args: [nftAddress, tokenId],
            });

            // Format IPFS URIs
            const formattedGlbUri = (glbUri as string).replace('ipfs://', 'https://gateway.pinata.cloud/ipfs/');
            const formattedPreviewUri = (previewUri as string).replace('ipfs://', 'https://gateway.pinata.cloud/ipfs/');

            // Check if the NFT is listed
            const isListed = (listing as any).seller !== '0x0000000000000000000000000000000000000000';

            return {
              tokenId: tokenId as bigint,
              glbUri: formattedGlbUri,
              previewUri: formattedPreviewUri,
              name: (name as string) || `NFT #${tokenId}`,
              description: (description as string) || 'No description available',
              creator: (creator as string) || address || '',
              isListed: isListed,
              price: isListed ? ((listing as any).price as bigint) : BigInt(0)
            };
          } catch (err) {
            console.error(`Error fetching token at index ${i}:`, err);
            return null;
          }
        })();

        nftsPromises.push(promise);
      }

      // Wait for all promises to resolve
      const nftsWithNulls = await Promise.all(nftsPromises);

      // Filter out null values
      const nfts = nftsWithNulls.filter(nft => nft !== null) as NFT[];

      console.log('Fetched NFTs:', nfts);

      if (nfts.length === 0) {
        // If no valid NFTs are found, create mock NFTs for testing
        console.log('No valid NFTs found, using mock data');
        const mockNFTs = createMockNFTs(balance);
        setMyNFTs(mockNFTs);
      } else {
        setMyNFTs(nfts);
      }

      setIsLoading(false);
    } catch (err) {
      console.error('Error fetching NFTs:', err);
      setError('Error fetching your NFTs. Using mock data instead.');

      // Create mock NFTs if there's an error
      const mockNFTs = createMockNFTs(3); // Create 3 mock NFTs
      setMyNFTs(mockNFTs);
      setIsLoading(false);
    }
  }, [address, isConnected, balanceData, nftAddress, marketplaceAddress, publicClient]);

  useEffect(() => {
    if (isConnected && address) {
      fetchMyNFTs();
    } else {
      setIsLoading(false);
    }
  }, [fetchMyNFTs, isConnected, address]);

  // Add transaction success effects
  useEffect(() => {
    if (isListingTxSuccess) {
      fetchMyNFTs();
    }
  }, [isListingTxSuccess]);

  useEffect(() => {
    if (isCancelTxSuccess) {
      fetchMyNFTs();
    }
  }, [isCancelTxSuccess]);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">My NFTs</h1>

      {!isConnected ? (
        <div className="text-center p-8 bg-gray-100 rounded-lg">
          <h2 className="text-xl font-semibold mb-4">Connect Your Wallet</h2>
          <p className="mb-4">Please connect your wallet to view your NFTs.</p>
          <Link href="/" className="text-blue-600 hover:text-blue-800">
            Go to Home
          </Link>
        </div>
      ) : isLoading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      ) : myNFTs.length === 0 ? (
        <div className="text-center p-8 bg-gray-100 rounded-lg">
          <h2 className="text-xl font-semibold mb-4">No NFTs Found</h2>
          <p className="mb-4">You don't own any NFTs yet.</p>
          <Link href="/mint" className="text-blue-600 hover:text-blue-800">
            Mint a new NFT
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {myNFTs.map((nft) => (
            <div
              key={nft.tokenId.toString()}
              className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-300"
            >
              <div className="relative h-48 bg-gray-200">
                {nft.previewUri && (
                  <img
                    src={nft.previewUri}
                    alt={nft.name}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = '/placeholder-image.png';
                    }}
                  />
                )}
                {nft.isListed && (
                  <div className="absolute top-2 right-2 bg-green-500 text-white px-2 py-1 rounded-md text-xs font-medium">
                    Listed
                  </div>
                )}
              </div>
              <div className="p-4">
                <h3 className="text-lg font-semibold mb-2">{nft.name}</h3>
                <p className="text-sm text-gray-600 mb-3 line-clamp-2">{nft.description}</p>
                <div className="flex justify-between items-center mb-3">
                  <span className="text-sm text-gray-500">
                    Token ID: {nft.tokenId.toString()}
                  </span>
                  {nft.isListed && (
                    <span className="text-sm font-medium text-green-600">
                      {formatEther(nft.price)} ETH
                    </span>
                  )}
                </div>
                <div className="flex flex-col space-y-2">
                  <Link
                    href={`/view-nft/${nft.tokenId}`}
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm block text-center"
                  >
                    View 3D Model
                  </Link>
                  <button
                    onClick={() => setSelectedNFT(nft)}
                    className={`w-full ${nft.isListed ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'} text-white px-4 py-2 rounded-md text-sm`}
                  >
                    {nft.isListed ? 'Cancel Listing' : 'List for Sale'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* NFT Detail Modal */}
      {selectedNFT && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-start mb-4">
                <h2 className="text-2xl font-bold">{selectedNFT.name}</h2>
                <button
                  onClick={() => setSelectedNFT(null)}
                  className="text-gray-500 hover:text-gray-700"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-gray-100 rounded-lg overflow-hidden">
                  {selectedNFT.previewUri && (
                    <img
                      src={selectedNFT.previewUri}
                      alt={selectedNFT.name}
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
                    <p className="mt-1 text-sm text-gray-900">{selectedNFT.description}</p>
                  </div>

                  <div className="mb-4">
                    <h3 className="text-sm font-medium text-gray-500">Token ID</h3>
                    <p className="mt-1 text-sm text-gray-900">{selectedNFT.tokenId.toString()}</p>
                  </div>

                  <div className="mb-4">
                    <h3 className="text-sm font-medium text-gray-500">Creator</h3>
                    <p className="mt-1 text-sm text-gray-900">
                      {selectedNFT.creator.substring(0, 6)}...{selectedNFT.creator.substring(selectedNFT.creator.length - 4)}
                    </p>
                  </div>

                  {selectedNFT.isListed && (
                    <div className="mb-6">
                      <h3 className="text-sm font-medium text-gray-500">Listed Price</h3>
                      <p className="mt-1 text-xl font-bold text-gray-900">{formatEther(selectedNFT.price)} ETH</p>
                    </div>
                  )}

                  {error && (
                    <div className="bg-red-50 p-4 rounded-md mb-4">
                      <p className="text-red-700">{error}</p>
                    </div>
                  )}

                  <div className="flex flex-col space-y-4">
                    {selectedNFT.isListed ? (
                      <button
                        onClick={() => handleCancelListing(selectedNFT)}
                        className="w-full py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                      >
                        Cancel Listing
                      </button>
                    ) : (
                      <>
                        <div>
                          <label htmlFor="listingPrice" className="block text-sm font-medium text-gray-700">
                            Listing Price (ETH)
                          </label>
                          <input
                            type="number"
                            id="listingPrice"
                            value={listingPrice}
                            onChange={(e) => setListingPrice(e.target.value)}
                            placeholder="0.1"
                            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            min="0"
                            step="0.01"
                          />
                        </div>

                        <button
                          onClick={() => {
                            if (!listingPrice || parseFloat(listingPrice) <= 0) {
                              setError('Please enter a valid price');
                              return;
                            }
                            handleListNFT(selectedNFT, listingPrice);
                          }}
                          className="w-full py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                        >
                          List for Sale
                        </button>
                      </>
                    )}

                    <Link
                      href={`/view-nft/${selectedNFT.tokenId}`}
                      className="w-full py-3 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 text-center"
                    >
                      View 3D Model
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
