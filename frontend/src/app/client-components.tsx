'use client';

import { useEffect, useState } from 'react';
import dynamic from 'next/dynamic';

// Dynamically import the ConnectWallet component to avoid hydration issues
const ConnectWallet = dynamic(() => import('../components/ConnectWallet'), {
  ssr: false,
});

export function ClientOnly({ children }: { children: React.ReactNode }) {
  const [hasMounted, setHasMounted] = useState(false);

  useEffect(() => {
    setHasMounted(true);
  }, []);

  if (!hasMounted) {
    return null;
  }

  return <>{children}</>;
}

export function WalletConnectButton() {
  return (
    <ClientOnly>
      <ConnectWallet />
    </ClientOnly>
  );
}
