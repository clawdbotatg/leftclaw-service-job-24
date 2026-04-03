// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96, int24 tick, uint16 observationIndex,
        uint16 observationCardinality, uint16 observationCardinalityNext,
        uint8 feeProtocol, bool unlocked
    );
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn; address tokenOut; uint24 fee;
        address recipient; uint256 amountIn; uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    struct ExactInputParams {
        bytes path; address recipient; uint256 amountIn; uint256 amountOutMinimum;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256);
    function exactInput(ExactInputParams calldata params) external payable returns (uint256);
}

interface IUniversalRouter {
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
}

interface IPermit2 {
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}

interface IStaking {
    function stake(uint256 amount, uint256 poolId) external;
    function unstake(uint256 amount, uint256 poolId) external;
}

interface IStateView {
    function getSlot0(bytes32 poolId) external view returns (
        uint160 sqrtPriceX96, int24 tick, uint16 protocolFee, uint24 lpFee
    );
}

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
    uint256 buyPriceUsd;
    uint256 buyMarketCapUsd;
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

contract TreasuryManagerV2 is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ==================== CORE TOKEN ADDRESSES ====================
    address public constant TUSD = 0x3d5e487B21E0569048c4D1A60E98C36e1B09DB07;
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // ==================== INFRASTRUCTURE ====================
    address public constant UNIVERSAL_ROUTER = 0x6fF5693b99212Da76ad316178A184AB56D299b43;
    address public constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    address public constant STATE_VIEW = 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71;
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public constant STAKING = 0x2a70a42BC0524aBCA9Bff59a51E7aAdB575DC89A;

    // ==================== POOL ADDRESSES ====================
    address public constant TUSD_WETH_POOL = 0xd013725b904e76394A3aB0334Da306C505D778F8;
    uint24 public constant TUSD_WETH_FEE = 10000;
    address public constant USDC_WETH_POOL = 0xd0b53D9277642d899DF5C87A3966A349A798F224;
    uint24 public constant USDC_WETH_FEE = 500;

    // ==================== PERMISSIONLESS CONSTANTS (immutable) ====================
    uint256 public constant PERMISSIONLESS_WETH_PER_ACTION = 0.5 ether;
    uint256 public constant PERMISSIONLESS_WETH_PER_DAY = 2 ether;
    uint256 public constant PERMISSIONLESS_SLIPPAGE_BPS = 300;
    uint256 public constant FALLBACK_INITIAL_DELAY = 180 days;
    uint256 public constant FALLBACK_RECURRING_DELAY = 14 days;
    uint256 public constant FALLBACK_ACTIVITY_THRESHOLD_BPS = 100;
    uint256 public constant FALLBACK_UNLOCK_INCREMENT_BPS = 200;
    uint256 public constant STRATEGIC_TRANCHE_BPS = 200;
    uint256 public constant STRATEGIC_TOKEN_COOLDOWN = 4 hours;
    uint256 public constant ROLLING_WINDOW_DURATION = 24 hours;
    uint256 public constant REBALANCE_SPLIT_TUSD_BPS = 7500;
    uint256 public constant REBALANCE_SPLIT_USDC_BPS = 2500;
    uint256 public constant ASSUMED_TOTAL_SUPPLY = 100_000_000_000e18;
    uint256 public constant BPS_DENOMINATOR = 10000;
    uint256 public constant RESCUE_DELAY = 90 days;

    // ==================== OPERATOR CAPS (owner-configurable) ====================
    address public operator;
    uint256 public buybackWethPerAction = 0.5 ether;
    uint256 public buybackWethPerDay = 2 ether;
    uint256 public buybackUsdcPerAction = 2000e6;
    uint256 public buybackUsdcPerDay = 5000e6;
    uint256 public burnTusdPerAction = 100_000_000e18;
    uint256 public burnTusdPerDay = 500_000_000e18;
    uint256 public stakeTusdPerAction = 100_000_000e18;
    uint256 public stakeTusdPerDay = 500_000_000e18;
    uint256 public operatorCooldown = 60 minutes;
    uint256 public operatorSlippageBps = 300;
    uint256 public rebalanceWethPerAction = 0.5 ether;
    uint256 public rebalanceWethPerDay = 2 ether;
    uint256 public rebalanceSlippageBps = 300;

    // ==================== ROLLING WINDOWS ====================
    RollingWindow public buybackWethWindow;
    RollingWindow public buybackUsdcWindow;
    RollingWindow public burnTusdWindow;
    RollingWindow public stakeTusdWindow;
    mapping(address => RollingWindow) public rebalanceWethWindows;
    mapping(address => RollingWindow) public permissionlessWindows;

    // ==================== OPERATOR COOLDOWN ====================
    uint256 public lastOperatorActionTimestamp;

    // ==================== STRATEGIC TOKENS ====================
    address[] public strategicTokenList;
    mapping(address => StrategicTokenConfig) public strategicTokens;
    mapping(address => bool) public isStrategicToken;

    // ==================== EVENTS ====================
    event BuybackWETH(uint256 amountIn, uint256 tusdReceived);
    event BuybackUSDC(uint256 amountIn, uint256 tusdReceived);
    event BurnTUSD(uint256 amount);
    event StakeTUSD(uint256 amount, uint256 poolId);
    event UnstakeTUSD(uint256 amount, uint256 poolId);
    event DepositStrategicToken(address indexed token, uint256 amount);
    event RebalanceStrategicToken(address indexed token, uint256 amount, uint256 wethReceived, uint256 tusdReceived, uint256 usdcReceived);
    event PermissionlessRebalance(address indexed token, uint256 amount, uint256 wethReceived);
    event RescueDeadPoolToken(address indexed token, uint256 wethReceived);
    event OperatorSet(address indexed newOperator);
    event CoreCapsUpdated();
    event RebalanceCapsUpdated();
    event FallbackRatchet(address indexed token, uint256 newFallbackUnlockedBps);

    // ==================== ERRORS ====================
    error NotOperator();
    error NotOwnerOrOperator();
    error ZeroAmount();
    error ZeroAddress();
    error TokenNotStrategic();
    error TokenNotEnabled();
    error ExceedsPerActionCap();
    error ExceedsPerDayCap();
    error CooldownNotElapsed();
    error ExceedsUnlockedAmount();
    error ExceedsTranche();
    error SlippageExceeded();
    error RescueTooEarly();
    error NoDeposits();
    error FallbackWindowNotElapsed();
    error ActivityAboveThreshold();

    // ==================== MODIFIERS ====================
    modifier onlyOperatorOrOwner() {
        if (msg.sender != owner() && msg.sender != operator) revert NotOwnerOrOperator();
        _;
    }

    modifier onlyOperator() {
        // NOTE: Also allows owner — owner has superset of operator permissions
        if (msg.sender != owner() && msg.sender != operator) revert NotOwnerOrOperator();
        _;
    }

    // ==================== CONSTRUCTOR ====================
    constructor(address _owner) Ownable(_owner) {
        // V3 Strategic Tokens
        _addStrategicToken(StrategicTokenConfig({
            enabled: true,
            token: 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b, // BNKR
            isV4: false,
            v3Pool: 0xAEC085E5A5CE8d96A7bDd3eB3A62445d4f6CE703,
            v3Fee: 10000,
            v4PoolId: bytes32(0),
            v4Currency0: address(0),
            v4Currency1: address(0),
            v4Fee: 0,
            v4TickSpacing: 0,
            v4Hooks: address(0),
            buyPriceUsd: 349700000000000, // $0.0003497
            buyMarketCapUsd: 35_000_000e18,
            trackedDeposits: 0,
            totalSold: 0,
            fallbackSold: 0,
            firstValidDepositTimestamp: 0,
            lastNormalRebalanceTimestamp: 0,
            fallbackActivatedOnce: false,
            fallbackWindowStart: 0,
            fallbackWindowPrivilegedSold: 0,
            fallbackUnlockedBps: 0
        }));

        _addStrategicToken(StrategicTokenConfig({
            enabled: true,
            token: 0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2, // DRB
            isV4: false,
            v3Pool: 0x5116773e18A9C7bB03EBB961b38678E45E238923,
            v3Fee: 10000,
            v4PoolId: bytes32(0),
            v4Currency0: address(0),
            v4Currency1: address(0),
            v4Fee: 0,
            v4TickSpacing: 0,
            v4Hooks: address(0),
            buyPriceUsd: 89090000000000, // $0.00008909
            buyMarketCapUsd: 9_000_000e18,
            trackedDeposits: 0,
            totalSold: 0,
            fallbackSold: 0,
            firstValidDepositTimestamp: 0,
            lastNormalRebalanceTimestamp: 0,
            fallbackActivatedOnce: false,
            fallbackWindowStart: 0,
            fallbackWindowPrivilegedSold: 0,
            fallbackUnlockedBps: 0
        }));

        _addStrategicToken(StrategicTokenConfig({
            enabled: true,
            token: 0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb, // Clanker
            isV4: false,
            v3Pool: 0xC1a6FBeDAe68E1472DbB91FE29B51F7a0Bd44F97,
            v3Fee: 10000,
            v4PoolId: bytes32(0),
            v4Currency0: address(0),
            v4Currency1: address(0),
            v4Fee: 0,
            v4TickSpacing: 0,
            v4Hooks: address(0),
            buyPriceUsd: 25e18, // $25
            buyMarketCapUsd: 25_000_000e18,
            trackedDeposits: 0,
            totalSold: 0,
            fallbackSold: 0,
            firstValidDepositTimestamp: 0,
            lastNormalRebalanceTimestamp: 0,
            fallbackActivatedOnce: false,
            fallbackWindowStart: 0,
            fallbackWindowPrivilegedSold: 0,
            fallbackUnlockedBps: 0
        }));
        // V4 Strategic Tokens
        address v4Hooks = 0xb429d62f8f3bFFb98CdB9569533eA23bF0Ba28CC;

        _addStrategicToken(StrategicTokenConfig({
            enabled: true,
            token: 0x50D2280441372486BeecdD328c1854743EBaCb07, // KELLY
            isV4: true,
            v3Pool: address(0),
            v3Fee: 0,
            v4PoolId: 0x7EAC33D5641697366EAEC3234147FD98BA25F01ACCA66A51A48BD129FC532145,
            v4Currency0: WETH,
            v4Currency1: 0x50D2280441372486BeecdD328c1854743EBaCb07,
            v4Fee: 8388608,
            v4TickSpacing: 200,
            v4Hooks: v4Hooks,
            buyPriceUsd: 15000000000000, // $0.000015
            buyMarketCapUsd: 1_500_000e18,
            trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
            firstValidDepositTimestamp: 0, lastNormalRebalanceTimestamp: 0,
            fallbackActivatedOnce: false, fallbackWindowStart: 0,
            fallbackWindowPrivilegedSold: 0, fallbackUnlockedBps: 0
        }));

        _addStrategicToken(StrategicTokenConfig({
            enabled: true,
            token: 0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07, // CLAWD
            isV4: true,
            v3Pool: address(0),
            v3Fee: 0,
            v4PoolId: 0x9FD58E73D8047CB14AC540ACD141D3FC1A41FB6252D674B730FAF62FE24AA8CE,
            v4Currency0: WETH,
            v4Currency1: 0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07,
            v4Fee: 8388608,
            v4TickSpacing: 200,
            v4Hooks: v4Hooks,
            buyPriceUsd: 28000000000000, // $0.000028
            buyMarketCapUsd: 2_800_000e18,
            trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
            firstValidDepositTimestamp: 0, lastNormalRebalanceTimestamp: 0,
            fallbackActivatedOnce: false, fallbackWindowStart: 0,
            fallbackWindowPrivilegedSold: 0, fallbackUnlockedBps: 0
        }));

        _addStrategicToken(StrategicTokenConfig({
            enabled: true,
            token: 0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07, // JUNO
            isV4: true,
            v3Pool: address(0),
            v3Fee: 0,
            v4PoolId: 0x1635213E2B19E459A4132DF40011638B65AE7510A35D6A88C47EBF94912C7F2E,
            v4Currency0: WETH,
            v4Currency1: 0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07,
            v4Fee: 8388608,
            v4TickSpacing: 200,
            v4Hooks: v4Hooks,
            buyPriceUsd: 8000000000000, // $0.000008
            buyMarketCapUsd: 800_000e18,
            trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
            firstValidDepositTimestamp: 0, lastNormalRebalanceTimestamp: 0,
            fallbackActivatedOnce: false, fallbackWindowStart: 0,
            fallbackWindowPrivilegedSold: 0, fallbackUnlockedBps: 0
        }));

        _addStrategicToken(StrategicTokenConfig({
            enabled: true,
            token: 0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07, // FELIX
            isV4: true,
            v3Pool: address(0),
            v3Fee: 0,
            v4PoolId: 0x6E19027912DB90892200A2B08C514921917BC55D7291EC878AA382C193B50084,
            v4Currency0: WETH,
            v4Currency1: 0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07,
            v4Fee: 8388608,
            v4TickSpacing: 200,
            v4Hooks: v4Hooks,
            buyPriceUsd: 10000000000000, // $0.00001
            buyMarketCapUsd: 1_000_000e18,
            trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
            firstValidDepositTimestamp: 0, lastNormalRebalanceTimestamp: 0,
            fallbackActivatedOnce: false, fallbackWindowStart: 0,
            fallbackWindowPrivilegedSold: 0, fallbackUnlockedBps: 0
        }));
    }

    function _addStrategicToken(StrategicTokenConfig memory config) internal {
        strategicTokenList.push(config.token);
        strategicTokens[config.token] = config;
        isStrategicToken[config.token] = true;
    }

    // ==================== OWNER FUNCTIONS ====================
    function setOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert ZeroAddress();
        operator = _operator;
        emit OperatorSet(_operator);
    }

    function setCoreCapSettings(
        uint256 _buybackWethPerAction, uint256 _buybackWethPerDay,
        uint256 _buybackUsdcPerAction, uint256 _buybackUsdcPerDay,
        uint256 _burnTusdPerAction, uint256 _burnTusdPerDay,
        uint256 _stakeTusdPerAction, uint256 _stakeTusdPerDay,
        uint256 _operatorCooldown, uint256 _operatorSlippageBps
    ) external onlyOwner {
        buybackWethPerAction = _buybackWethPerAction;
        buybackWethPerDay = _buybackWethPerDay;
        buybackUsdcPerAction = _buybackUsdcPerAction;
        buybackUsdcPerDay = _buybackUsdcPerDay;
        burnTusdPerAction = _burnTusdPerAction;
        burnTusdPerDay = _burnTusdPerDay;
        stakeTusdPerAction = _stakeTusdPerAction;
        stakeTusdPerDay = _stakeTusdPerDay;
        operatorCooldown = _operatorCooldown;
        operatorSlippageBps = _operatorSlippageBps;
        emit CoreCapsUpdated();
    }

    function setRebalanceCapSettings(
        uint256 _rebalanceWethPerAction, uint256 _rebalanceWethPerDay,
        uint256 _rebalanceSlippageBps
    ) external onlyOwner {
        rebalanceWethPerAction = _rebalanceWethPerAction;
        rebalanceWethPerDay = _rebalanceWethPerDay;
        rebalanceSlippageBps = _rebalanceSlippageBps;
        emit RebalanceCapsUpdated();
    }

    function setStrategicTokenEnabled(address token, bool _enabled) external onlyOwner {
        if (!isStrategicToken[token]) revert TokenNotStrategic();
        strategicTokens[token].enabled = _enabled;
    }

    // ==================== ROLLING WINDOW HELPERS ====================
    function _effectiveRollingAmount(RollingWindow storage w) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - w.windowStart;
        if (elapsed >= ROLLING_WINDOW_DURATION) {
            if (elapsed >= 2 * ROLLING_WINDOW_DURATION) {
                return 0;
            }
            uint256 remainingPrev = 2 * ROLLING_WINDOW_DURATION - elapsed;
            return (w.currentAmount * remainingPrev) / ROLLING_WINDOW_DURATION;
        }
        uint256 remainingCurr = ROLLING_WINDOW_DURATION - elapsed;
        uint256 prevContribution = (w.previousAmount * remainingCurr) / ROLLING_WINDOW_DURATION;
        return w.currentAmount + prevContribution;
    }

    function _consumeRollingAmount(RollingWindow storage w, uint256 amount, uint256 cap) internal {
        if (block.timestamp >= w.windowStart + ROLLING_WINDOW_DURATION) {
            w.previousAmount = w.currentAmount;
            w.currentAmount = 0;
            w.windowStart = block.timestamp;
        }
        uint256 effective = _effectiveRollingAmount(w);
        if (effective + amount > cap) revert ExceedsPerDayCap();
        w.currentAmount += amount;
    }

    function _enforceOperatorCaps(uint256 amount, uint256 perAction, RollingWindow storage window, uint256 perDay) internal {
        if (msg.sender != owner()) {
            if (amount > perAction) revert ExceedsPerActionCap();
            if (block.timestamp < lastOperatorActionTimestamp + operatorCooldown) revert CooldownNotElapsed();
            _consumeRollingAmount(window, amount, perDay);
            lastOperatorActionTimestamp = block.timestamp;
        }
    }

    // ==================== BUYBACK FUNCTIONS ====================
    function buybackWithWETH(uint256 amountIn) external nonReentrant onlyOperator {
        if (amountIn == 0) revert ZeroAmount();
        _enforceOperatorCaps(amountIn, buybackWethPerAction, buybackWethWindow, buybackWethPerDay);

        uint256 tusdBefore = IERC20(TUSD).balanceOf(address(this));

        // Approve and swap WETH -> TUSD via V3 pool
        IERC20(WETH).forceApprove(UNIVERSAL_ROUTER, amountIn);
        uint256 minOut = (amountIn * (BPS_DENOMINATOR - operatorSlippageBps)) / BPS_DENOMINATOR;
        _swapV3ExactIn(WETH, TUSD, TUSD_WETH_FEE, amountIn, minOut);

        uint256 tusdReceived = IERC20(TUSD).balanceOf(address(this)) - tusdBefore;
        emit BuybackWETH(amountIn, tusdReceived);
    }

    function buybackWithUSDC(uint256 amountIn) external nonReentrant onlyOperator {
        if (amountIn == 0) revert ZeroAmount();
        _enforceOperatorCaps(amountIn, buybackUsdcPerAction, buybackUsdcWindow, buybackUsdcPerDay);

        uint256 tusdBefore = IERC20(TUSD).balanceOf(address(this));

        // Two-hop: USDC -> WETH -> TUSD
        IERC20(USDC).forceApprove(UNIVERSAL_ROUTER, amountIn);
        bytes memory path = abi.encodePacked(USDC, USDC_WETH_FEE, WETH, TUSD_WETH_FEE, TUSD);
        uint256 minOut = (amountIn * (BPS_DENOMINATOR - operatorSlippageBps)) / BPS_DENOMINATOR;
        _swapV3ExactInMultihop(path, amountIn, minOut);

        uint256 tusdReceived = IERC20(TUSD).balanceOf(address(this)) - tusdBefore;
        emit BuybackUSDC(amountIn, tusdReceived);
    }

    // ==================== BURN FUNCTION ====================
    function burnTUSD(uint256 amount) external nonReentrant onlyOperator {
        if (amount == 0) revert ZeroAmount();
        _enforceOperatorCaps(amount, burnTusdPerAction, burnTusdWindow, burnTusdPerDay);
        IERC20(TUSD).safeTransfer(DEAD, amount);
        emit BurnTUSD(amount);
    }

    // ==================== STAKE/UNSTAKE FUNCTIONS ====================
    function stakeTUSD(uint256 amount, uint256 poolId) external nonReentrant onlyOperator {
        if (amount == 0) revert ZeroAmount();
        _enforceOperatorCaps(amount, stakeTusdPerAction, stakeTusdWindow, stakeTusdPerDay);
        IERC20(TUSD).forceApprove(STAKING, amount);
        IStaking(STAKING).stake(amount, poolId);
        emit StakeTUSD(amount, poolId);
    }

    function unstakeTUSD(uint256 amount, uint256 poolId) external nonReentrant onlyOperator {
        if (amount == 0) revert ZeroAmount();
        _enforceOperatorCaps(amount, stakeTusdPerAction, stakeTusdWindow, stakeTusdPerDay);
        IStaking(STAKING).unstake(amount, poolId);
        emit UnstakeTUSD(amount, poolId);
    }

    // ==================== DEPOSIT STRATEGIC TOKEN ====================
    function depositStrategicToken(address token, uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (!isStrategicToken[token]) revert TokenNotStrategic();

        StrategicTokenConfig storage config = strategicTokens[token];
        if (!config.enabled) revert TokenNotEnabled();

        uint256 balBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 actualAmount = IERC20(token).balanceOf(address(this)) - balBefore;

        config.trackedDeposits += actualAmount;

        if (config.firstValidDepositTimestamp == 0) {
            config.firstValidDepositTimestamp = block.timestamp;
            config.fallbackWindowStart = block.timestamp;
        }

        emit DepositStrategicToken(token, actualAmount);
    }

    // ==================== REBALANCE STRATEGIC TOKEN (Owner/Operator) ====================
    function rebalanceStrategicToken(address token, uint256 amount) external nonReentrant onlyOperatorOrOwner {
        if (amount == 0) revert ZeroAmount();
        if (!isStrategicToken[token]) revert TokenNotStrategic();

        StrategicTokenConfig storage config = strategicTokens[token];
        if (!config.enabled) revert TokenNotEnabled();
        if (config.trackedDeposits == 0) revert NoDeposits();

        // Operator constraints
        if (msg.sender != owner()) {
            // 4h per-token cooldown
            if (block.timestamp < config.lastNormalRebalanceTimestamp + STRATEGIC_TOKEN_COOLDOWN) revert CooldownNotElapsed();
            // 2% tranche check
            uint256 tranche = (config.trackedDeposits * STRATEGIC_TRANCHE_BPS) / BPS_DENOMINATOR;
            if (amount > tranche) revert ExceedsTranche();
            // Unlock check
            uint256 unlocked = _normalUnlockedAvailable(config);
            if (amount > unlocked) revert ExceedsUnlockedAmount();
        }

        // Execute rebalance
        uint256 wethReceived = _sellStrategicTokenForWETH(config, amount);

        // Operator: enforce WETH caps
        if (msg.sender != owner()) {
            if (wethReceived > rebalanceWethPerAction) revert ExceedsPerActionCap();
            _consumeRollingAmount(rebalanceWethWindows[token], wethReceived, rebalanceWethPerDay);
            lastOperatorActionTimestamp = block.timestamp;
        }

        // Split 75/25
        uint256 wethForTusd = (wethReceived * REBALANCE_SPLIT_TUSD_BPS) / BPS_DENOMINATOR;
        uint256 wethForUsdc = wethReceived - wethForTusd;

        // WETH -> TUSD (apply rebalance slippage)
        uint256 tusdBefore = IERC20(TUSD).balanceOf(address(this));
        IERC20(WETH).forceApprove(UNIVERSAL_ROUTER, wethForTusd);
        uint256 minTusd = (wethForTusd * (BPS_DENOMINATOR - rebalanceSlippageBps)) / BPS_DENOMINATOR;
        _swapV3ExactIn(WETH, TUSD, TUSD_WETH_FEE, wethForTusd, minTusd);
        uint256 tusdReceived = IERC20(TUSD).balanceOf(address(this)) - tusdBefore;

        // WETH -> USDC -> owner (apply rebalance slippage)
        uint256 usdcBefore = IERC20(USDC).balanceOf(owner());
        IERC20(WETH).forceApprove(UNIVERSAL_ROUTER, wethForUsdc);
        uint256 minUsdc = (wethForUsdc * (BPS_DENOMINATOR - rebalanceSlippageBps)) / BPS_DENOMINATOR;
        _swapV3ExactInToRecipient(WETH, USDC, USDC_WETH_FEE, wethForUsdc, minUsdc, owner());
        uint256 usdcReceived = IERC20(USDC).balanceOf(owner()) - usdcBefore;

        // Update accounting
        config.totalSold += amount;
        config.lastNormalRebalanceTimestamp = block.timestamp;
        config.fallbackWindowPrivilegedSold += amount;

        emit RebalanceStrategicToken(token, amount, wethReceived, tusdReceived, usdcReceived);
    }

    // ==================== PERMISSIONLESS REBALANCE ====================
    function permissionlessRebalanceStrategicToken(address token, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (!isStrategicToken[token]) revert TokenNotStrategic();

        StrategicTokenConfig storage config = strategicTokens[token];
        if (!config.enabled) revert TokenNotEnabled();
        if (config.trackedDeposits == 0) revert NoDeposits();

        // Check fallback window has elapsed
        _checkAndAdvanceFallbackWindow(config);

        // Permissionless unlock check
        uint256 permUnlocked = _permissionlessUnlockedAvailable(config);
        if (amount > permUnlocked) revert ExceedsUnlockedAmount();

        // 2% tranche of fallback chunk
        uint256 fallbackChunk = (config.trackedDeposits * config.fallbackUnlockedBps) / BPS_DENOMINATOR;
        uint256 tranche = (fallbackChunk * STRATEGIC_TRANCHE_BPS) / BPS_DENOMINATOR;
        if (amount > tranche) revert ExceedsTranche();

        // Execute sell
        uint256 wethReceived = _sellStrategicTokenForWETH(config, amount);

        // Immutable caps
        if (wethReceived > PERMISSIONLESS_WETH_PER_ACTION) revert ExceedsPerActionCap();
        _consumeRollingAmount(permissionlessWindows[token], wethReceived, PERMISSIONLESS_WETH_PER_DAY);

        // Split 75/25 same as normal rebalance
        uint256 wethForTusd = (wethReceived * REBALANCE_SPLIT_TUSD_BPS) / BPS_DENOMINATOR;
        uint256 wethForUsdc = wethReceived - wethForTusd;

        IERC20(WETH).forceApprove(UNIVERSAL_ROUTER, wethForTusd);
        uint256 minTusd = (wethForTusd * (BPS_DENOMINATOR - rebalanceSlippageBps)) / BPS_DENOMINATOR;
        _swapV3ExactIn(WETH, TUSD, TUSD_WETH_FEE, wethForTusd, minTusd);

        IERC20(WETH).forceApprove(UNIVERSAL_ROUTER, wethForUsdc);
        uint256 minUsdc = (wethForUsdc * (BPS_DENOMINATOR - rebalanceSlippageBps)) / BPS_DENOMINATOR;
        _swapV3ExactInToRecipient(WETH, USDC, USDC_WETH_FEE, wethForUsdc, minUsdc, owner());

        // Update accounting
        config.totalSold += amount;
        config.fallbackSold += amount;
        config.fallbackActivatedOnce = true;
        config.fallbackWindowStart = block.timestamp;
        config.fallbackWindowPrivilegedSold = 0;

        emit PermissionlessRebalance(token, amount, wethReceived);
    }

    // ==================== RESCUE DEAD POOL TOKEN ====================
    function rescueDeadPoolToken(address token, bytes calldata pathToWETH) external nonReentrant onlyOwner {
        if (!isStrategicToken[token]) revert TokenNotStrategic();
        StrategicTokenConfig storage config = strategicTokens[token];
        if (config.firstValidDepositTimestamp == 0) revert NoDeposits();
        if (block.timestamp < config.firstValidDepositTimestamp + RESCUE_DELAY) revert RescueTooEarly();

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert ZeroAmount();

        uint256 wethBefore = IERC20(WETH).balanceOf(address(this));
        IERC20(token).forceApprove(UNIVERSAL_ROUTER, balance);
        _swapV3ExactInMultihop(pathToWETH, balance, 0); // Dead pool token — minOut=0 acceptable
        uint256 wethReceived = IERC20(WETH).balanceOf(address(this)) - wethBefore;

        config.totalSold += balance;
        emit RescueDeadPoolToken(token, wethReceived);
    }

    // ==================== UNLOCK LOGIC ====================
    function _calculateRoiUnlockBps(StrategicTokenConfig storage config) internal view returns (uint256) {
        uint256 currentPrice = _getCurrentPrice(config);
        if (currentPrice == 0 || config.buyPriceUsd == 0) return 0;

        // multiplier = currentPrice * 1e18 / buyPriceUsd (both 1e18 scaled, result in 1e18)
        uint256 multiplier = (currentPrice * 1e18) / config.buyPriceUsd;

        // Need at least 10x (multiplier >= 10e18)
        if (multiplier < 10e18) return 0;

        // At 10x: 2500 bps. Each integer multiple above 10: +500 bps
        uint256 intMultiplier = multiplier / 1e18;
        uint256 unlockBps = 2500 + (intMultiplier - 10) * 500;
        if (unlockBps > BPS_DENOMINATOR) unlockBps = BPS_DENOMINATOR;
        return unlockBps;
    }

    function _calculateMcapUnlockBps(StrategicTokenConfig storage config) internal view returns (uint256) {
        uint256 currentPrice = _getCurrentPrice(config);
        if (currentPrice == 0) return 0;

        // mcap = currentPrice * ASSUMED_TOTAL_SUPPLY / 1e18
        uint256 mcap = (currentPrice * ASSUMED_TOTAL_SUPPLY) / 1e18;

        // Need at least $100M (100_000_000e18)
        if (mcap < 100_000_000e18) return 0;

        // At $100M: 2500 bps. Each $10M above: +500 bps
        uint256 above100M = (mcap - 100_000_000e18) / 10_000_000e18;
        uint256 unlockBps = 2500 + above100M * 500;
        if (unlockBps > BPS_DENOMINATOR) unlockBps = BPS_DENOMINATOR;
        return unlockBps;
    }

    function _effectiveUnlockBps(StrategicTokenConfig storage config) internal view returns (uint256) {
        uint256 roiBps = _calculateRoiUnlockBps(config);
        uint256 mcapBps = _calculateMcapUnlockBps(config);
        return roiBps > mcapBps ? roiBps : mcapBps;
    }

    function _normalUnlockedAvailable(StrategicTokenConfig storage config) internal view returns (uint256) {
        uint256 unlockBps = _effectiveUnlockBps(config);
        uint256 normalUnlockedAmount = (config.trackedDeposits * unlockBps) / BPS_DENOMINATOR;
        if (normalUnlockedAmount <= config.totalSold) return 0;
        return normalUnlockedAmount - config.totalSold;
    }

    function _permissionlessUnlockedAvailable(StrategicTokenConfig storage config) internal view returns (uint256) {
        uint256 permUnlockedAmount = (config.trackedDeposits * config.fallbackUnlockedBps) / BPS_DENOMINATOR;
        if (permUnlockedAmount <= config.fallbackSold) return 0;
        return permUnlockedAmount - config.fallbackSold;
    }

    function _checkAndAdvanceFallbackWindow(StrategicTokenConfig storage config) internal {
        uint256 windowDuration;
        if (!config.fallbackActivatedOnce) {
            windowDuration = FALLBACK_INITIAL_DELAY;
        } else {
            windowDuration = FALLBACK_RECURRING_DELAY;
        }

        if (block.timestamp < config.fallbackWindowStart + windowDuration) revert FallbackWindowNotElapsed();

        // Check activity threshold: privileged sold < 1% of trackedDeposits
        uint256 threshold = (config.trackedDeposits * FALLBACK_ACTIVITY_THRESHOLD_BPS) / BPS_DENOMINATOR;
        if (config.fallbackWindowPrivilegedSold >= threshold) revert ActivityAboveThreshold();

        // Ratchet up
        config.fallbackUnlockedBps += FALLBACK_UNLOCK_INCREMENT_BPS;
        if (config.fallbackUnlockedBps > BPS_DENOMINATOR) {
            config.fallbackUnlockedBps = BPS_DENOMINATOR;
        }

        emit FallbackRatchet(config.token, config.fallbackUnlockedBps);
    }

    // ==================== PRICE HELPERS ====================
    function _getCurrentPrice(StrategicTokenConfig storage config) internal view returns (uint256) {
        if (config.isV4) {
            return _getV4Price(config);
        } else {
            return _getV3Price(config);
        }
    }

    function _getV3Price(StrategicTokenConfig storage config) internal view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(config.v3Pool);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        address token0 = pool.token0();

        // sqrtPriceX96 = sqrt(price) * 2^96
        // price = (sqrtPriceX96 / 2^96)^2
        // If token is token0: price = token1/token0 (how much token1 per token0)
        // If token is token1: price = token0/token1 = 1/price

        uint256 price;
        if (config.token == token0) {
            // price of token0 in terms of token1 (WETH)
            price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18) >> 192;
        } else {
            // price of token1 in terms of token0 (WETH)
            if (sqrtPriceX96 == 0) return 0;
            price = (1e18 << 192) / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
        }
        return price; // Returns price in WETH terms, 1e18 scaled
    }

    function _getV4Price(StrategicTokenConfig storage config) internal view returns (uint256) {
        (uint160 sqrtPriceX96,,,) = IStateView(STATE_VIEW).getSlot0(config.v4PoolId);
        if (sqrtPriceX96 == 0) return 0;

        // V4 pools: currency0 is WETH, currency1 is the token
        // sqrtPriceX96 = sqrt(currency1/currency0) * 2^96 = sqrt(token/WETH) * 2^96
        // We want price of token in WETH: WETH per token = 1/(token/WETH) = currency0/currency1
        // price = 1 / ((sqrtPriceX96/2^96)^2)
        uint256 sqrtPrice = uint256(sqrtPriceX96);
        uint256 price = (1e18 << 192) / (sqrtPrice * sqrtPrice);
        return price; // Price in WETH, 1e18 scaled
    }

    // ==================== SWAP HELPERS ====================
    function _sellStrategicTokenForWETH(StrategicTokenConfig storage config, uint256 amount) internal returns (uint256 wethReceived) {
        uint256 wethBefore = IERC20(WETH).balanceOf(address(this));

        if (config.isV4) {
            _swapV4(config, amount);
        } else {
            IERC20(config.token).forceApprove(UNIVERSAL_ROUTER, amount);
            _swapV3ExactIn(config.token, WETH, config.v3Fee, amount, 0); // Slippage checked via WETH caps post-swap
        }

        wethReceived = IERC20(WETH).balanceOf(address(this)) - wethBefore;
    }

    function _swapV3ExactIn(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint256 minOut) internal {
        // V3_SWAP_EXACT_IN command = 0x00
        bytes memory path = abi.encodePacked(tokenIn, fee, tokenOut);
        bytes memory input = abi.encode(
            address(this), // recipient
            amountIn,
            minOut,
            path,
            true // payerIsUser
        );
        bytes memory commands = hex"00";
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = input;
        IUniversalRouter(UNIVERSAL_ROUTER).execute(commands, inputs, block.timestamp);
    }

    function _swapV3ExactInToRecipient(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint256 minOut, address recipient) internal {
        bytes memory path = abi.encodePacked(tokenIn, fee, tokenOut);
        bytes memory input = abi.encode(
            recipient,
            amountIn,
            minOut,
            path,
            true
        );
        bytes memory commands = hex"00";
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = input;
        IUniversalRouter(UNIVERSAL_ROUTER).execute(commands, inputs, block.timestamp);
    }

    function _swapV3ExactInMultihop(bytes memory path, uint256 amountIn, uint256 minOut) internal {
        bytes memory input = abi.encode(
            address(this),
            amountIn,
            minOut,
            path,
            true
        );
        bytes memory commands = hex"00";
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = input;
        IUniversalRouter(UNIVERSAL_ROUTER).execute(commands, inputs, block.timestamp);
    }

    function _swapV4(StrategicTokenConfig storage config, uint256 amount) internal {
        // Step 1: Approve token to Permit2
        IERC20(config.token).forceApprove(PERMIT2, amount);

        // Step 2: Permit2 approve to Universal Router
        IPermit2(PERMIT2).approve(config.token, UNIVERSAL_ROUTER, uint160(amount), uint48(block.timestamp + 1800));

        // Step 3: Execute V4 swap via Universal Router
        // V4_SWAP command = 0x10
        // Build V4SwapExactInputSingle params
        // PathKey: intermediateCurrency, fee, tickSpacing, hooks, hookData
        // For selling token -> WETH: zeroForOne depends on token ordering
        // currency0 = WETH, currency1 = token
        // Selling token (currency1) for WETH (currency0) means zeroForOne = false

        bool zeroForOne = false; // selling currency1 (token) for currency0 (WETH)
        int128 amountSpecified = -int128(int256(amount)); // negative = exactInput

        // Encode V4_SWAP = command 0x10
        // actions: SWAP_EXACT_IN_SINGLE = 0x06, SETTLE_ALL = 0x0c, TAKE_ALL = 0x0e
        bytes memory actions = abi.encodePacked(uint8(0x06), uint8(0x0c), uint8(0x0e));

        // PoolKey struct
        bytes memory poolKey = abi.encode(
            config.v4Currency0,
            config.v4Currency1,
            config.v4Fee,
            config.v4TickSpacing,
            config.v4Hooks
        );

        // SWAP_EXACT_IN_SINGLE params
        bytes memory swapParams = abi.encode(
            poolKey,
            zeroForOne,
            amountSpecified,
            uint160(0), // sqrtPriceLimitX96 = 0 (no limit)
            bytes("") // hookData
        );

        // SETTLE_ALL params: token being sold (currency1)
        bytes memory settleParams = abi.encode(config.token, uint256(amount));

        // TAKE_ALL params: WETH going to this contract
        bytes memory takeParams = abi.encode(WETH, uint256(0)); // minAmount = 0

        bytes[] memory v4Params = new bytes[](3);
        v4Params[0] = swapParams;
        v4Params[1] = settleParams;
        v4Params[2] = takeParams;

        bytes memory v4Input = abi.encode(actions, v4Params);

        bytes memory commands = hex"10";
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = v4Input;

        IUniversalRouter(UNIVERSAL_ROUTER).execute(commands, inputs, block.timestamp);
    }

    // ==================== VIEW FUNCTIONS ====================
    function getKnownTokens() external view returns (TokenInfo[] memory) {
        uint256 totalTokens = 3 + strategicTokenList.length; // 3 core + strategic
        TokenInfo[] memory tokens = new TokenInfo[](totalTokens);

        // Core tokens
        tokens[0] = TokenInfo({
            token: TUSD, enabled: true, isCore: true, isV4: false,
            buyPriceUsd: 0, buyMarketCapUsd: 0,
            currentBalance: IERC20(TUSD).balanceOf(address(this)),
            trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
            effectiveUnlockedBps: 0, fallbackUnlockedBps: 0,
            lastNormalRebalanceTimestamp: 0, firstValidDepositTimestamp: 0,
            fallbackActivatedOnce: false, fallbackWindowStart: 0
        });
        tokens[1] = TokenInfo({
            token: WETH, enabled: true, isCore: true, isV4: false,
            buyPriceUsd: 0, buyMarketCapUsd: 0,
            currentBalance: IERC20(WETH).balanceOf(address(this)),
            trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
            effectiveUnlockedBps: 0, fallbackUnlockedBps: 0,
            lastNormalRebalanceTimestamp: 0, firstValidDepositTimestamp: 0,
            fallbackActivatedOnce: false, fallbackWindowStart: 0
        });
        tokens[2] = TokenInfo({
            token: USDC, enabled: true, isCore: true, isV4: false,
            buyPriceUsd: 0, buyMarketCapUsd: 0,
            currentBalance: IERC20(USDC).balanceOf(address(this)),
            trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
            effectiveUnlockedBps: 0, fallbackUnlockedBps: 0,
            lastNormalRebalanceTimestamp: 0, firstValidDepositTimestamp: 0,
            fallbackActivatedOnce: false, fallbackWindowStart: 0
        });

        // Strategic tokens
        for (uint256 i = 0; i < strategicTokenList.length; i++) {
            StrategicTokenConfig storage config = strategicTokens[strategicTokenList[i]];
            tokens[3 + i] = TokenInfo({
                token: config.token,
                enabled: config.enabled,
                isCore: false,
                isV4: config.isV4,
                buyPriceUsd: config.buyPriceUsd,
                buyMarketCapUsd: config.buyMarketCapUsd,
                currentBalance: IERC20(config.token).balanceOf(address(this)),
                trackedDeposits: config.trackedDeposits,
                totalSold: config.totalSold,
                fallbackSold: config.fallbackSold,
                effectiveUnlockedBps: _effectiveUnlockBps(config),
                fallbackUnlockedBps: config.fallbackUnlockedBps,
                lastNormalRebalanceTimestamp: config.lastNormalRebalanceTimestamp,
                firstValidDepositTimestamp: config.firstValidDepositTimestamp,
                fallbackActivatedOnce: config.fallbackActivatedOnce,
                fallbackWindowStart: config.fallbackWindowStart
            });
        }

        return tokens;
    }

    function getKnownToken(address token) external view returns (TokenInfo memory) {
        if (token == TUSD || token == WETH || token == USDC) {
            return TokenInfo({
                token: token, enabled: true, isCore: true, isV4: false,
                buyPriceUsd: 0, buyMarketCapUsd: 0,
                currentBalance: IERC20(token).balanceOf(address(this)),
                trackedDeposits: 0, totalSold: 0, fallbackSold: 0,
                effectiveUnlockedBps: 0, fallbackUnlockedBps: 0,
                lastNormalRebalanceTimestamp: 0, firstValidDepositTimestamp: 0,
                fallbackActivatedOnce: false, fallbackWindowStart: 0
            });
        }

        if (!isStrategicToken[token]) revert TokenNotStrategic();
        StrategicTokenConfig storage config = strategicTokens[token];
        return TokenInfo({
            token: config.token, enabled: config.enabled, isCore: false, isV4: config.isV4,
            buyPriceUsd: config.buyPriceUsd, buyMarketCapUsd: config.buyMarketCapUsd,
            currentBalance: IERC20(config.token).balanceOf(address(this)),
            trackedDeposits: config.trackedDeposits, totalSold: config.totalSold,
            fallbackSold: config.fallbackSold,
            effectiveUnlockedBps: _effectiveUnlockBps(config),
            fallbackUnlockedBps: config.fallbackUnlockedBps,
            lastNormalRebalanceTimestamp: config.lastNormalRebalanceTimestamp,
            firstValidDepositTimestamp: config.firstValidDepositTimestamp,
            fallbackActivatedOnce: config.fallbackActivatedOnce,
            fallbackWindowStart: config.fallbackWindowStart
        });
    }

    function getStrategicTokenCount() external view returns (uint256) {
        return strategicTokenList.length;
    }
}
