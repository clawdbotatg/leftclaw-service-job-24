import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

const CONTRACT_ADDRESS = "0x634328008345f1e63571dd24cd818a8f1947b628";

const externalContracts = {
  8453: {
    TreasuryManagerV2: {
      address: CONTRACT_ADDRESS,
      abi: [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_owner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "ASSUMED_TOTAL_SUPPLY",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "BPS_DENOMINATOR",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "DEAD",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "FALLBACK_ACTIVITY_THRESHOLD_BPS",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "FALLBACK_INITIAL_DELAY",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "FALLBACK_RECURRING_DELAY",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "FALLBACK_UNLOCK_INCREMENT_BPS",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "PERMISSIONLESS_SLIPPAGE_BPS",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "PERMISSIONLESS_WETH_PER_ACTION",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "PERMISSIONLESS_WETH_PER_DAY",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "PERMIT2",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "POOL_MANAGER",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "REBALANCE_SPLIT_TUSD_BPS",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "REBALANCE_SPLIT_USDC_BPS",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "RESCUE_DELAY",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "ROLLING_WINDOW_DURATION",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "STAKING",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "STATE_VIEW",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "STRATEGIC_TOKEN_COOLDOWN",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "STRATEGIC_TRANCHE_BPS",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "TUSD",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "TUSD_WETH_FEE",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint24",
        "internalType": "uint24"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "TUSD_WETH_POOL",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "UNIVERSAL_ROUTER",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "USDC",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "USDC_WETH_FEE",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint24",
        "internalType": "uint24"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "USDC_WETH_POOL",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "WETH",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "acceptOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "burnTUSD",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "burnTusdPerAction",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "burnTusdPerDay",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "burnTusdWindow",
    "inputs": [],
    "outputs": [
      {
        "name": "windowStart",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "currentAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "previousAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "buybackUsdcPerAction",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "buybackUsdcPerDay",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "buybackUsdcWindow",
    "inputs": [],
    "outputs": [
      {
        "name": "windowStart",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "currentAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "previousAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "buybackWethPerAction",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "buybackWethPerDay",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "buybackWethWindow",
    "inputs": [],
    "outputs": [
      {
        "name": "windowStart",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "currentAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "previousAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "buybackWithUSDC",
    "inputs": [
      {
        "name": "amountIn",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "buybackWithWETH",
    "inputs": [
      {
        "name": "amountIn",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "depositStrategicToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getKnownToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct TokenInfo",
        "components": [
          {
            "name": "token",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "enabled",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "isCore",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "isV4",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "buyPriceUsd",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "buyMarketCapUsd",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "currentBalance",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "trackedDeposits",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "totalSold",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "fallbackSold",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "effectiveUnlockedBps",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "fallbackUnlockedBps",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "lastNormalRebalanceTimestamp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "firstValidDepositTimestamp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "fallbackActivatedOnce",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "fallbackWindowStart",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getKnownTokens",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "tuple[]",
        "internalType": "struct TokenInfo[]",
        "components": [
          {
            "name": "token",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "enabled",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "isCore",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "isV4",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "buyPriceUsd",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "buyMarketCapUsd",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "currentBalance",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "trackedDeposits",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "totalSold",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "fallbackSold",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "effectiveUnlockedBps",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "fallbackUnlockedBps",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "lastNormalRebalanceTimestamp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "firstValidDepositTimestamp",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "fallbackActivatedOnce",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "fallbackWindowStart",
            "type": "uint256",
            "internalType": "uint256"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getStrategicTokenCount",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "isStrategicToken",
    "inputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "lastOperatorActionTimestamp",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "operator",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "operatorCooldown",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "operatorSlippageBps",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "pendingOwner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "permissionlessRebalanceStrategicToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "permissionlessWindows",
    "inputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "windowStart",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "currentAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "previousAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "rebalanceSlippageBps",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "rebalanceStrategicToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "rebalanceWethPerAction",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "rebalanceWethPerDay",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "rebalanceWethWindows",
    "inputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "windowStart",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "currentAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "previousAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "rescueDeadPoolToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "pathToWETH",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setCoreCapSettings",
    "inputs": [
      {
        "name": "_buybackWethPerAction",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_buybackWethPerDay",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_buybackUsdcPerAction",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_buybackUsdcPerDay",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_burnTusdPerAction",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_burnTusdPerDay",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_stakeTusdPerAction",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_stakeTusdPerDay",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_operatorCooldown",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_operatorSlippageBps",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setOperator",
    "inputs": [
      {
        "name": "_operator",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setStrategicTokenEnabled",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_enabled",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setRebalanceCapSettings",
    "inputs": [
      {
        "name": "_rebalanceWethPerAction",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_rebalanceWethPerDay",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_rebalanceSlippageBps",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "stakeTUSD",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "poolId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "stakeTusdPerAction",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "stakeTusdPerDay",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "stakeTusdWindow",
    "inputs": [],
    "outputs": [
      {
        "name": "windowStart",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "currentAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "previousAmount",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "strategicTokenList",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "strategicTokens",
    "inputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "enabled",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "isV4",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "v3Pool",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "v3Fee",
        "type": "uint24",
        "internalType": "uint24"
      },
      {
        "name": "v4PoolId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "v4Currency0",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "v4Currency1",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "v4Fee",
        "type": "uint24",
        "internalType": "uint24"
      },
      {
        "name": "v4TickSpacing",
        "type": "int24",
        "internalType": "int24"
      },
      {
        "name": "v4Hooks",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "buyPriceUsd",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "buyMarketCapUsd",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "trackedDeposits",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "totalSold",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "fallbackSold",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "firstValidDepositTimestamp",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "lastNormalRebalanceTimestamp",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "fallbackActivatedOnce",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "fallbackWindowStart",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "fallbackWindowPrivilegedSold",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "fallbackUnlockedBps",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "unstakeTUSD",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "poolId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "BurnTUSD",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "BuybackUSDC",
    "inputs": [
      {
        "name": "amountIn",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "tusdReceived",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "BuybackWETH",
    "inputs": [
      {
        "name": "amountIn",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "tusdReceived",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "CoreCapsUpdated",
    "inputs": [],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "DepositStrategicToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "FallbackRatchet",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newFallbackUnlockedBps",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OperatorSet",
    "inputs": [
      {
        "name": "newOperator",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferStarted",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "PermissionlessRebalance",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "wethReceived",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RebalanceCapsUpdated",
    "inputs": [],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RebalanceStrategicToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "wethReceived",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "tusdReceived",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "usdcReceived",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RescueDeadPoolToken",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "wethReceived",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "StakeTUSD",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "poolId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "UnstakeTUSD",
    "inputs": [
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "poolId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "ActivityAboveThreshold",
    "inputs": []
  },
  {
    "type": "error",
    "name": "CooldownNotElapsed",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ExceedsPerActionCap",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ExceedsPerDayCap",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ExceedsTranche",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ExceedsUnlockedAmount",
    "inputs": []
  },
  {
    "type": "error",
    "name": "FallbackWindowNotElapsed",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NoDeposits",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotOperator",
    "inputs": []
  },
  {
    "type": "error",
    "name": "NotOwnerOrOperator",
    "inputs": []
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  },
  {
    "type": "error",
    "name": "RescueTooEarly",
    "inputs": []
  },
  {
    "type": "error",
    "name": "SafeERC20FailedOperation",
    "inputs": [
      {
        "name": "token",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "SlippageExceeded",
    "inputs": []
  },
  {
    "type": "error",
    "name": "TokenNotEnabled",
    "inputs": []
  },
  {
    "type": "error",
    "name": "TokenNotStrategic",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ZeroAddress",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ZeroAmount",
    "inputs": []
  }
]
    },
  },
} as const;

export default externalContracts satisfies GenericContractsDeclaration;
