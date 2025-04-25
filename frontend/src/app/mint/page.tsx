'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import Link from 'next/link';
import { contractAddresses } from '../../contracts/contractAddresses';
import Glb3dNftAbi from '../../contracts/Glb3dNft.json';

export default function MintPage() {
  const { address, isConnected } = useAccount();
  const [glbUri, setGlbUri] = useState('');
  const [previewUri, setPreviewUri] = useState('');
  const [glbFile, setGlbFile] = useState<File | null>(null);
  const [previewFile, setPreviewFile] = useState<File | null>(null);
  const [previewDataUrl, setPreviewDataUrl] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [royaltyBps, setRoyaltyBps] = useState(1000); // Default 10%
  const [isLoading, setIsLoading] = useState(false);
  const [mintedTokenId, setMintedTokenId] = useState<number | null>(null);
  const [error, setError] = useState('');
  const [isSuccess, setIsSuccess] = useState(false);
  const [txHash, setTxHash] = useState<`0x${string}` | null>(null);

  // Get the contract address for Anvil local chain
  const chainId = 31337; // Anvil local chain ID
  const nftAddress = contractAddresses[chainId]?.glb3dNft;

  // Contract write function for minting an NFT
  const { writeContract } = useWriteContract();

  // Wait for transaction to be mined
  const { isLoading: isWaitingForTx, isSuccess: isTxSuccess, data: txReceipt } = useWaitForTransactionReceipt({
    hash: txHash || undefined,
  });

  // Handle transaction success
  useEffect(() => {
    if (isTxSuccess && txReceipt) {
      try {
        // Extract the token ID from the transaction receipt
        if (txReceipt.logs && txReceipt.logs.length > 0) {
          // The Glb3dNftMinted event has the token ID as the first indexed parameter
          const tokenIdHex = txReceipt.logs[0].topics?.[1];
          if (tokenIdHex) {
            const tokenId = parseInt(tokenIdHex, 16);
            setMintedTokenId(tokenId);
          }
        }
        setIsSuccess(true);
        setIsLoading(false);
      } catch (err) {
        console.error('Error parsing token ID from logs:', err);
        setIsSuccess(true);
        setIsLoading(false);
      }
    }
  }, [isTxSuccess, txReceipt]);

  // Handle preview image file selection
  const handlePreviewFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setPreviewFile(file);

      // Create a data URL for preview
      const reader = new FileReader();
      reader.onload = () => {
        setPreviewDataUrl(reader.result as string);
      };
      reader.readAsDataURL(file);

      // For demo purposes, we'll use a direct URL
      // In a production app, you would upload to IPFS
      setPreviewUri(`https://threejs.org/examples/screenshots/webgl_animation_keyframes.jpg`);
    }
  };

  // Handle GLB file selection
  const handleGlbFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setGlbFile(file);

      // For demo purposes, we'll use a sample GLB URL
      // In a production app, you would upload to IPFS
      setGlbUri(`https://gateway.pinata.cloud/ipfs/bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4`);
    }
  };

  // Function to mint an NFT
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    if (!isConnected) {
      setError('Please connect your wallet first');
      setIsLoading(false);
      return;
    }

    if (!glbFile || !previewFile || !name || !description) {
      setError('Please upload all files and fill in all fields');
      setIsLoading(false);
      return;
    }

    try {
      // Call the mintGlb3dNft function on the contract
      writeContract({
        address: contractAddresses[chainId]?.glb3dNft as `0x${string}`,
        abi: Glb3dNftAbi,
        functionName: 'mintGlb3dNft',
        args: [glbUri, previewUri, name, description, BigInt(royaltyBps)],
      }, {
        onSuccess(hash) {
          // Save the transaction hash
          setTxHash(hash);

          console.log('Minting transaction submitted:', {
            hash,
            name,
            description,
            glbUri,
            previewUri,
            royaltyBps,
            owner: address
          });
        },
        onError(error) {
          console.error('Error minting NFT:', error);
          setError('Error minting NFT: ' + error.message);
          setIsLoading(false);
        }
      });
    } catch (err) {
      console.error('Error minting NFT:', err);
      setError('Error minting NFT: ' + (err instanceof Error ? err.message : String(err)));
      setIsLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 className="text-3xl font-bold mb-6">Mint a 3D GLB NFT</h1>

      {!isConnected ? (
        <div className="text-center p-6 bg-gray-100 rounded-lg">
          <p className="mb-4">Please connect your wallet to mint NFTs</p>
          <Link href="/" className="text-blue-600 hover:text-blue-800">
            Go back to home
          </Link>
        </div>
      ) : isSuccess && mintedTokenId ? (
        <div className="text-center p-6 bg-green-50 rounded-lg">
          <h2 className="text-2xl font-bold text-green-600 mb-2">NFT Minted Successfully!</h2>
          <p className="mb-4">Your NFT has been minted with Token ID: {mintedTokenId}</p>
          <div className="flex justify-center space-x-4">
            <Link
              href={`/my-nfts`}
              className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            >
              View My NFTs
            </Link>
            <button
              onClick={() => {
                setGlbUri('');
                setPreviewUri('');
                setGlbFile(null);
                setPreviewFile(null);
                setPreviewDataUrl(null);
                setName('');
                setDescription('');
                setRoyaltyBps(1000);
                setMintedTokenId(null);
                setIsSuccess(false);
              }}
              className="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-2 px-4 rounded"
            >
              Mint Another
            </button>
          </div>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="glbFile" className="block text-sm font-medium text-gray-700">
              Upload GLB File
            </label>
            <div className="mt-1 flex items-center">
              <input
                type="file"
                id="glbFile"
                accept=".glb"
                onChange={handleGlbFileChange}
                className="sr-only"

              />
              <label
                htmlFor="glbFile"
                className="cursor-pointer bg-white py-2 px-3 border border-gray-300 rounded-md shadow-sm text-sm leading-4 font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Choose GLB File
              </label>
              <span className="ml-3 text-sm text-gray-500">
                {glbFile ? glbFile.name : 'No file chosen'}
              </span>
            </div>
            {glbUri && (
              <div className="mt-2">
                <p className="text-sm text-gray-500">IPFS URI: {glbUri}</p>
              </div>
            )}
          </div>

          <div>
            <label htmlFor="previewFile" className="block text-sm font-medium text-gray-700">
              Upload Preview Image
            </label>
            <div className="mt-1 flex items-center">
              <input
                type="file"
                id="previewFile"
                accept="image/*"
                onChange={handlePreviewFileChange}
                className="sr-only"

              />
              <label
                htmlFor="previewFile"
                className="cursor-pointer bg-white py-2 px-3 border border-gray-300 rounded-md shadow-sm text-sm leading-4 font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Choose Image
              </label>
              <span className="ml-3 text-sm text-gray-500">
                {previewFile ? previewFile.name : 'No file chosen'}
              </span>
            </div>
            {previewDataUrl && (
              <div className="mt-2">
                <div className="w-32 h-32 relative border border-gray-300 rounded-md overflow-hidden">
                  <img
                    src={previewDataUrl}
                    alt="Preview"
                    className="w-full h-full object-cover"
                  />
                </div>
                <p className="mt-1 text-sm text-gray-500">IPFS URI: {previewUri}</p>
              </div>
            )}
          </div>

          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700">
              NFT Name
            </label>
            <input
              type="text"
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="My Awesome 3D Model"
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700">
              Description
            </label>
            <textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Describe your 3D model..."
              rows={3}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="royaltyBps" className="block text-sm font-medium text-gray-700">
              Royalty Percentage (in basis points, 100 = 1%)
            </label>
            <input
              type="number"
              id="royaltyBps"
              value={royaltyBps}
              onChange={(e) => setRoyaltyBps(parseInt(e.target.value))}
              min="0"
              max="5000"
              step="100"
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
            />
            <p className="mt-1 text-xs text-gray-500">
              Current royalty: {royaltyBps / 100}%
            </p>
          </div>

          {error && (
            <div className="p-3 bg-red-50 text-red-700 rounded-md">
              {error}
            </div>
          )}

          <div className="flex justify-end">
            <button
              type="submit"
              disabled={isLoading}
              className={`px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 ${
                isLoading && 'opacity-50 cursor-not-allowed'
              }`}
            >
              {isLoading ? 'Minting...' : 'Mint NFT'}
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
