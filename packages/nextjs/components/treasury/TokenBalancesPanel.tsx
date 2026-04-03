"use client";

import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { formatEther, formatUnits } from "viem";

const TOKEN_NAMES: Record<string, string> = {
  "0x3d5e487B21E0569048c4D1A60E98C36e1B09DB07": "TUSD",
  "0x4200000000000000000000000000000000000006": "WETH",
  "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913": "USDC",
  "0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b": "BNKR",
  "0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2": "DRB",
  "0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb": "Clanker",
  "0x50D2280441372486BeecdD328c1854743EBaCb07": "KELLY",
  "0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07": "CLAWD",
  "0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07": "JUNO",
  "0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07": "FELIX",
};

interface TokenBalancesPanelProps {
  onSelectToken: (address: string) => void;
}

export function TokenBalancesPanel({ onSelectToken }: TokenBalancesPanelProps) {
  const { data: tokens } = useScaffoldReadContract({
    contractName: "TreasuryManagerV2",
    functionName: "getKnownTokens",
  });

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title">Token Balances</h2>
        <div className="overflow-x-auto">
          <table className="table table-sm">
            <thead>
              <tr>
                <th>Token</th>
                <th>Balance</th>
                <th>Type</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {tokens?.map((token: any, i: number) => {
                const name = TOKEN_NAMES[token.token] || token.token.slice(0, 8);
                const isUSDC = token.token === "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";
                const balance = isUSDC
                  ? formatUnits(token.currentBalance, 6)
                  : formatEther(token.currentBalance);

                return (
                  <tr key={i} className="hover">
                    <td className="font-mono">{name}</td>
                    <td>{Number(balance).toLocaleString(undefined, { maximumFractionDigits: 4 })}</td>
                    <td>
                      {token.isCore ? (
                        <span className="badge badge-sm badge-primary">Core</span>
                      ) : token.isV4 ? (
                        <span className="badge badge-sm badge-accent">V4</span>
                      ) : (
                        <span className="badge badge-sm badge-secondary">V3</span>
                      )}
                    </td>
                    <td>
                      {!token.isCore && (
                        <button
                          className="btn btn-xs btn-ghost"
                          onClick={() => onSelectToken(token.token)}
                        >
                          Details
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
