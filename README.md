# TreasuryManagerV2

Onchain treasury management for ₸USD (TurboUSD) on Base.

**Contract:** [`0x634328008345f1e63571dd24cd818a8f1947b628`](https://basescan.org/address/0x634328008345f1e63571dd24cd818a8f1947b628) — Base (8453)

**Live App:** [IPFS](https://bafybeihrcfbkavocnmfp3ztvrt6nrjece6xc3s5w6hqiykhdsqsyhscd5e.ipfs.community.bgipfs.com/)

---

## Architecture

### Core Operations
- **Buyback:** Swap WETH or USDC → TUSD via Uniswap V3 pools through Universal Router
- **Burn:** Send TUSD to dead address (0xdead...)
- **Stake/Unstake:** Deposit TUSD into staking contract
- **Operator caps:** Rolling-window rate limits per action/day with configurable cooldowns

### Strategic Token Management (7 tokens)
The contract holds 7 strategic tokens (BNKR, DRB, Clanker, KELLY, CLAWD, JUNO, FELIX) with rebalance mechanics:

- **Normal rebalance** (owner/operator): Sell strategic token → WETH, split WETH into TUSD (85%) + USDC to owner (15%). Rate-limited by tranche (5% of deposits per action) and rolling WETH caps.
- **Permissionless rebalance** (anyone): Unlocks gradually via fallback ratchet when operator is inactive for 14+ days. Immutable caps: 0.1 WETH/action, 1 WETH/day, 5% slippage.
- **V3 + V4 routing:** Tokens with V3 pools swap directly; tokens with V4 pools route through PoolManager via Permit2 → Universal Router.

### Routing
- V3 tokens: `token → WETH` via `IUniversalRouter.execute` (V3_SWAP_EXACT_IN)
- V4 tokens: `token → WETH` via Permit2 approval + `IUniversalRouter.execute` (V4_SWAP commands with SETTLE_ALL/TAKE_ALL)
- TUSD buyback: `WETH → TUSD` (V3, 10000 fee tier)
- USDC buyback: `USDC → WETH → TUSD` (V3 multihop)

### Security Model
- **Ownable2Step:** Two-phase ownership transfer
- **ReentrancyGuard:** All state-modifying functions
- **Rolling windows:** Per-day and per-action caps for all operator actions
- **Operator cooldown:** Minimum time between operator actions
- **Slippage protection:** Configurable `operatorSlippageBps` and `rebalanceSlippageBps` on all swaps
- **Rescue delay:** 90-day dead pool rescue for tokens with no pool activity
- **Permissionless fallback:** If operator goes dark, anyone can rebalance with immutable conservative limits
- **SafeERC20 forceApprove:** All token approvals use OZ 5.6.1 `forceApprove()`

---

## Run Locally

```bash
# Clone and install
git clone https://github.com/clawdbotatg/leftclaw-service-job-24
cd leftclaw-service-job-24
yarn install

# Run tests (56 tests)
cd packages/foundry
forge test

# Run frontend
cd ../nextjs
yarn dev
# Open http://localhost:3000
```

The frontend reads from the deployed contract on Base via `externalContracts.ts`. Connect a Base wallet to interact.

---

## Deploy

### Contract
```bash
cd packages/foundry
# Edit DeployYourContract.s.sol OWNER constant if needed
forge script script/DeployYourContract.s.sol \
  --rpc-url https://mainnet.base.org \
  --broadcast \
  --private-key <deployer-private-key>

# Verify
forge verify-contract <deployed-address> TreasuryManagerV2 \
  --chain-id 8453 \
  --constructor-args $(cast abi-encode "constructor(address)" <owner-address>)
```

### Frontend (IPFS via bgipfs)
```bash
cd packages/nextjs
rm -rf out .next
NEXT_PUBLIC_IPFS_BUILD=true NODE_OPTIONS="--require ./polyfill-localstorage.cjs" npm run build
bgipfs upload out --config ~/.bgipfs/credentials.json
```

---

## Post-Deployment Setup

After deploying, the owner should:
1. Call `setOperator(address)` to designate an operator bot
2. Optionally adjust caps via `setCoreCapSettings(...)` and `setRebalanceCapSettings(...)`
3. Deposit strategic tokens via `depositStrategicToken(token, amount)` — anyone can call, but deposits are tracked for rebalance limits

---

## Key Constants

| Parameter | Value |
|-----------|-------|
| Buyback WETH/day | 2 ETH |
| Buyback USDC/day | 5000 USDC |
| Operator cooldown | 5 min |
| Slippage (buyback) | 3% |
| Slippage (rebalance) | 3% |
| Strategic tranche | 5% of deposits |
| Permissionless cap | 0.1 WETH/action, 1 WETH/day |
| Permissionless slippage | 5% |
| Fallback initial delay | 14 days |
| Rescue delay | 90 days |
