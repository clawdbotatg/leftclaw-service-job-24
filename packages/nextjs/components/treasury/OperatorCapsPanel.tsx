"use client";

import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { formatEther, formatUnits } from "viem";

function CapBar({ label, max, decimals = 18 }: { label: string; max: bigint; decimals?: number }) {
  const fmt = decimals === 6 ? formatUnits(max, 6) : formatEther(max);
  return (
    <div className="mb-2">
      <div className="flex justify-between text-sm">
        <span>{label}</span>
        <span>{Number(fmt).toLocaleString()} / day</span>
      </div>
      <progress className="progress progress-primary w-full" value={100} max={100}></progress>
    </div>
  );
}

export function OperatorCapsPanel() {
  const { data: wethPerDay, isLoading: l1 } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "buybackWethPerDay" });
  const { data: usdcPerDay, isLoading: l2 } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "buybackUsdcPerDay" });
  const { data: burnPerDay, isLoading: l3 } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "burnTusdPerDay" });
  const { data: stakePerDay, isLoading: l4 } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "stakeTusdPerDay" });
  const { data: cooldown } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "operatorCooldown" });
  const { data: slippage } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "operatorSlippageBps" });
  const { data: rebalSlippage } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "rebalanceSlippageBps" });

  const isLoading = l1 || l2 || l3 || l4;

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title">Operator Caps</h2>
        {isLoading ? (
          <div className="flex justify-center py-8">
            <span className="loading loading-spinner loading-lg"></span>
          </div>
        ) : (
          <>
            <CapBar label="Buyback WETH" max={wethPerDay || 0n} />
            <CapBar label="Buyback USDC" max={usdcPerDay || 0n} decimals={6} />
            <CapBar label="Burn TUSD" max={burnPerDay || 0n} />
            <CapBar label="Stake TUSD" max={stakePerDay || 0n} />
            <div className="mt-2 text-sm opacity-70 space-y-1">
              <div>Cooldown: {cooldown ? Number(cooldown) / 60 : "?"} min</div>
              <div>Buyback slippage: {slippage ? Number(slippage) / 100 : "?"}%</div>
              <div>Rebalance slippage: {rebalSlippage ? Number(rebalSlippage) / 100 : "?"}%</div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
