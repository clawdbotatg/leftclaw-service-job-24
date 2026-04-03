"use client";

import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

export function RoleDisplay({ address }: { address: string | undefined }) {
  const { data: owner } = useScaffoldReadContract({
    contractName: "TreasuryManagerV2",
    functionName: "owner",
  });

  const { data: operator } = useScaffoldReadContract({
    contractName: "TreasuryManagerV2",
    functionName: "operator",
  });

  const isOwner = address && owner && address.toLowerCase() === owner.toLowerCase();
  const isOperator = address && operator && address.toLowerCase() === operator.toLowerCase();

  return (
    <div className="flex gap-2 items-center">
      <span className="text-sm opacity-70">Role:</span>
      {isOwner && <span className="badge badge-primary">Owner</span>}
      {isOperator && <span className="badge badge-secondary">Operator</span>}
      {!isOwner && !isOperator && <span className="badge badge-ghost">Viewer</span>}
    </div>
  );
}
