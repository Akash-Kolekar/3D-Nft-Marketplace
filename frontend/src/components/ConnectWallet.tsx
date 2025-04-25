'use client';

import { useState } from 'react';
import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { metaMask } from 'wagmi/connectors';

export default function ConnectWallet() {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect();
  const { disconnect } = useDisconnect();
  const [isLoading, setIsLoading] = useState(false);

  // If connected, show the address and disconnect button
  if (isConnected && address) {
    return (
      <div className="flex items-center">
        <span className="text-sm text-gray-700 mr-2">
          {address.substring(0, 6)}...{address.substring(address.length - 4)}
        </span>
        <button
          onClick={() => disconnect()}
          className="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-2 px-4 rounded-lg text-sm"
        >
          Disconnect
        </button>
      </div>
    );
  }

  // If not connected, show the connect button with direct MetaMask connection
  const handleConnect = () => {
    try {
      setIsLoading(true);
      connect({ connector: metaMask() });
    } catch (error) {
      console.error('Failed to connect:', error);
      alert('Failed to connect to MetaMask. Please make sure MetaMask is installed and unlocked.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button
      onClick={handleConnect}
      disabled={isLoading}
      className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg text-sm"
    >
      {isLoading ? 'Connecting...' : 'Connect Wallet'}
    </button>
  );
}
