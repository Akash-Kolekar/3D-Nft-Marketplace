'use client';

import Image from "next/image";
import Link from "next/link";
import { ClientOnly } from './client-components';
import dynamic from 'next/dynamic';

// Dynamically import the HomeWalletConnect component to avoid hydration issues
const HomeWalletConnect = dynamic(() => import('@/components/HomeWalletConnect'), {
  ssr: false,
});

export default function Home() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[70vh] p-8">
      <div className="text-center mb-12">
        <h1 className="text-4xl font-bold mb-4">Welcome to 3D GLB NFT Marketplace</h1>
        <p className="text-xl text-gray-600 mb-8">
          Discover, collect, and trade unique 3D NFTs in GLB format
        </p>

        <ClientOnly>
          <HomeWalletConnect />
        </ClientOnly>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 w-full max-w-6xl">
        <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition duration-300">
          <h2 className="text-2xl font-bold mb-4 text-blue-600">Mint 3D NFTs</h2>
          <p className="text-gray-600 mb-4">Create and mint your own 3D GLB format NFTs with customizable royalties.</p>
          <Link href="/mint" className="text-blue-600 hover:text-blue-800 font-medium">
            Start Minting →
          </Link>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition duration-300">
          <h2 className="text-2xl font-bold mb-4 text-blue-600">Browse Marketplace</h2>
          <p className="text-gray-600 mb-4">Explore and purchase 3D NFTs from creators around the world.</p>
          <Link href="/marketplace" className="text-blue-600 hover:text-blue-800 font-medium">
            Explore NFTs →
          </Link>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition duration-300">
          <h2 className="text-2xl font-bold mb-4 text-blue-600">Manage Collection</h2>
          <p className="text-gray-600 mb-4">View, list, and manage your 3D NFT collection.</p>
          <Link href="/my-nfts" className="text-blue-600 hover:text-blue-800 font-medium">
            My Collection →
          </Link>
        </div>
      </div>

      <div className="mt-16 text-center">
        <h2 className="text-2xl font-bold mb-4">Why 3D GLB NFTs?</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto">
          <div className="bg-white p-5 rounded-lg shadow-sm">
            <h3 className="text-lg font-semibold mb-2">Immersive Experiences</h3>
            <p className="text-gray-600">3D models provide a more engaging and interactive experience than traditional 2D NFTs.</p>
          </div>
          <div className="bg-white p-5 rounded-lg shadow-sm">
            <h3 className="text-lg font-semibold mb-2">Metaverse Ready</h3>
            <p className="text-gray-600">GLB format is compatible with most metaverse platforms and AR/VR applications.</p>
          </div>
          <div className="bg-white p-5 rounded-lg shadow-sm">
            <h3 className="text-lg font-semibold mb-2">Creator Royalties</h3>
            <p className="text-gray-600">Earn royalties on secondary sales with our ERC2981 implementation.</p>
          </div>
          <div className="bg-white p-5 rounded-lg shadow-sm">
            <h3 className="text-lg font-semibold mb-2">Secure Ownership</h3>
            <p className="text-gray-600">Blockchain-verified ownership of your digital 3D assets.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
