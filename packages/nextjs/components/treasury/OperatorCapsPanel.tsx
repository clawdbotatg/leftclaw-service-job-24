"use client";

import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { formatEther, formatUnits } from "viem";

function CapBar({ label, current, max, decimals = 18 }: { label: string; current: bigint; max: bigint; decimals?: number }) {
  const pct = max > 0n ? Number((current * 100n) / max) : 0;
  return (
    <div className="mb-2">
      <div className="flex justify-between text-sm">
        <span>{label}</span>
        <span>
          {Number(decimals === 6 ? formatUnits(current, 6) : formatEther(current)).toLocaleString()} /{" "}
          {Number(decimals === 6 ? formatUnits(max, 6) : formatEther(max)).toLocaleString()}
        </span>
      </div>
      <progress className="progress progress-primary w-full" value={pct} max={100}></progress>
    </div>
  );
}

export function OperatorCapsPanel() {
  const { data: wethPerDay } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "buybackWethPerDay" });
  const { data: usdcPerDay } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "buybackUsdcPerDay" });
  const { data: burnPerDay } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "burnTusdPerDay" });
  const { data: stakePerDay } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "stakeTusdPerDay" });
  const { data: cooldown } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "operatorCooldown" });
  const { data: slippage } = useScaffoldReadContract({ contractName: "TreasuryManagerV2", functionName: "operatorSlippageBps" });

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title">Operator Caps</h2>
        <CapBar label="Buyback WETH/Day" current={0n} max={wethPerDay || 0n} />
        <CapBar label="Buyback USDC/Day" current={0n} max={usdcPerDay || 0n} decimals={6} />
        <CapBar label="Burn TUSD/Day" current={0n} max={burnPerDay || 0n} />
        <CapBar label="Stake TUSD/Day" current={0n} max={stakePerDay || 0n} />
        <div className="mt-2 text-sm opacity-70">
          <div>Cooldown: {cooldown ? Number(cooldown) / 60 : "?"} min</div>
          <div>Slippage: {slippage ? Number(slippage) / 100 : "?"}%</div>
        </div>
      </div>
    </div>
  );
}
