'use client';

import { useRef, useState, useEffect } from 'react';
import { Canvas, useLoader } from '@react-three/fiber';
import { OrbitControls, useGLTF, Environment, PresentationControls } from '@react-three/drei';
import { Suspense } from 'react';

interface GlbViewerProps {
  glbUri: string;
  autoRotate?: boolean;
  backgroundColor?: string;
}

function Model({ glbUri }: { glbUri: string }) {
  // Convert IPFS URI to HTTP URL if needed
  const modelUrl = glbUri.startsWith('ipfs://')
    ? `https://ipfs.io/ipfs/${glbUri.replace('ipfs://', '')}`
    : glbUri;

  const [error, setError] = useState<string | null>(null);

  const { scene } = useGLTF(modelUrl, undefined, (e) => {
    console.error('Error loading GLB model:', e);
    setError('Failed to load 3D model');
  });

  if (error) {
    return (
      <mesh>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="red" />
      </mesh>
    );
  }

  return <primitive object={scene} />;
}

export default function GlbViewer({ glbUri, autoRotate = true, backgroundColor = '#f3f4f6' }: GlbViewerProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Simulate loading the model
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 2000);

    return () => clearTimeout(timer);
  }, [glbUri]);

  return (
    <div ref={containerRef} className="w-full h-full relative">
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-100 bg-opacity-75 z-10">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        </div>
      )}

      {error && (
        <div className="absolute inset-0 flex items-center justify-center bg-gray-100 bg-opacity-75 z-10">
          <div className="bg-white p-4 rounded-md shadow-md">
            <p className="text-red-600 font-medium">Error loading 3D model</p>
            <p className="text-gray-600 text-sm mt-1">{error}</p>
          </div>
        </div>
      )}

      <Canvas
        style={{ background: backgroundColor }}
        camera={{ position: [0, 0, 5], fov: 50 }}
        shadows
      >
        <ambientLight intensity={0.5} />
        <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} intensity={1} castShadow />
        <Suspense fallback={null}>
          <PresentationControls
            global
            rotation={[0, 0, 0]}
            polar={[-Math.PI / 4, Math.PI / 4]}
            azimuth={[-Math.PI / 4, Math.PI / 4]}
            config={{ mass: 2, tension: 500 }}
            snap={{ mass: 4, tension: 1500 }}
          >
            <Model glbUri={glbUri} />
          </PresentationControls>
          <OrbitControls autoRotate={autoRotate} enablePan={true} enableZoom={true} enableRotate={true} />
          <Environment preset="city" />
        </Suspense>
      </Canvas>
    </div>
  );
}
