# 3D GLB NFT Marketplace

A decentralized marketplace for 3D GLB format NFTs built with Solidity, Foundry, and Next.js.

## Features

- Mint 3D GLB NFTs with preview images
- List NFTs for sale on the marketplace
- Buy NFTs from the marketplace
- Make offers on NFTs
- View 3D models in the browser
- Royalties for creators

## Tech Stack

- **Smart Contracts**: Solidity, Foundry
- **Frontend**: Next.js, React, TypeScript, Tailwind CSS
- **Web3 Integration**: Wagmi, Viem
- **3D Rendering**: Three.js
- **Storage**: IPFS (Pinata)

## Smart Contracts

- `Glb3dNft.sol`: ERC721 contract for 3D GLB NFTs
- `Glb3dMarketplace.sol`: Marketplace contract for buying, selling, and making offers

## Getting Started

### Prerequisites

- Node.js (v18+)
- Foundry (Forge, Cast, Anvil)
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/nft-marketplace.git
   cd nft-marketplace
   ```

2. Install dependencies:
   ```bash
   # Install Foundry dependencies
   forge install

   # Install frontend dependencies
   cd frontend
   npm install
   ```

3. Set up environment variables:
   ```bash
   # Create a .env file in the root directory
   cp .env.example .env
   # Add your WalletConnect project ID and other required variables
   ```

### Running Locally

1. Start a local Anvil chain:
   ```bash
   anvil
   ```

2. Deploy contracts and preload the marketplace:
   ```bash
   forge script script/PreloadMarketplace.s.sol --rpc-url http://localhost:8545 --broadcast
   ```

3. Start the frontend:
   ```bash
   cd frontend
   npm run dev
   ```

4. Open your browser and navigate to `http://localhost:3000`

## Usage

1. **Connect Wallet**: Connect your wallet using MetaMask or WalletConnect
2. **Mint NFT**: Upload a GLB model and preview image, add metadata, and mint your NFT
3. **View My NFTs**: See your minted NFTs and list them for sale
4. **Marketplace**: Browse, buy, and make offers on listed NFTs
5. **View NFT**: View the 3D model in the browser

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- OpenZeppelin for secure contract implementations
- Foundry for the Ethereum development toolchain
- Next.js team for the React framework
- Three.js for 3D rendering capabilities