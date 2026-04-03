"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

export function BuybackPanel() {
  const [amount, setAmount] = useState("");
  const [isPending, setIsPending] = useState(false);

  const { writeContractAsync } = useScaffoldWriteContract({
    contractName: "TreasuryManagerV2",
  });

  const handleBuyback = async () => {
    const val = parseFloat(amount);
    if (!val || val <= 0 || isPending) return;
    setIsPending(true);
    try {
      await writeContractAsync({
        functionName: "buybackWithWETH",
        args: [parseEther(amount)],
      });
      setAmount("");
      notification.success("Buyback (WETH → TUSD) executed");
    } catch (e: any) {
      notification.error(e?.shortMessage || e?.message || "Transaction failed");
    } finally {
      setIsPending(false);
    }
  };

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title text-sm">Buyback (WETH → TUSD)</h2>
        <div className="form-control">
          <label className="label"><span className="label-text">WETH Amount</span></label>
          <input
            type="number"
            min="0"
            step="0.01"
            className="input input-bordered w-full"
            placeholder="0.5"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            disabled={isPending}
          />
        </div>
        <button
          className={`btn btn-primary mt-2 ${isPending ? "loading" : ""}`}
          onClick={handleBuyback}
          disabled={isPending || !amount || parseFloat(amount) <= 0}
        >
          {isPending ? "Executing..." : "Execute Buyback"}
        </button>
      </div>
    </div>
  );
}
