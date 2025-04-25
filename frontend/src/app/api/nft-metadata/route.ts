import { NextRequest, NextResponse } from 'next/server';
import { createPublicClient, http } from 'viem';
import { localhost } from 'viem/chains';
import { contractAddresses } from '../../../contracts/contractAddresses';
import Glb3dNftAbi from '../../../contracts/Glb3dNft.json';

// Create a public client for interacting with the blockchain
const publicClient = createPublicClient({
  chain: localhost,
  transport: http(),
});

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const nftAddress = searchParams.get('nftAddress');
    const tokenId = searchParams.get('tokenId');

    if (!nftAddress || !tokenId) {
      return NextResponse.json(
        { error: 'Missing nftAddress or tokenId parameters' },
        { status: 400 }
      );
    }

    // Use the contract address from the query or fall back to the configured address
    const contractAddress = nftAddress || contractAddresses[31337].glb3dNft;

    // Call the contract to get metadata
    const metadata = await publicClient.readContract({
      address: contractAddress as `0x${string}`,
      abi: Glb3dNftAbi,
      functionName: 'getGlbMetadata',
      args: [BigInt(tokenId)],
    });

    // Format the response
    const [glbUri, previewUri, name, description, creator] = metadata as unknown as [string, string, string, string, string];
    
    return NextResponse.json({
      glbUri,
      previewUri,
      name,
      description,
      creator
    });
  } catch (error) {
    console.error('Error fetching NFT metadata:', error);
    
    // For demo purposes, return mock data
    return NextResponse.json({
      glbUri: 'https://market-assets.fra1.cdn.digitaloceanspaces.com/market-assets/assets/Astronaut.glb',
      previewUri: 'https://example.com/preview.png',
      name: `3D Model #${request.nextUrl.searchParams.get('tokenId')}`,
      description: 'This is a sample 3D model for demonstration purposes.',
      creator: '0x1234567890123456789012345678901234567890'
    });
  }
}
