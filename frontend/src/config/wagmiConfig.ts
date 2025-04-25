import { createConfig, http } from 'wagmi';
import { mainnet, sepolia, localhost } from 'wagmi/chains';
import { injected, metaMask, coinbaseWallet, walletConnect } from 'wagmi/connectors';

// Create wagmi config for v2
export const wagmiConfig = createConfig({
  chains: [mainnet, sepolia, localhost],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [localhost.id]: http('http://localhost:8545'),
  },
  connectors: [
    injected(),
    metaMask(),
    coinbaseWallet({
      appName: '3D GLB NFT Marketplace',
    }),
    walletConnect({
      projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '3ec28e3f1ef786bdb9d7e2f4b03f5aeb',
      metadata: {
        name: '3D GLB NFT Marketplace',
        description: 'A marketplace for 3D GLB format NFTs',
        url: 'http://localhost:3000',
        icons: ['https://avatars.githubusercontent.com/u/37784886']
      }
    }),
  ],
});
