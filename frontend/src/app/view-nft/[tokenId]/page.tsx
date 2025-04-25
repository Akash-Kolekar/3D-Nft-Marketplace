'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { useReadContract } from 'wagmi';
import GlbViewer from '../../../components/GlbViewer';
import Link from 'next/link';
import { contractAddresses } from '../../../contracts/contractAddresses';
import Glb3dNftAbi from '../../../contracts/Glb3dNft.json';

interface NftMetadata {
  glbUri: string;
  previewUri: string;
  name: string;
  description: string;
  creator: string;
}

export default function ViewNftPage() {
  const params = useParams();
  const tokenId = params.tokenId as string;
  const [metadata, setMetadata] = useState<NftMetadata | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  // Get the contract address for Anvil local chain
  const chainId = 31337; // Anvil local chain ID
  const nftAddress = contractAddresses[chainId]?.glb3dNft;

  // For demo purposes, we'll use mock data
  const glbUri = 'https://gateway.pinata.cloud/ipfs/bafybeigkbibx7rlmvzjsism2x4sjt2ziblpk66wvi4hm343syraudwvcr4';
  const previewUri = 'https://gateway.pinata.cloud/ipfs/bafkreicdas32m2xygbt5jsbrsac5mkksgom25cfpl223imhhctz2aml7um';
  const name = `3D Model #${tokenId}`;
  const description = `This is a 3D GLB model NFT with ID ${tokenId}`;
  const creator = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'; // First Anvil account

  // Error states
  const isGlbUriError = false;
  const isPreviewUriError = false;
  const isNameError = false;
  const isDescriptionError = false;
  const isCreatorError = false;

  // Fetch NFT metadata from the contract
  useEffect(() => {
    const fetchMetadata = async () => {
      try {
        setIsLoading(true);
        setError('');

        // Check if any of the contract reads failed
        if (isGlbUriError || isPreviewUriError || isNameError || isDescriptionError || isCreatorError) {
          setError('Error fetching NFT metadata from the contract');
          setIsLoading(false);
          return;
        }

        // Check if we have all the data
        if (glbUri && previewUri && name && description && creator) {
          setMetadata({
            glbUri: glbUri as string,
            previewUri: previewUri as string,
            name: name as string,
            description: description as string,
            creator: creator as string
          });
          setIsLoading(false);
        }
      } catch (err) {
        console.error('Error fetching NFT metadata:', err);
        setError('Error fetching NFT metadata. Please try again.');
        setIsLoading(false);
      }
    };

    fetchMetadata();
  }, [tokenId, glbUri, previewUri, name, description, creator, isGlbUriError, isPreviewUriError, isNameError, isDescriptionError, isCreatorError]);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <Link href="/my-nfts" className="text-blue-600 hover:text-blue-800 flex items-center">
          <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clipRule="evenodd" />
          </svg>
          Back to My NFTs
        </Link>
      </div>

      {isLoading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      ) : error ? (
        <div className="text-center p-8 bg-red-50 rounded-lg">
          <h2 className="text-xl font-semibold mb-4 text-red-700">Error</h2>
          <p className="mb-4 text-red-600">{error}</p>
          <Link href="/my-nfts" className="text-blue-600 hover:text-blue-800">
            Go back to My NFTs
          </Link>
        </div>
      ) : metadata ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="h-[500px]">
              <GlbViewer glbUri={metadata.glbUri} autoRotate={true} />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6">
            <h1 className="text-3xl font-bold mb-4">{metadata.name}</h1>
            <p className="text-gray-600 mb-6">{metadata.description}</p>

            <div className="space-y-4">
              <div>
                <h2 className="text-sm font-medium text-gray-500">Token ID</h2>
                <p className="mt-1 text-lg font-medium">{tokenId}</p>
              </div>

              <div>
                <h2 className="text-sm font-medium text-gray-500">Creator</h2>
                <p className="mt-1 text-lg font-medium">
                  {metadata.creator.substring(0, 6)}...{metadata.creator.substring(metadata.creator.length - 4)}
                </p>
              </div>

              <div>
                <h2 className="text-sm font-medium text-gray-500">GLB URI</h2>
                <p className="mt-1 text-sm text-gray-600 break-all">{metadata.glbUri}</p>
              </div>

              <div className="pt-4">
                <h2 className="text-lg font-semibold mb-2">Controls</h2>
                <ul className="list-disc list-inside text-sm text-gray-600">
                  <li>Left click + drag: Rotate model</li>
                  <li>Right click + drag: Pan</li>
                  <li>Scroll: Zoom in/out</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="text-center p-8 bg-gray-100 rounded-lg">
          <h2 className="text-xl font-semibold mb-4">NFT Not Found</h2>
          <p className="mb-4">The NFT you're looking for doesn't exist or you don't have permission to view it.</p>
          <Link href="/my-nfts" className="text-blue-600 hover:text-blue-800">
            Go back to My NFTs
          </Link>
        </div>
      )}
    </div>
  );
}
