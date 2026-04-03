"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

export function BurnPanel() {
  const [amount, setAmount] = useState("");
  const [isPending, setIsPending] = useState(false);

  const { writeContractAsync } = useScaffoldWriteContract({
    contractName: "TreasuryManagerV2",
  });

  const handleBurn = async () => {
    if (!amount || isPending) return;
    setIsPending(true);
    try {
      await writeContractAsync({
        functionName: "burnTUSD",
        args: [parseEther(amount)],
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
        <h2 className="card-title text-sm">Burn TUSD</h2>
        <div className="form-control">
          <label className="label"><span className="label-text">TUSD Amount</span></label>
          <input
            type="number"
            step="1000000"
            className="input input-bordered w-full"
            placeholder="1000000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            disabled={isPending}
          />
        </div>
        <button
          className={`btn btn-error mt-2 ${isPending ? "loading" : ""}`}
          onClick={handleBurn}
          disabled={isPending || !amount}
        >
          {isPending ? "Burning..." : "Burn TUSD"}
        </button>
      </div>
    </div>
  );
}
