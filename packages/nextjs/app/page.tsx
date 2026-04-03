"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { RoleDisplay } from "../components/treasury/RoleDisplay";
import { TokenBalancesPanel } from "../components/treasury/TokenBalancesPanel";
import { OperatorCapsPanel } from "../components/treasury/OperatorCapsPanel";
import { BuybackPanel } from "../components/treasury/BuybackPanel";
import { BuybackUSDCPanel } from "../components/treasury/BuybackUSDCPanel";
import { BurnPanel } from "../components/treasury/BurnPanel";
import { StakePanel } from "../components/treasury/StakePanel";
import { RebalancePanel } from "../components/treasury/RebalancePanel";
import { PermissionlessPanel } from "../components/treasury/PermissionlessPanel";
import { StrategicTokenDetail } from "../components/treasury/StrategicTokenDetail";
import { RainbowKitCustomConnectButton } from "~~/components/scaffold-eth";

export default function TreasuryDashboard() {
  const { address, isConnected } = useAccount();
  const [selectedToken, setSelectedToken] = useState<string | null>(null);

  return (
    <div className="min-h-screen bg-base-200">
      <div className="navbar bg-base-100 shadow-lg px-4">
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-primary">TreasuryManager V2</h1>
          <span className="ml-2 badge badge-outline badge-sm">Base</span>
        </div>
        <div className="flex-none gap-4">
          <RainbowKitCustomConnectButton />
        </div>
      </div>

      <div className="container mx-auto px-4 py-6 max-w-7xl">
        {!isConnected ? (
          <div className="hero min-h-[60vh]">
            <div className="hero-content text-center">
              <div>
                <h2 className="text-4xl font-bold mb-4">TreasuryManager V2</h2>
                <p className="text-lg opacity-70 mb-8">
                  Onchain treasury management for ₸USD (TurboUSD) on Base
                </p>
                <RainbowKitCustomConnectButton />
              </div>
            </div>
          </div>
        ) : (
          <>
            <RoleDisplay address={address} />

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
              <TokenBalancesPanel onSelectToken={setSelectedToken} />
              <OperatorCapsPanel />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">
              <BuybackPanel />
              <BuybackUSDCPanel />
              <BurnPanel />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
              <StakePanel />
              <RebalancePanel />
            </div>

            <div className="mt-6">
              <PermissionlessPanel />
            </div>

            {selectedToken && (
              <StrategicTokenDetail
                tokenAddress={selectedToken}
                onClose={() => setSelectedToken(null)}
              />
            )}
          </>
        )}
      </div>
    </div>
  );
}
