# PLAN.md — TreasuryManager v2 (Job 24)

## Overview

TreasuryManager v2 is an onchain treasury management system for ₸USD (TurboUSD) on Base, operated by AMI (Artificial Monetary Intelligence). It enforces strictly one-directional treasury flows: strategic treasury ERC20 assets can only be rebalanced back into ₸USD. ₸USD can only be bought, staked, unstaked, or burned — never sold. Independent permissionless fallback paths ensure treasury funds cannot remain stuck indefinitely.

This is the base TreasuryManager v2 build. Job 20 adds staking integration on top of this same contract.

---

## Token & Pool Reference (Final — from Client)

### Core Tokens
| Token | Address |
|-------|---------|
| TUSD (₸USD) | `0x3d5e487B21E0569048c4D1A60E98C36e1B09DB07` |
| WETH | `0x4200000000000000000000000000000000000006` |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |

### Infrastructure
| Contract | Address |
|----------|---------|
| UNIVERSAL_ROUTER | `0x6fF5693b99212Da76ad316178A184AB56D299b43` |
| POOL_MANAGER (V4) | `0x498581fF718922c3f8e6A244956aF099B2652b2b` |
| STATE_VIEW (V4) | `0xA3c0c9b65baD0b08107Aa264b0F3dB444b867A71` |
| PERMIT2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| STAKING | `0x2a70a42BC0524aBCA9Bff59a51E7aAdB575DC89A` |

### Official Pools
| Pool | Address | Fee |
|------|---------|-----|
| TUSD/WETH (official) | `0xd013725b904e76394A3aB0334Da306C505D778F8` | 10000 |
| USDC/WETH | `0xd0b53D9277642d899DF5C87A3966A349A798F224` | 500 |

### Strategic Tokens — V3
| Token | Address | Pool | Fee | Buy Price | Buy MCap |
|-------|---------|------|-----|-----------|----------|
| BNKR | `0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b` | `0xAEC085E5A5CE8d96A7bDd3eB3A62445d4f6CE703` | 10000 | $0.0003497 | $35M |
| DRB | `0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2` | `0x5116773e18A9C7bB03EBB961b38678E45E238923` | 10000 | $0.00008909 | $9M |
| Clanker | `0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb` | `0xC1a6FBeDAe68E1472DbB91FE29B51F7a0Bd44F97` | 10000 | $25 | $25M |

### Strategic Tokens — V4
| Token | Address | PoolId | currency0 | Fee | TickSpacing | Hooks | Buy Price | Buy MCap |
|-------|---------|--------|-----------|-----|-------------|-------|-----------|----------|
| KELLY | `0x50D2280441372486BeecdD328c1854743EBaCb07` | `0x7EAC33D5641697366EAEC3234147FD98BA25F01ACCA66A51A48BD129FC532145` | WETH | 8388608 | 200 | `0xb429d62f8f3bFFb98CdB9569533eA23bF0Ba28CC` | $0.000015 | $1.5M |
| CLAWD | `0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07` | `0x9FD58E73D8047CB14AC540ACD141D3FC1A41FB6252D674B730FAF62FE24AA8CE` | WETH | 8388608 | 200 | `0xb429d62f8f3bFFb98CdB9569533eA23bF0Ba28CC` | $0.000028 | $2.8M |
| JUNO | `0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07` | `0x1635213E2B19E459A4132DF40011638B65AE7510A35D6A88C47EBF94912C7F2E` | WETH | 8388608 | 200 | `0xb429d62f8f3bFFb98CdB9569533eA23bF0Ba28CC` | $0.000008 | $0.8M |
| FELIX | `0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07` | `0x6E19027912DB90892200A2B08C514921917BC55D7291EC878AA382C193B50084` | WETH | 8388608 | 200 | `0xb429d62f8f3bFFb98CdB9569533eA23bF0Ba28CC` | $0.00001 | $1M |

---

## Smart Contract Architecture

### TreasuryManagerV2.sol
**Inheritance:** Ownable2Step, ReentrancyGuard

### Permissionless Constants (immutable, hardcoded)
| Constant | Value |
|----------|-------|
| PERMISSIONLESS_WETH_PER_ACTION | 0.5 ether |
| PERMISSIONLESS_WETH_PER_DAY | 2 ether |
| PERMISSIONLESS_SLIPPAGE_BPS | 300 (3%) |
| FALLBACK_INITIAL_DELAY | 180 days |
| FALLBACK_RECURRING_DELAY | 14 days |
| FALLBACK_ACTIVITY_THRESHOLD_BPS | 100 (1% = 0.01) |
| FALLBACK_UNLOCK_INCREMENT_BPS | 200 (2%) |
| STRATEGIC_TRANCHE_BPS | 200 (2%) |
| STRATEGIC_TOKEN_COOLDOWN | 4 hours |
| ROLLING_WINDOW_DURATION | 24 hours |
| REBALANCE_SPLIT_TUSD_BPS | 7500 (75%) |
| REBALANCE_SPLIT_USDC_BPS | 2500 (25%) |
| ASSUMED_TOTAL_SUPPLY | 100,000,000,000e18 |

### Operator Caps (owner-configurable)
| Action | Per Action | Per Day |
|--------|-----------|---------|
| buybackWeth | 0.5 ETH | 2 ETH |
| buybackUsdc | 2000 USDC | 5000 USDC |
| burnTusd | 100M TUSD | 500M TUSD |
| stakeTusd | 100M TUSD | 500M TUSD |
| rebalance | Uses buybackWeth caps on 100% of input | — |
| operatorCooldown | 60 minutes | — |
| operatorSlippageBps | 300 (3%) | — |

### Normal Rebalance Caps (owner-configurable)
| Action | Per Action | Per Day |
|--------|-----------|---------|
| rebalanceWeth | 0.5 ETH | 2 ETH |
| rebalanceSlippageBps | 300 (3%) | — |

---

## Structs

```solidity
struct RollingWindow {
    uint256 windowStart;
    uint256 currentAmount;
    uint256 previousAmount;
}

struct StrategicTokenConfig {
    bool enabled;
    address token;
    bool isV4;
    address v3Pool;
    uint24 v3Fee;
    bytes32 v4PoolId;
    address v4Currency0;
    address v4Currency1;
    uint24 v4Fee;
    int24 v4TickSpacing;
    address v4Hooks;
    uint256 buyPriceUsd;      // 1e18 scaled: 0.0003497 = 349700000000000
    uint256 buyMarketCapUsd;  // 1e18 scaled
    uint256 trackedDeposits;
    uint256 totalSold;
    uint256 fallbackSold;
    uint256 firstValidDepositTimestamp;
    uint256 lastNormalRebalanceTimestamp;
    bool fallbackActivatedOnce;
    uint256 fallbackWindowStart;
    uint256 fallbackWindowPrivilegedSold;
    uint256 fallbackUnlockedBps;
}

struct TokenInfo {
    address token;
    bool enabled;
    bool isCore;
    bool isV4;
    uint256 buyPriceUsd;
    uint256 buyMarketCapUsd;
    uint256 currentBalance;
    uint256 trackedDeposits;
    uint256 totalSold;
    uint256 fallbackSold;
    uint256 effectiveUnlockedBps;
    uint256 fallbackUnlockedBps;
    uint256 lastNormalRebalanceTimestamp;
    uint256 firstValidDepositTimestamp;
    bool fallbackActivatedOnce;
    uint256 fallbackWindowStart;
}
```

---

## Functions

### Owner-Only
- `setOperator(address)` — set AMI operator
- `setCoreCapSettings(...)` — mutable core caps
- `setRebalanceCapSettings(...)` — mutable normal rebalance caps
- `rescueDeadPoolToken(address token, bytes path)` — after 90+ days dead pool. Swaps to WETH only, stays in contract.

### Operator-Only
- `buybackWithWETH(uint256 amountIn)` — WETH → TUSD via official pool (fee 10000). TUSD stays in contract. Balance delta validation. Operator: buybackWethPerAction/Day, operatorCooldown, operatorSlippageBps. Owner: bypass caps/cooldown.
- `buybackWithUSDC(uint256 amountIn)` — USDC → WETH (fee 500) → TUSD (fee 10000). Balance delta validation. Operator: buybackUsdcPerAction/Day, operatorCooldown. Owner: bypass.
- `burnTUSD(uint256 amount)` — burns to `0x000000000000000000000000000000000000dEaD`. amount > 0. Operator: burnTusdPerAction/Day, operatorCooldown. Owner: bypass.
- `stakeTUSD(uint256 amount, uint256 poolId)` — approves TUSD to STAKING, calls `IStaking(STAKING).stake(amount, poolId)`. Operator: stakeTusdPerAction/Day, operatorCooldown. Owner: bypass.
- `unstakeTUSD(uint256 amount, uint256 poolId)` — calls `IStaking(STAKING).unstake(amount, poolId)`. TUSD returns to TreasuryManager. Operator: stake caps/cooldown. Owner: bypass.
- `depositStrategicToken(address token, uint256 amount)` — Owner only. Uses `transferFrom`. First valid deposit sets `firstValidDepositTimestamp` and initializes `fallbackWindowStart`. Balance delta for fee-on-transfer.
- `rebalanceStrategicToken(address token, uint256 amount)` — Owner or operator. Execution: (1) sell token → WETH via V3 or V4+Permit2, (2) split 75/25, (3) 75% WETH → TUSD, (4) 25% WETH → USDC to owner(). Balance delta on every leg. Operator: 4h per-token cooldown, amount <= 2% tranche of trackedDeposits, amount <= normalUnlockedAvailable, quoted WETH <= rebalanceWethPerAction/Day, rebalanceSlippageBps, operatorCooldown. Owner: bypass caps/cooldown but NOT routing/slippage.
- `buyTokenWithETH(address token, uint256 amount, bytes path)` — ETH → ERC20 via Universal Router. V3: path starts/ends with WETH/token. V4: no path needed. Records cost basis via balanceOf delta. **amount = WETH to spend (input amount, exactInput style).** `poolNumber` parameter = poolId for staking integration reference.

### Permissionless
- `permissionlessRebalanceStrategicToken(address token, uint256 amount)` — anyone can call. Same execution as normal rebalance. Immutable constraints: amount <= permissionlessUnlockedAvailable, amount <= 2% tranche of fallback chunk, quoted WETH <= PERMISSIONLESS_WETH_PER_ACTION/DAY, PERMISSIONLESS_SLIPPAGE_BPS. On success: `fallbackActivatedOnce = true`, `fallbackWindowStart = block.timestamp`, `fallbackWindowPrivilegedSold = 0`.

---

## Unlock Logic

### ROI Unlock
- `currentPrice` from V3 pool `slot0()` or V4 `StateView`
- `multiplier = currentPrice / buyPriceUsd`
- At 10x: 2500 bps. Each integer multiple above 10: +500 bps.
- `roiUnlockBps = min(2500 + (multiplier - 10) * 500, 10000)`

### Market Cap Unlock
- `currentMarketCap = currentPrice * ASSUMED_TOTAL_SUPPLY`
- At $100M: 2500 bps. Each $10M above $100M: +500 bps.
- `mcapUnlockBps = min(2500 + ((mcap - 100M) / 10M) * 500, 10000)`

### Effective Unlock
- `effectiveUnlockBps = max(roiUnlockBps, mcapUnlockBps)`
- `normalUnlockedAmount = trackedDeposits * effectiveUnlockBps / 10000`
- `normalUnlockedAvailable = normalUnlockedAmount - totalSold`

### Fallback Window Logic
- If `fallbackActivatedOnce == false`: window = 180 days from `firstValidDepositTimestamp`
- If `fallbackActivatedOnce == true`: window = 14 days from `fallbackWindowStart`
- When full window elapses AND `fallbackWindowPrivilegedSold < 1% of trackedDeposits`: increase `fallbackUnlockedBps` by 200, cap at 10000
- `permissionlessUnlockedAvailable = (trackedDeposits * fallbackUnlockedBps / 10000) - fallbackSold`

### Rolling Window Helper
Reusable struct + two internal functions:
- `_effectiveRollingAmount(RollingWindow storage w)` — returns weighted usage across current + previous window
- `_consumeRollingAmount(RollingWindow storage w, uint256 amount, uint256 cap)` — validates and records

Applied to: all daily caps for core operator, normal rebalance per token, permissionless rebalance per token.

### Unlock Schedule (ratcheted, never decreases)
- 1000% ROI (10x): 25% unlocked
- Each additional 10% above 10x: 5% of remaining locked unlocks

---

## V4 Swap Flow (Permit2)
For V4 strategic sells (KELLY, CLAWD, JUNO, FELIX → WETH):
1. `IERC20(token).approve(PERMIT2, amount)`
2. `IPermit2(PERMIT2).approve(token, UNIVERSAL_ROUTER, uint160(amount), expiration)`
3. `IUniversalRouter(UNIVERSAL_ROUTER).execute(commands, inputs, deadline)`
Output WETH returns to TreasuryManager. No offchain signatures.

---

## View Functions
- `getKnownTokens() → TokenInfo[]` — all 10 tokens (3 core + 7 strategic)
- `getKnownToken(address) → TokenInfo` — single token lookup

---

## Interfaces
```solidity
interface IStaking {
    function stake(uint256 amount, uint256 poolId) external;
    function unstake(uint256 amount, uint256 poolId) external;
}

interface IUniversalRouter {
    function execute(bytes commands, bytes[] inputs, uint256 deadline) external payable;
}
```

---

## V4 Audit Fixes (from Job 9 audit — apply to this contract too)
1. `commands = hex"10"` (V4_SWAP only), `inputs[0] = abi.encode(poolKey, zeroForOne, exactAmount, minAmountOut, hookData)`
2. Output token validation in `_swapV4`: `require(outputToken == token, "output token mismatch")`
3. No `sqrtPriceLimitX96` — not part of V4SwapData struct
4. V3 path validation: path starts with WETH, ends with target token

---

## Client
`0x9ba58Eea1Ea9ABDEA25BA83603D54F6D9A01E506`

All privileged roles (owner, operator) must be set to the client address.

---

## Build Pipeline
Service Type 6 (Build):
- [x] create_repo
- [x] create_plan
- [ ] create_user_journey
- [ ] prototype
- [ ] contract_audit
- [ ] contract_fix
- [ ] deep_contract_audit (if complex)
- [ ] deep_contract_fix
- [ ] frontend_audit
- [ ] frontend_fix
- [ ] full_audit
- [ ] full_audit_fix
- [ ] deploy_contract
- [ ] livecontract_fix
- [ ] deploy_app
- [ ] liveapp_fix
- [ ] liveuserjourney
- [ ] readme
- [ ] ready
