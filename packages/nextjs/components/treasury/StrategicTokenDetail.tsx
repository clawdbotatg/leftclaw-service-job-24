"use client";

import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { formatEther } from "viem";

const TOKEN_NAMES: Record<string, string> = {
  "0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b": "BNKR",
  "0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2": "DRB",
  "0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb": "Clanker",
  "0x50D2280441372486BeecdD328c1854743EBaCb07": "KELLY",
  "0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07": "CLAWD",
  "0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07": "JUNO",
  "0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07": "FELIX",
};

interface Props {
  tokenAddress: string;
  onClose: () => void;
}

export function StrategicTokenDetail({ tokenAddress, onClose }: Props) {
  const { data: info } = useScaffoldReadContract({
    contractName: "TreasuryManagerV2",
    functionName: "getKnownToken",
    args: [tokenAddress],
  });

  if (!info) return null;

  const name = TOKEN_NAMES[tokenAddress] || tokenAddress.slice(0, 10);
  const effectivePct = (Number(info.effectiveUnlockedBps) / 100).toFixed(1);
  const fallbackPct = (Number(info.fallbackUnlockedBps) / 100).toFixed(1);

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-lg">
        <h3 className="font-bold text-lg">{name} Details</h3>

        <div className="divider"></div>

        <div className="grid grid-cols-2 gap-2 text-sm">
          <div className="opacity-70">Type:</div>
          <div>{info.isV4 ? "V4" : "V3"}</div>

          <div className="opacity-70">Current Balance:</div>
          <div>{Number(formatEther(info.currentBalance)).toLocaleString()}</div>

          <div className="opacity-70">Tracked Deposits:</div>
          <div>{Number(formatEther(info.trackedDeposits)).toLocaleString()}</div>

          <div className="opacity-70">Total Sold:</div>
          <div>{Number(formatEther(info.totalSold)).toLocaleString()}</div>

          <div className="opacity-70">Fallback Sold:</div>
          <div>{Number(formatEther(info.fallbackSold)).toLocaleString()}</div>

          <div className="opacity-70">Effective Unlock:</div>
          <div className="font-bold text-primary">{effectivePct}%</div>

          <div className="opacity-70">Fallback Unlock:</div>
          <div className="font-bold text-secondary">{fallbackPct}%</div>

          <div className="opacity-70">Buy Price (USD):</div>
          <div>${Number(formatEther(info.buyPriceUsd)).toFixed(8)}</div>

          <div className="opacity-70">Fallback Activated:</div>
          <div>{info.fallbackActivatedOnce ? "Yes" : "No"}</div>

          <div className="opacity-70">Last Rebalance:</div>
          <div>
            {info.lastNormalRebalanceTimestamp > 0n
              ? new Date(Number(info.lastNormalRebalanceTimestamp) * 1000).toLocaleString()
              : "Never"}
          </div>

          <div className="opacity-70">First Deposit:</div>
          <div>
            {info.firstValidDepositTimestamp > 0n
              ? new Date(Number(info.firstValidDepositTimestamp) * 1000).toLocaleString()
              : "None"}
          </div>
        </div>

        <div className="modal-action">
          <button className="btn" onClick={onClose}>Close</button>
        </div>
      </div>
      <div className="modal-backdrop" onClick={onClose}></div>
    </div>
  );
}
