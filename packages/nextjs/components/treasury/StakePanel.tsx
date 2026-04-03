"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

export function StakePanel() {
  const [amount, setAmount] = useState("");
  const [poolId, setPoolId] = useState("");
  const [isPending, setIsPending] = useState(false);

  const { writeContractAsync } = useScaffoldWriteContract({
    contractName: "TreasuryManagerV2",
  });

  const handleStake = async () => {
    if (!amount || !poolId || isPending) return;
    setIsPending(true);
    try {
      await writeContractAsync({
        functionName: "stakeTUSD",
        args: [parseEther(amount), BigInt(poolId)],
      });
      setAmount("");
    } catch (e) {
      console.error(e);
    } finally {
      setIsPending(false);
    }
  };

  const handleUnstake = async () => {
    if (!amount || !poolId || isPending) return;
    setIsPending(true);
    try {
      await writeContractAsync({
        functionName: "unstakeTUSD",
        args: [parseEther(amount), BigInt(poolId)],
      });
      setAmount("");
    } catch (e) {
      console.error(e);
    } finally {
      setIsPending(false);
    }
  };

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title">Stake / Unstake TUSD</h2>
        <div className="form-control">
          <label className="label"><span className="label-text">TUSD Amount</span></label>
          <input
            type="number"
            className="input input-bordered w-full"
            placeholder="1000000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            disabled={isPending}
          />
        </div>
        <div className="form-control mt-2">
          <label className="label"><span className="label-text">Pool ID</span></label>
          <input
            type="number"
            className="input input-bordered w-full"
            placeholder="0"
            value={poolId}
            onChange={(e) => setPoolId(e.target.value)}
            disabled={isPending}
          />
        </div>
        <div className="flex gap-2 mt-2">
          <button
            className={`btn btn-primary flex-1 ${isPending ? "loading" : ""}`}
            onClick={handleStake}
            disabled={isPending || !amount || !poolId}
          >
            {isPending ? "..." : "Stake"}
          </button>
          <button
            className={`btn btn-secondary flex-1 ${isPending ? "loading" : ""}`}
            onClick={handleUnstake}
            disabled={isPending || !amount || !poolId}
          >
            {isPending ? "..." : "Unstake"}
          </button>
        </div>
      </div>
    </div>
  );
}
