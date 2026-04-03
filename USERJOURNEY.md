# USERJOURNEY.md — TreasuryManager v2 (Job 24)

## Actors

1. **Owner** — deploys and configures the contract, deposits strategic tokens, sets operator, adjusts caps
2. **Operator (AMI bot)** — performs buybacks, burns, stakes, unstakes, rebalances within defined caps
3. **Anyone (Permissionless)** — can trigger fallback rebalance when operator is inactive

---

## Network & Wallets

- Network: Base mainnet (chain ID 8453)
- Owner wallet: `job.client` — the address that posted the job
- Operator wallet: set via `setOperator()` — AMI's bot wallet
- Contract: deployed at `[TBD after deploy]`

---

## User Flows

### Flow 1: Owner Deploys and Configures Contract

1. Owner deploys `TreasuryManagerV2.sol` — constructor initializes all 7 strategic tokens with their pool configs
2. Owner calls `setOperator(operatorAddress)` — registers AMI bot as operator
3. Owner calls `setCoreCapSettings(...)` to set operator action/day limits (or uses defaults)
4. Owner calls `setRebalanceCapSettings(...)` for rebalance limits
5. Contract is now configured and ready to receive funds

**Edge cases:**
- Owner accidentally sets operator to zero address → `setOperator(0)` is valid but operator functions will revert (no special zero-address bypass)
- Owner tries to call operator-only functions → reverts with `OwnableUnauthorizedAccount`

---

### Flow 2: Owner Deposits Strategic Token

1. Owner calls `IERC20(token).approve(treasury, amount)` — approves TreasuryManager to pull tokens
2. Owner calls `depositStrategicToken(token, amount)` — tokens transferred from owner to treasury
3. Contract records `trackedDeposits += actualReceived` (balance delta, handles fee-on-transfer)
4. `firstValidDepositTimestamp` set if this is the first valid deposit
5. Event `StrategicTokenDeposited` emitted

**Edge cases:**
- Token not in strategic token list → revert
- Amount exceeds available balance → `transferFrom` reverts
- Fee-on-transfer token → `trackedDeposits` uses actual received amount, not `amount` param

---

### Flow 3: Operator Buyback with WETH

**Prerequisites:** TreasuryManager holds WETH

1. Operator calls `buybackWithWETH(amountIn)`
2. Cooldown check: `block.timestamp - lastOperatorActionTimestamp >= operatorCooldown`
3. Daily cap check: `operatorDailyUsed + amountIn <= buybackWethPerDay`
4. Per-action cap check: `amountIn <= buybackWethPerAction`
5. Swap: WETH → TUSD via official TUSD/WETH pool (fee 10000)
6. TUSD stays in contract. Balance delta validates received amount.
7. `lastOperatorActionTimestamp = block.timestamp`
8. Event `BuybackExecuted` emitted

**Edge cases:**
- Cooldown not elapsed → revert `CooldownNotElapsed`
- Daily cap exceeded → revert `DailyCapExceeded`
- Insufficient WETH balance → `transferFrom` reverts
- Slippage exceeded → Universal Router reverts

---

### Flow 4: Operator Buyback with USDC

**Prerequisites:** TreasuryManager holds USDC

1. Operator calls `buybackWithUSDC(amountIn)`
2. Same cooldown/cap checks (buybackUsdcPerAction/Day)
3. Two-hop swap: USDC → WETH (fee 500) → TUSD (fee 10000)
4. Balance delta validates final TUSD received
5. Events emitted for both swap legs

**Edge cases:** Same as Flow 3, plus two-hop path validation

---

### Flow 5: Operator Burns TUSD

**Prerequisites:** TreasuryManager holds TUSD

1. Operator calls `burnTUSD(amount)`
2. Cooldown/cap checks (burnTusdPerAction/Day)
3. `IERC20(TUSD).transfer(DEAD_ADDRESS, amount)` — burns to `0x000000000000000000000000000000000000dEaD`
4. Event `BurnExecuted` emitted

**Edge cases:**
- Amount = 0 → revert
- Insufficient TUSD → reverts
- Dead address transfer fails → extremely unlikely for standard ERC20

---

### Flow 6: Operator Stakes TUSD

**Prerequisites:** TreasuryManager holds TUSD, operator knows a valid staking poolId

1. Operator calls `stakeTUSD(amount, poolId)`
2. Cooldown/cap checks (stakeTusdPerAction/Day)
3. `IERC20(TUSD).approve(STAKING, amount)` — max approval
4. `IStaking(STAKING).stake(amount, poolId)`
5. TUSD transferred from TreasuryManager to staking contract
6. Event `StakeExecuted` emitted

**Edge cases:**
- Invalid poolId → staking contract reverts
- Insufficient TUSD → reverts at step 3 or 4

---

### Flow 7: Operator Unstakes TUSD

**Prerequisites:** TreasuryManager previously staked TUSD

1. Operator calls `unstakeTUSD(amount, poolId)`
2. NO cooldown check, NO cap check
3. `IStaking(STAKING).unstake(amount, poolId)` — staked TUSD + rewards return to TreasuryManager
4. Event `UnstakeExecuted` emitted

**Edge cases:**
- Nothing staked → staking contract likely reverts
- Wrong poolId → staking contract reverts

---

### Flow 8: Operator Rebalances Strategic Token

**Prerequisites:** Owner has deposited strategic token, sufficient unlock available

1. Operator calls `rebalanceStrategicToken(token, amount)`
2. 4h per-token cooldown check
3. Unlock check: `amount <= normalUnlockedAvailable` (checked via unlock math)
4. 2% tranche check: `amount <= trackedDeposits * 200 / 10000`
5. Cap checks: quoted WETH output <= rebalanceWethPerAction/Day
6. Slippage check
7. Swap token → WETH via V3 pool (or V4 via Permit2)
8. Split: 75% WETH → TUSD (stays in contract), 25% WETH → USDC (sent to owner)
9. Balance deltas validate all legs
10. `lastNormalRebalanceTimestamp = block.timestamp`
11. Event `RebalanceExecuted(..., false, msg.sender)` emitted

**Edge cases:**
- Insufficient unlock → revert `InsufficientUnlock`
- 4h cooldown not elapsed → revert
- Daily cap exceeded → revert
- Slippage exceeded → revert

---

### Flow 9: Permissionless Rebalance (Fallback)

**Unlock conditions (both required):**
1. ROI >= 1000% (10x) vs weighted average cost — measured via 24h TWAP
2. No operator rebalance for 14 days since current ROI tier first reached

**When unlock conditions are met:**
1. Anyone calls `permissionlessRebalanceStrategicToken(token, amount)`
2. `amount <= permissionlessUnlockedAvailable`
3. `amount <= 2% tranche of fallback chunk`
4. Quoted WETH <= PERMISSIONLESS_WETH_PER_ACTION/DAY
5. 3% slippage enforced
6. Same swap/split execution as operator rebalance
7. `fallbackActivatedOnce = true`, `fallbackWindowStart = block.timestamp`, `fallbackWindowPrivilegedSold = 0`
8. Event `RebalanceExecuted(..., true, msg.sender)` emitted

**Fallback unlock ratchet:**
- After 14-day window elapses AND `fallbackWindowPrivilegedSold < 1% trackedDeposits`: `fallbackUnlockedBps += 200`, capped at 10000
- This is a one-way ratchet: unlock percentage can only increase

**Edge cases:**
- Unlock not met → revert `UnlockNotMet`
- Wrong network / stale TWAP → oracle manipulation risk acknowledged (24h TWAP mitigates)
- Permissionless params are immutable — owner cannot change them

---

### Flow 10: Owner Rescues Dead Pool Token

**Trigger:** A strategic token's pool has been inactive for 90+ days

1. Owner calls `rescueDeadPoolToken(token, pathToWETH)`
2. 90-day check: `block.timestamp - lastNormalRebalanceTimestamp > 90 days`
3. Swap token → WETH via path (no TUSD leg)
4. WETH stays in contract
5. Event `DeadPoolTokenRescued` emitted

**Edge cases:**
- Pool not actually dead → still allowed, just a normal swap
- Owner tries to call during normal operation → revert `DeadPoolNotMet`

---

### Flow 11: Owner Updates Operator Caps

1. Owner calls `setCoreCapSettings(actionType, perAction, perDay)`
2. New caps applied immediately
3. Existing in-progress daily windows unaffected (rolling window resets on next action after 24h)
4. Event `CapsUpdated` emitted

**Edge cases:**
- Owner sets perAction > perDay → allowed (not enforced as invariant)
- Owner sets caps to 0 → operator effectively blocked from that action type

---

## Global Edge Cases

### Wrong Network
- All contract calls fail if not on Base mainnet (chain ID 8453)
- Frontend shows "Wrong Network" banner if connected wallet is on wrong chain

### Insufficient Balance
- Any swap/rebalance/buyback fails if contract balance is insufficient
- Clear error messages from revert data

### Contract Paused
- Contract does not have a pause mechanism (not OwnablePausable)
- Owner can renounce ownership via `renounceOwnership()` — but this is explicit action

### Zero Address Inputs
- `address(0)` passed as token → various reverts depending on function
- `address(0)` passed as operator → valid (zero address means no operator)

### Token Blacklisting (USDC)
- If USDC is blacklisted, USDC-related functions (buybackWithUSDC, 25% rebalance leg) will fail
- No on-chain mitigation possible — acknowledged risk

### Reentrancy
- All external-calling functions use `ReentrancyGuard`
- CEI pattern applied throughout
- No callback mechanisms in this contract

### Fee-on-Transfer Tokens
- All token accounting uses `balanceOf` deltas, never the input `amount`
- `trackedDeposits` and all accounting reflect actual received amounts

### Rebasing Tokens
- Same as fee-on-transfer: balanceOf deltas handle rebasing correctly
