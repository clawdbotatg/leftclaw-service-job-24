"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

const STRATEGIC_TOKENS = [
  { name: "BNKR", address: "0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b" },
  { name: "DRB", address: "0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2" },
  { name: "Clanker", address: "0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb" },
  { name: "KELLY", address: "0x50D2280441372486BeecdD328c1854743EBaCb07" },
  { name: "CLAWD", address: "0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07" },
  { name: "JUNO", address: "0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07" },
  { name: "FELIX", address: "0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07" },
];

export function RebalancePanel() {
  const [selectedToken, setSelectedToken] = useState(STRATEGIC_TOKENS[0].address);
  const [amount, setAmount] = useState("");
  const [isPending, setIsPending] = useState(false);

  const { writeContractAsync } = useScaffoldWriteContract({
    contractName: "TreasuryManagerV2",
  });

  const handleRebalance = async () => {
    const val = parseFloat(amount);
    if (!val || val <= 0 || isPending) return;
    setIsPending(true);
    try {
      await writeContractAsync({
        functionName: "rebalanceStrategicToken",
        args: [selectedToken, parseEther(amount)],
      });
      setAmount("");
      const name = STRATEGIC_TOKENS.find(t => t.address === selectedToken)?.name || "token";
      notification.success(`Rebalanced ${amount} ${name}`);
    } catch (e: any) {
      notification.error(e?.shortMessage || e?.message || "Rebalance failed");
    } finally {
      setIsPending(false);
    }
  };

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title">Rebalance Strategic Token</h2>
        <p className="text-sm opacity-70">Owner / Operator only</p>
        <div className="form-control">
          <label className="label"><span className="label-text">Token</span></label>
          <select
            className="select select-bordered w-full"
            value={selectedToken}
            onChange={(e) => setSelectedToken(e.target.value)}
            disabled={isPending}
          >
            {STRATEGIC_TOKENS.map((t) => (
              <option key={t.address} value={t.address}>{t.name}</option>
            ))}
          </select>
        </div>
        <div className="form-control mt-2">
          <label className="label"><span className="label-text">Amount</span></label>
          <input
            type="number"
            min="0"
            className="input input-bordered w-full"
            placeholder="1000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            disabled={isPending}
          />
        </div>
        <button
          className={`btn btn-warning mt-2 ${isPending ? "loading" : ""}`}
          onClick={handleRebalance}
          disabled={isPending || !amount || parseFloat(amount) <= 0}
        >
          {isPending ? "Executing..." : "Rebalance"}
        </button>
      </div>
    </div>
  );
}
