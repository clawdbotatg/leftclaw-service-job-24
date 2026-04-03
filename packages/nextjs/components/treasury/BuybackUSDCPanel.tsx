"use client";

import { useState } from "react";
import { parseUnits } from "viem";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

export function BuybackUSDCPanel() {
  const [amount, setAmount] = useState("");
  const [isPending, setIsPending] = useState(false);

  const { writeContractAsync } = useScaffoldWriteContract({
    contractName: "TreasuryManagerV2",
  });

  const handleBuyback = async () => {
    if (!amount || isPending) return;
    setIsPending(true);
    try {
      await writeContractAsync({
        functionName: "buybackWithUSDC",
        args: [parseUnits(amount, 6)],
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
        <h2 className="card-title text-sm">Buyback (USDC → TUSD)</h2>
        <div className="form-control">
          <label className="label"><span className="label-text">USDC Amount</span></label>
          <input
            type="number"
            step="1"
            className="input input-bordered w-full"
            placeholder="2000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            disabled={isPending}
          />
        </div>
        <button
          className={`btn btn-primary mt-2 ${isPending ? "loading" : ""}`}
          onClick={handleBuyback}
          disabled={isPending || !amount}
        >
          {isPending ? "Executing..." : "Execute Buyback"}
        </button>
      </div>
    </div>
  );
}
