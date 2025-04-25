'use client';

import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { metaMask } from 'wagmi/connectors';

export default function HomeWalletConnect() {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect();
  const { disconnect } = useDisconnect();

  if (!isConnected) {
    return (
      <button
        onClick={() => connect({ connector: metaMask() })}
        className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg transition duration-300"
      >
        Connect Wallet
      </button>
    );
  }

  return (
    <div className="flex flex-col items-center">
      <p className="text-gray-700 mb-2">
        Connected: {address?.substring(0, 6)}...{address?.substring(address?.length - 4)}
      </p>
      <button
        onClick={() => disconnect()}
        className="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-2 px-4 rounded-lg transition duration-300 mb-4"
      >
        Disconnect
      </button>
    </div>
  );
}
