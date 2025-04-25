interface ContractAddresses {
  [chainId: number]: {
    glb3dNft: string;
    glb3dMarketplace: string;
  };
}

// Contract addresses for different networks
export const contractAddresses: ContractAddresses = {
  // Anvil (local)
  31337: {
    glb3dNft: "0x998abeb3E57409262aE5b751f60747921B33613E",
    glb3dMarketplace: "0x70e0bA845a1A0F2DA3359C97E0285013525FFC49",
  },
  // Sepolia testnet
  11155111: {
    glb3dNft: "0x0000000000000000000000000000000000000000", // Replace with actual address when deployed
    glb3dMarketplace: "0x0000000000000000000000000000000000000000", // Replace with actual address when deployed
  },
  // Ethereum mainnet
  1: {
    glb3dNft: "0x0000000000000000000000000000000000000000", // Replace with actual address when deployed
    glb3dMarketplace: "0x0000000000000000000000000000000000000000", // Replace with actual address when deployed
  },
};
