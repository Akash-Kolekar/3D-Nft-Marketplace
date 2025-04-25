'use client';

import { WagmiConfig } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { wagmiConfig } from '../config/wagmiConfig';
import Link from 'next/link';
import { WalletConnectButton } from './client-components';

// Create a client
const queryClient = new QueryClient();

export default function ClientLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <QueryClientProvider client={queryClient}>
      <WagmiConfig config={wagmiConfig}>
        <div className="min-h-screen bg-gray-100">
          <header className="bg-white shadow">
            <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
              <h1 className="text-3xl font-bold text-gray-900">3D GLB NFT Marketplace</h1>
              <div className="flex items-center space-x-6">
                <nav className="flex space-x-4">
                  <Link href="/" className="text-gray-600 hover:text-gray-900">Home</Link>
                  <Link href="/mint" className="text-gray-600 hover:text-gray-900">Mint NFT</Link>
                  <Link href="/marketplace" className="text-gray-600 hover:text-gray-900">Marketplace</Link>
                  <Link href="/my-nfts" className="text-gray-600 hover:text-gray-900">My NFTs</Link>
                </nav>
                <div className="hidden md:block">
                  <WalletConnectButton />
                </div>
              </div>
            </div>
          </header>
          <main>
            <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
              {children}
            </div>
          </main>
        </div>
      </WagmiConfig>
    </QueryClientProvider>
  );
}
