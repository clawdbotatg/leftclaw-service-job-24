// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/TreasuryManagerV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 for testing
contract MockERC20 is ERC20 {
    uint8 private _dec;
    constructor(string memory name, string memory symbol, uint8 dec_) ERC20(name, symbol) {
        _dec = dec_;
    }
    function decimals() public view override returns (uint8) { return _dec; }
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

// Fee-on-transfer token
contract FeeOnTransferToken is ERC20 {
    uint256 public feeBps = 100; // 1%
    constructor() ERC20("FeeToken", "FEE") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * feeBps) / 10000;
        _burn(msg.sender, fee);
        return super.transfer(to, amount - fee);
    }
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * feeBps) / 10000;
        _burn(from, fee);
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount - fee);
        return true;
    }
}

// Mock Universal Router that simulates swaps
contract MockUniversalRouter {
    // Exchange rate: 1 WETH = 1000 TUSD, 1 WETH = 2000 USDC
    mapping(address => mapping(address => uint256)) public rates;
    address public weth;
    address public tusd;
    address public usdc;

    constructor(address _weth, address _tusd, address _usdc) {
        weth = _weth;
        tusd = _tusd;
        usdc = _usdc;
    }

    function setRate(address from, address to, uint256 rate) external {
        rates[from][to] = rate;
    }

    function execute(bytes calldata, bytes[] calldata inputs, uint256) external payable {
        // Simple mock: just transfer based on pre-set rates
        // Decode the first input to get amounts
        (address recipient, uint256 amountIn, , bytes memory path, ) = abi.decode(inputs[0], (address, uint256, uint256, bytes, bool));

        // Extract tokenIn from path (first 20 bytes)
        address tokenIn;
        assembly { tokenIn := shr(96, mload(add(path, 32))) }

        // Extract tokenOut from path (last 20 bytes)
        address tokenOut;
        uint256 pathLen = path.length;
        assembly { tokenOut := shr(96, mload(add(add(path, 32), sub(pathLen, 20)))) }

        // Transfer tokenIn from msg.sender
        MockERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Calculate output
        uint256 rate = rates[tokenIn][tokenOut];
        uint256 amountOut;
        if (rate > 0) {
            amountOut = (amountIn * rate) / 1e18;
        } else {
            amountOut = amountIn; // 1:1 fallback
        }

        // Mint and transfer output
        MockERC20(tokenOut).mint(recipient, amountOut);
    }
}

// Mock Staking contract
contract MockStaking {
    mapping(address => mapping(uint256 => uint256)) public staked;

    function stake(uint256 amount, uint256 poolId) external {
        IERC20 tusd = IERC20(msg.sender); // Will be called by TreasuryManager
        staked[msg.sender][poolId] += amount;
    }

    function unstake(uint256 amount, uint256 poolId) external {
        staked[msg.sender][poolId] -= amount;
    }
}

// Mock V3 Pool
contract MockV3Pool {
    uint160 public sqrtPriceX96;
    address public token0Addr;
    address public token1Addr;

    constructor(address _token0, address _token1, uint160 _sqrtPriceX96) {
        token0Addr = _token0;
        token1Addr = _token1;
        sqrtPriceX96 = _sqrtPriceX96;
    }

    function setSqrtPriceX96(uint160 _sqrtPriceX96) external {
        sqrtPriceX96 = _sqrtPriceX96;
    }

    function slot0() external view returns (
        uint160, int24, uint16, uint16, uint16, uint8, bool
    ) {
        return (sqrtPriceX96, 0, 0, 0, 0, 0, true);
    }

    function token0() external view returns (address) { return token0Addr; }
    function token1() external view returns (address) { return token1Addr; }
}

// Mock StateView for V4
contract MockStateView {
    mapping(bytes32 => uint160) public prices;

    function setPrice(bytes32 poolId, uint160 sqrtPriceX96) external {
        prices[poolId] = sqrtPriceX96;
    }

    function getSlot0(bytes32 poolId) external view returns (
        uint160 sqrtPriceX96, int24 tick, uint16 protocolFee, uint24 lpFee
    ) {
        return (prices[poolId], 0, 0, 0);
    }
}

// Mock Permit2
contract MockPermit2 {
    function approve(address, address, uint160, uint48) external {}
}

contract TreasuryManagerV2Test is Test {
    TreasuryManagerV2 public treasury;
    MockERC20 public tusd;
    MockERC20 public weth;
    MockERC20 public usdc;
    MockERC20 public bnkr;
    MockERC20 public drb;
    MockERC20 public clanker;
    MockERC20 public kelly;
    MockERC20 public clawd;
    MockERC20 public juno;
    MockERC20 public felix;
    MockUniversalRouter public router;
    MockStaking public staking;
    MockV3Pool public tusdWethPool;
    MockV3Pool public bnkrPool;
    MockStateView public stateView;
    MockPermit2 public permit2;

    address public owner = address(0x1111);
    address public operatorAddr = address(0x2222);
    address public user = address(0x3333);

    function setUp() public {
        // Deploy mock tokens at the exact addresses needed
        // We'll use vm.etch to place code at the expected addresses

        // First deploy normally then set up treasury with mocks
        // Since treasury hardcodes addresses, we need to deploy mocks AT those addresses
        // Use vm.etch approach

        // Deploy mock tokens
        tusd = new MockERC20("TurboUSD", "TUSD", 18);
        weth = new MockERC20("Wrapped ETH", "WETH", 18);
        usdc = new MockERC20("USD Coin", "USDC", 6);
        bnkr = new MockERC20("Bankr", "BNKR", 18);
        drb = new MockERC20("DRB", "DRB", 18);
        clanker = new MockERC20("Clanker", "CLANKER", 18);
        kelly = new MockERC20("Kelly", "KELLY", 18);
        clawd = new MockERC20("Clawd", "CLAWD", 18);
        juno = new MockERC20("Juno", "JUNO", 18);
        felix = new MockERC20("Felix", "FELIX", 18);

        // Deploy mock infrastructure
        router = new MockUniversalRouter(address(weth), address(tusd), address(usdc));
        staking = new MockStaking();
        stateView = new MockStateView();
        permit2 = new MockPermit2();

        // Place mock code at expected addresses using vm.etch
        vm.etch(0x3d5e487B21E0569048c4D1A60E98C36e1B09DB07, address(tusd).code); // TUSD
        vm.etch(0x4200000000000000000000000000000000000006, address(weth).code); // WETH
        vm.etch(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, address(usdc).code); // USDC
        vm.etch(0x6fF5693b99212Da76ad316178A184AB56D299b43, address(router).code); // UNIVERSAL_ROUTER
        vm.etch(0x2a70a42BC0524aBCA9Bff59a51E7aAdB575DC89A, address(staking).code); // STAKING
        vm.etch(0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71, address(stateView).code); // STATE_VIEW
        vm.etch(0x000000000022D473030F116dDEE9F6B43aC78BA3, address(permit2).code); // PERMIT2

        // Etch strategic token addresses
        vm.etch(0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b, address(bnkr).code); // BNKR
        vm.etch(0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2, address(drb).code); // DRB
        vm.etch(0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb, address(clanker).code); // Clanker
        vm.etch(0x50D2280441372486BeecdD328c1854743EBaCb07, address(kelly).code); // KELLY
        vm.etch(0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07, address(clawd).code); // CLAWD
        vm.etch(0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07, address(juno).code); // JUNO
        vm.etch(0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07, address(felix).code); // FELIX

        // Deploy TreasuryManagerV2
        vm.prank(owner);
        treasury = new TreasuryManagerV2(owner);

        // Set operator
        vm.prank(owner);
        treasury.setOperator(operatorAddr);

        // Setup mock router rates
        // Set rates on the router at the Universal Router address
        MockUniversalRouter routerAtAddr = MockUniversalRouter(0x6fF5693b99212Da76ad316178A184AB56D299b43);

        // Warp to a reasonable timestamp so cooldown logic works
        vm.warp(1_700_000_000);

        // Fund treasury with tokens for testing
        _mintAtAddress(0x4200000000000000000000000000000000000006, address(treasury), 100 ether); // WETH
        _mintAtAddress(0x3d5e487B21E0569048c4D1A60E98C36e1B09DB07, address(treasury), 1_000_000_000e18); // TUSD
        _mintAtAddress(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, address(treasury), 100_000e6); // USDC
    }

    function _mintAtAddress(address token, address to, uint256 amount) internal {
        // Use deal to set balances at specific addresses
        deal(token, to, amount);
    }

    // ==================== CONSTRUCTOR TESTS ====================
    function test_constructor_setsOwner() public view {
        assertEq(treasury.owner(), owner);
    }

    function test_constructor_strategicTokenCount() public view {
        assertEq(treasury.getStrategicTokenCount(), 7);
    }

    function test_constructor_bnkrConfigured() public view {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        assertTrue(treasury.isStrategicToken(bnkrAddr));
        (bool enabled, address token, bool isV4,,,,,,,,,uint256 buyPriceUsd,,,,,,,,,,) = treasury.strategicTokens(bnkrAddr);
        assertTrue(enabled);
        assertEq(token, bnkrAddr);
        assertFalse(isV4);
        assertEq(buyPriceUsd, 349700000000000);
    }

    function test_constructor_kellyV4Configured() public view {
        address kellyAddr = 0x50D2280441372486BeecdD328c1854743EBaCb07;
        assertTrue(treasury.isStrategicToken(kellyAddr));
        (bool enabled,, bool isV4,,,,,,,,, uint256 buyPriceUsd,,,,,,,,,,) = treasury.strategicTokens(kellyAddr);
        assertTrue(enabled);
        assertTrue(isV4);
        assertEq(buyPriceUsd, 15000000000000);
    }

    // ==================== OPERATOR TESTS ====================
    function test_setOperator() public {
        address newOp = address(0x9999);
        vm.prank(owner);
        treasury.setOperator(newOp);
        assertEq(treasury.operator(), newOp);
    }

    function test_setOperator_revertNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        treasury.setOperator(user);
    }

    function test_setOperator_revertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(TreasuryManagerV2.ZeroAddress.selector);
        treasury.setOperator(address(0));
    }

    // ==================== CAP SETTINGS TESTS ====================
    function test_setCoreCapSettings() public {
        vm.prank(owner);
        treasury.setCoreCapSettings(
            1 ether, 5 ether,
            5000e6, 10000e6,
            200_000_000e18, 1_000_000_000e18,
            200_000_000e18, 1_000_000_000e18,
            30 minutes, 500
        );
        assertEq(treasury.buybackWethPerAction(), 1 ether);
        assertEq(treasury.buybackWethPerDay(), 5 ether);
        assertEq(treasury.operatorSlippageBps(), 500);
    }

    function test_setCoreCapSettings_revertNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        treasury.setCoreCapSettings(1, 1, 1, 1, 1, 1, 1, 1, 1, 1);
    }

    function test_setRebalanceCapSettings() public {
        vm.prank(owner);
        treasury.setRebalanceCapSettings(1 ether, 5 ether, 500);
        assertEq(treasury.rebalanceWethPerAction(), 1 ether);
        assertEq(treasury.rebalanceSlippageBps(), 500);
    }

    // ==================== BURN TESTS ====================
    function test_burnTUSD_operator() public {
        uint256 balBefore = IERC20(treasury.TUSD()).balanceOf(address(treasury));
        vm.prank(operatorAddr);
        treasury.burnTUSD(1_000_000e18);
        uint256 balAfter = IERC20(treasury.TUSD()).balanceOf(address(treasury));
        assertEq(balBefore - balAfter, 1_000_000e18);
    }

    function test_burnTUSD_owner_bypassCaps() public {
        // Owner can burn more than per-action cap
        vm.prank(owner);
        treasury.burnTUSD(200_000_000e18); // Above default 100M cap
    }

    function test_burnTUSD_revertZeroAmount() public {
        vm.prank(operatorAddr);
        vm.expectRevert(TreasuryManagerV2.ZeroAmount.selector);
        treasury.burnTUSD(0);
    }

    function test_burnTUSD_revertExceedsPerAction() public {
        vm.prank(operatorAddr);
        vm.expectRevert(TreasuryManagerV2.ExceedsPerActionCap.selector);
        treasury.burnTUSD(200_000_000e18);
    }

    function test_burnTUSD_revertCooldown() public {
        vm.prank(operatorAddr);
        treasury.burnTUSD(1_000_000e18);

        // Try again immediately - should fail
        vm.prank(operatorAddr);
        vm.expectRevert(TreasuryManagerV2.CooldownNotElapsed.selector);
        treasury.burnTUSD(1_000_000e18);
    }

    function test_burnTUSD_afterCooldown() public {
        vm.prank(operatorAddr);
        treasury.burnTUSD(1_000_000e18);

        // Wait for cooldown
        vm.warp(block.timestamp + 61 minutes);

        vm.prank(operatorAddr);
        treasury.burnTUSD(1_000_000e18);
    }

    function test_burnTUSD_revertNotOperator() public {
        vm.prank(user);
        vm.expectRevert(TreasuryManagerV2.NotOperator.selector);
        treasury.burnTUSD(1_000_000e18);
    }

    // ==================== DEPOSIT STRATEGIC TOKEN TESTS ====================
    function test_depositStrategicToken() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        deal(bnkrAddr, owner, 1_000_000e18);

        vm.startPrank(owner);
        IERC20(bnkrAddr).approve(address(treasury), 1_000_000e18);
        treasury.depositStrategicToken(bnkrAddr, 1_000_000e18);
        vm.stopPrank();

        (,,,,,,,,,,,,, uint256 trackedDeposits,,, uint256 firstValidDepositTimestamp,,,,,) = treasury.strategicTokens(bnkrAddr);
        assertEq(trackedDeposits, 1_000_000e18);
        assertGt(firstValidDepositTimestamp, 0);
    }

    function test_depositStrategicToken_revertNotOwner() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        deal(bnkrAddr, operatorAddr, 1_000_000e18);

        vm.startPrank(operatorAddr);
        IERC20(bnkrAddr).approve(address(treasury), 1_000_000e18);
        vm.expectRevert();
        treasury.depositStrategicToken(bnkrAddr, 1_000_000e18);
        vm.stopPrank();
    }

    function test_depositStrategicToken_revertNotStrategic() public {
        vm.prank(owner);
        vm.expectRevert(TreasuryManagerV2.TokenNotStrategic.selector);
        treasury.depositStrategicToken(address(0x9999), 100);
    }

    function test_depositStrategicToken_revertZeroAmount() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(owner);
        vm.expectRevert(TreasuryManagerV2.ZeroAmount.selector);
        treasury.depositStrategicToken(bnkrAddr, 0);
    }

    function test_depositStrategicToken_setsFirstDepositTimestamp() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        deal(bnkrAddr, owner, 2_000_000e18);

        vm.startPrank(owner);
        IERC20(bnkrAddr).approve(address(treasury), 2_000_000e18);

        // First deposit sets timestamp
        treasury.depositStrategicToken(bnkrAddr, 1_000_000e18);
        (,,,,,,,,,,,,,,,, uint256 ts1,,,,,) = treasury.strategicTokens(bnkrAddr);
        uint256 firstTs = ts1;

        // Second deposit doesn't change it
        vm.warp(block.timestamp + 1 hours);
        treasury.depositStrategicToken(bnkrAddr, 1_000_000e18);
        (,,,,,,,,,,,,,,,, uint256 ts2,,,,,) = treasury.strategicTokens(bnkrAddr);
        assertEq(ts2, firstTs);

        vm.stopPrank();
    }

    // ==================== ROLLING WINDOW TESTS ====================
    function test_rollingWindow_dailyCap() public {
        // Burn up to the daily cap using explicit timestamps
        uint256 perAction = treasury.burnTusdPerAction();
        uint256 baseTime = block.timestamp;

        // 5 burns of 100M each = 500M (daily cap), with 65min gap to ensure cooldown passes
        for (uint256 i = 0; i < 5; i++) {
            uint256 newTime = baseTime + (i + 1) * 65 minutes;
            vm.warp(newTime);
            vm.prank(operatorAddr);
            treasury.burnTUSD(perAction);
        }

        // 6th should fail due to daily cap
        vm.warp(baseTime + 6 * 65 minutes);
        vm.prank(operatorAddr);
        vm.expectRevert(TreasuryManagerV2.ExceedsPerDayCap.selector);
        treasury.burnTUSD(perAction);
    }

    function test_rollingWindow_resetsAfter24Hours() public {
        uint256 perAction = treasury.burnTusdPerAction();

        // Use some of daily cap
        vm.prank(operatorAddr);
        treasury.burnTUSD(perAction);

        // Wait 25 hours
        vm.warp(block.timestamp + 25 hours);

        // Should work again - window has rolled
        vm.prank(operatorAddr);
        treasury.burnTUSD(perAction);
    }

    // ==================== VIEW FUNCTION TESTS ====================
    function test_getKnownTokens() public {
        // Setup mock pools for V3 tokens so slot0() calls work
        _setupMockPools();
        TokenInfo[] memory tokens = treasury.getKnownTokens();
        assertEq(tokens.length, 10); // 3 core + 7 strategic
        assertTrue(tokens[0].isCore);
        assertTrue(tokens[1].isCore);
        assertTrue(tokens[2].isCore);
        assertFalse(tokens[3].isCore);
    }

    function test_getKnownToken_core() public view {
        TokenInfo memory info = treasury.getKnownToken(treasury.TUSD());
        assertTrue(info.isCore);
        assertTrue(info.enabled);
    }

    function test_getKnownToken_strategic() public {
        _setupMockPools();
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        TokenInfo memory info = treasury.getKnownToken(bnkrAddr);
        assertFalse(info.isCore);
        assertTrue(info.enabled);
        assertFalse(info.isV4);
        assertEq(info.buyPriceUsd, 349700000000000);
    }

    function test_getKnownToken_revertUnknown() public {
        vm.expectRevert(TreasuryManagerV2.TokenNotStrategic.selector);
        treasury.getKnownToken(address(0x9999));
    }

    function _setupMockPools() internal {
        // Create mock V3 pools and etch them at the pool addresses
        // BNKR pool: token0=BNKR, token1=WETH, sqrtPriceX96 = some value
        MockV3Pool bnkrMock = new MockV3Pool(
            0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b,
            0x4200000000000000000000000000000000000006,
            79228162514264337593543950336 // ~1:1 price
        );
        vm.etch(0xAEC085E5A5CE8d96A7bDd3eB3A62445d4f6CE703, address(bnkrMock).code);
        // Copy storage slots
        _copyPoolStorage(address(bnkrMock), 0xAEC085E5A5CE8d96A7bDd3eB3A62445d4f6CE703);

        // DRB pool
        MockV3Pool drbMock = new MockV3Pool(
            0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2,
            0x4200000000000000000000000000000000000006,
            79228162514264337593543950336
        );
        vm.etch(0x5116773e18A9C7bB03EBB961b38678E45E238923, address(drbMock).code);
        _copyPoolStorage(address(drbMock), 0x5116773e18A9C7bB03EBB961b38678E45E238923);

        // Clanker pool
        MockV3Pool clankerMock = new MockV3Pool(
            0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb,
            0x4200000000000000000000000000000000000006,
            79228162514264337593543950336
        );
        vm.etch(0xC1a6FBeDAe68E1472DbB91FE29B51F7a0Bd44F97, address(clankerMock).code);
        _copyPoolStorage(address(clankerMock), 0xC1a6FBeDAe68E1472DbB91FE29B51F7a0Bd44F97);

        // Mock StateView for V4 tokens - etch and set storage
        MockStateView sv = new MockStateView();
        sv.setPrice(0x7EAC33D5641697366EAEC3234147FD98BA25F01ACCA66A51A48BD129FC532145, 79228162514264337593543950336);
        sv.setPrice(0x9FD58E73D8047CB14AC540ACD141D3FC1A41FB6252D674B730FAF62FE24AA8CE, 79228162514264337593543950336);
        sv.setPrice(0x1635213E2B19E459A4132DF40011638B65AE7510A35D6A88C47EBF94912C7F2E, 79228162514264337593543950336);
        sv.setPrice(0x6E19027912DB90892200A2B08C514921917BC55D7291EC878AA382C193B50084, 79228162514264337593543950336);
        vm.etch(0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71, address(sv).code);
        // Copy storage for all pool IDs
        for (uint256 i = 0; i < 256; i++) {
            bytes32 slot = bytes32(i);
            bytes32 val = vm.load(address(sv), slot);
            if (val != bytes32(0)) {
                vm.store(0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71, slot, val);
            }
        }
        // Also copy mapping storage for each pool ID
        _copyStateViewPrice(address(sv), 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71, 0x7EAC33D5641697366EAEC3234147FD98BA25F01ACCA66A51A48BD129FC532145);
        _copyStateViewPrice(address(sv), 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71, 0x9FD58E73D8047CB14AC540ACD141D3FC1A41FB6252D674B730FAF62FE24AA8CE);
        _copyStateViewPrice(address(sv), 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71, 0x1635213E2B19E459A4132DF40011638B65AE7510A35D6A88C47EBF94912C7F2E);
        _copyStateViewPrice(address(sv), 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71, 0x6E19027912DB90892200A2B08C514921917BC55D7291EC878AA382C193B50084);
    }

    function _copyPoolStorage(address src, address dst) internal {
        // Copy slots 0, 1, 2 (sqrtPriceX96, token0Addr, token1Addr)
        for (uint256 i = 0; i < 3; i++) {
            bytes32 val = vm.load(src, bytes32(i));
            vm.store(dst, bytes32(i), val);
        }
    }

    function _copyStateViewPrice(address src, address dst, bytes32 poolId) internal {
        // mapping(bytes32 => uint160) prices at slot 0
        bytes32 slot = keccak256(abi.encode(poolId, uint256(0)));
        bytes32 val = vm.load(src, slot);
        vm.store(dst, slot, val);
    }

    function test_getStrategicTokenCount() public view {
        assertEq(treasury.getStrategicTokenCount(), 7);
    }

    // ==================== UNLOCK CALCULATION TESTS ====================
    // Note: These test the unlock logic indirectly through rebalance attempts
    // since the unlock functions are internal

    function test_constants() public view {
        assertEq(treasury.PERMISSIONLESS_WETH_PER_ACTION(), 0.5 ether);
        assertEq(treasury.PERMISSIONLESS_WETH_PER_DAY(), 2 ether);
        assertEq(treasury.PERMISSIONLESS_SLIPPAGE_BPS(), 300);
        assertEq(treasury.FALLBACK_INITIAL_DELAY(), 180 days);
        assertEq(treasury.FALLBACK_RECURRING_DELAY(), 14 days);
        assertEq(treasury.FALLBACK_ACTIVITY_THRESHOLD_BPS(), 100);
        assertEq(treasury.FALLBACK_UNLOCK_INCREMENT_BPS(), 200);
        assertEq(treasury.STRATEGIC_TRANCHE_BPS(), 200);
        assertEq(treasury.STRATEGIC_TOKEN_COOLDOWN(), 4 hours);
        assertEq(treasury.ROLLING_WINDOW_DURATION(), 24 hours);
        assertEq(treasury.REBALANCE_SPLIT_TUSD_BPS(), 7500);
        assertEq(treasury.REBALANCE_SPLIT_USDC_BPS(), 2500);
        assertEq(treasury.ASSUMED_TOTAL_SUPPLY(), 100_000_000_000e18);
        assertEq(treasury.BPS_DENOMINATOR(), 10000);
        assertEq(treasury.RESCUE_DELAY(), 90 days);
    }

    // ==================== REBALANCE TESTS (access control) ====================
    function test_rebalance_revertNoDeposits() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(owner);
        vm.expectRevert(TreasuryManagerV2.NoDeposits.selector);
        treasury.rebalanceStrategicToken(bnkrAddr, 100e18);
    }

    function test_rebalance_revertNotStrategic() public {
        vm.prank(owner);
        vm.expectRevert(TreasuryManagerV2.TokenNotStrategic.selector);
        treasury.rebalanceStrategicToken(address(0x9999), 100e18);
    }

    function test_rebalance_revertZeroAmount() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(owner);
        vm.expectRevert(TreasuryManagerV2.ZeroAmount.selector);
        treasury.rebalanceStrategicToken(bnkrAddr, 0);
    }

    function test_rebalance_revertNotOperator() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(user);
        vm.expectRevert(TreasuryManagerV2.NotOwnerOrOperator.selector);
        treasury.rebalanceStrategicToken(bnkrAddr, 100e18);
    }

    // ==================== PERMISSIONLESS REBALANCE TESTS ====================
    function test_permissionless_revertNoDeposits() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(user);
        vm.expectRevert(TreasuryManagerV2.NoDeposits.selector);
        treasury.permissionlessRebalanceStrategicToken(bnkrAddr, 100e18);
    }

    function test_permissionless_revertNotStrategic() public {
        vm.prank(user);
        vm.expectRevert(TreasuryManagerV2.TokenNotStrategic.selector);
        treasury.permissionlessRebalanceStrategicToken(address(0x9999), 100e18);
    }

    function test_permissionless_revertZeroAmount() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(user);
        vm.expectRevert(TreasuryManagerV2.ZeroAmount.selector);
        treasury.permissionlessRebalanceStrategicToken(bnkrAddr, 0);
    }

    // ==================== RESCUE TESTS ====================
    function test_rescue_revertNotOwner() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(user);
        vm.expectRevert();
        treasury.rescueDeadPoolToken(bnkrAddr, "");
    }

    function test_rescue_revertNoDeposits() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        vm.prank(owner);
        vm.expectRevert(TreasuryManagerV2.NoDeposits.selector);
        treasury.rescueDeadPoolToken(bnkrAddr, "");
    }

    function test_rescue_revertTooEarly() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;

        // Deposit first
        deal(bnkrAddr, owner, 1_000_000e18);
        vm.startPrank(owner);
        IERC20(bnkrAddr).approve(address(treasury), 1_000_000e18);
        treasury.depositStrategicToken(bnkrAddr, 1_000_000e18);

        // Try to rescue immediately (before 90 days)
        vm.expectRevert(TreasuryManagerV2.RescueTooEarly.selector);
        treasury.rescueDeadPoolToken(bnkrAddr, abi.encodePacked(bnkrAddr, uint24(10000), address(0x4200000000000000000000000000000000000006)));
        vm.stopPrank();
    }

    // ==================== OWNABLE2STEP TESTS ====================
    function test_transferOwnership_twoStep() public {
        vm.prank(owner);
        treasury.transferOwnership(user);
        // Pending owner should be user
        assertEq(treasury.pendingOwner(), user);
        // Owner should still be original
        assertEq(treasury.owner(), owner);

        // Accept ownership
        vm.prank(user);
        treasury.acceptOwnership();
        assertEq(treasury.owner(), user);
    }

    // ==================== OPERATOR COOLDOWN EDGE CASES ====================
    function test_ownerBypassesCooldown() public {
        // Owner can call multiple operations without cooldown
        vm.startPrank(owner);
        treasury.burnTUSD(1_000_000e18);
        treasury.burnTUSD(1_000_000e18); // No cooldown for owner
        treasury.burnTUSD(1_000_000e18);
        vm.stopPrank();
    }

    function test_ownerBypassesPerActionCap() public {
        uint256 bigAmount = 200_000_000e18; // Above 100M default cap
        vm.prank(owner);
        treasury.burnTUSD(bigAmount);
    }

    // ==================== PERMISSIONLESS FALLBACK WINDOW TESTS ====================
    function test_permissionless_fallbackWindowInitialDelay() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;

        // Deposit
        deal(bnkrAddr, owner, 1_000_000e18);
        vm.startPrank(owner);
        IERC20(bnkrAddr).approve(address(treasury), 1_000_000e18);
        treasury.depositStrategicToken(bnkrAddr, 1_000_000e18);
        vm.stopPrank();

        // Try permissionless immediately - should fail
        vm.prank(user);
        vm.expectRevert(TreasuryManagerV2.FallbackWindowNotElapsed.selector);
        treasury.permissionlessRebalanceStrategicToken(bnkrAddr, 100e18);

        // Even after 179 days
        vm.warp(block.timestamp + 179 days);
        vm.prank(user);
        vm.expectRevert(TreasuryManagerV2.FallbackWindowNotElapsed.selector);
        treasury.permissionlessRebalanceStrategicToken(bnkrAddr, 100e18);
    }

    // ==================== ADDRESS CONSTANT TESTS ====================
    function test_addressConstants() public view {
        assertEq(treasury.TUSD(), 0x3d5e487B21E0569048c4D1A60E98C36e1B09DB07);
        assertEq(treasury.WETH(), 0x4200000000000000000000000000000000000006);
        assertEq(treasury.USDC(), 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
        assertEq(treasury.DEAD(), 0x000000000000000000000000000000000000dEaD);
        assertEq(treasury.UNIVERSAL_ROUTER(), 0x6fF5693b99212Da76ad316178A184AB56D299b43);
        assertEq(treasury.PERMIT2(), 0x000000000022D473030F116dDEE9F6B43aC78BA3);
        assertEq(treasury.STAKING(), 0x2a70a42BC0524aBCA9Bff59a51E7aAdB575DC89A);
    }

    function test_poolConstants() public view {
        assertEq(treasury.TUSD_WETH_FEE(), 10000);
        assertEq(treasury.USDC_WETH_FEE(), 500);
    }

    // ==================== DEFAULT CAP VALUES ====================
    function test_defaultCaps() public view {
        assertEq(treasury.buybackWethPerAction(), 0.5 ether);
        assertEq(treasury.buybackWethPerDay(), 2 ether);
        assertEq(treasury.buybackUsdcPerAction(), 2000e6);
        assertEq(treasury.buybackUsdcPerDay(), 5000e6);
        assertEq(treasury.burnTusdPerAction(), 100_000_000e18);
        assertEq(treasury.burnTusdPerDay(), 500_000_000e18);
        assertEq(treasury.stakeTusdPerAction(), 100_000_000e18);
        assertEq(treasury.stakeTusdPerDay(), 500_000_000e18);
        assertEq(treasury.operatorCooldown(), 60 minutes);
        assertEq(treasury.operatorSlippageBps(), 300);
        assertEq(treasury.rebalanceWethPerAction(), 0.5 ether);
        assertEq(treasury.rebalanceWethPerDay(), 2 ether);
        assertEq(treasury.rebalanceSlippageBps(), 300);
    }

    // ==================== STRATEGIC TOKEN LIST ====================
    function test_strategicTokenList() public view {
        assertEq(treasury.strategicTokenList(0), 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b); // BNKR
        assertEq(treasury.strategicTokenList(1), 0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2); // DRB
        assertEq(treasury.strategicTokenList(2), 0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb); // Clanker
        assertEq(treasury.strategicTokenList(3), 0x50D2280441372486BeecdD328c1854743EBaCb07); // KELLY
        assertEq(treasury.strategicTokenList(4), 0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07); // CLAWD
        assertEq(treasury.strategicTokenList(5), 0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07); // JUNO
        assertEq(treasury.strategicTokenList(6), 0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07); // FELIX
    }

    // ==================== MULTIPLE DEPOSIT TRACKING ====================
    function test_multipleDeposits_accumulate() public {
        address bnkrAddr = 0x22aF33FE49fD1Fa80c7149773dDe5890D3c76F3b;
        deal(bnkrAddr, owner, 3_000_000e18);

        vm.startPrank(owner);
        IERC20(bnkrAddr).approve(address(treasury), 3_000_000e18);
        treasury.depositStrategicToken(bnkrAddr, 1_000_000e18);
        treasury.depositStrategicToken(bnkrAddr, 2_000_000e18);
        vm.stopPrank();

        (,,,,,,,,,,,,, uint256 trackedDeposits,,,,,,,,) = treasury.strategicTokens(bnkrAddr);
        assertEq(trackedDeposits, 3_000_000e18);
    }

    // ==================== BURN TO DEAD ADDRESS ====================
    function test_burnTUSD_sendsToDeadAddress() public {
        address deadAddr = 0x000000000000000000000000000000000000dEaD;
        uint256 deadBefore = IERC20(treasury.TUSD()).balanceOf(deadAddr);

        vm.prank(operatorAddr);
        treasury.burnTUSD(1_000_000e18);

        uint256 deadAfter = IERC20(treasury.TUSD()).balanceOf(deadAddr);
        assertEq(deadAfter - deadBefore, 1_000_000e18);
    }

    // ==================== V4 TOKEN CONFIG TESTS ====================
    function test_v4TokenConfigs() public view {
        address kellyAddr = 0x50D2280441372486BeecdD328c1854743EBaCb07;
        (,, bool isV4,,,bytes32 v4PoolId,,, uint24 v4Fee, int24 v4TickSpacing, address v4Hooks,,,,,,,,,,,) = treasury.strategicTokens(kellyAddr);
        assertTrue(isV4);
        assertEq(v4PoolId, 0x7EAC33D5641697366EAEC3234147FD98BA25F01ACCA66A51A48BD129FC532145);
        assertEq(v4Fee, 8388608);
        assertEq(v4TickSpacing, 200);
        assertEq(v4Hooks, 0xb429d62f8f3bFFb98CdB9569533eA23bF0Ba28CC);
    }

    function test_v4AllTokensShareHooks() public view {
        address[4] memory v4Tokens = [
            address(0x50D2280441372486BeecdD328c1854743EBaCb07), // KELLY
            address(0x9f86dB9fc6f7c9408e8Fda3Ff8ce4e78ac7a6b07), // CLAWD
            address(0x4E6c9f48f73E54EE5F3AB7e2992B2d733D0d0b07), // JUNO
            address(0xf30Bf00edd0C22db54C9274B90D2A4C21FC09b07)  // FELIX
        ];

        for (uint256 i = 0; i < v4Tokens.length; i++) {
            (,, bool isV4,,,,,,,,address hooks,,,,,,,,,,,) = treasury.strategicTokens(v4Tokens[i]);
            assertTrue(isV4);
            assertEq(hooks, 0xb429d62f8f3bFFb98CdB9569533eA23bF0Ba28CC);
        }
    }

    // ==================== V3 TOKEN CONFIG TESTS ====================
    function test_v3TokenConfigs() public view {
        // DRB
        address drbAddr = 0x3ec2156D4c0A9CBdAB4a016633b7BcF6a8d68Ea2;
        (bool enabled,, bool isV4, address v3Pool, uint24 v3Fee,,,,,,, uint256 buyPrice,,,,,,,,,,) = treasury.strategicTokens(drbAddr);
        assertTrue(enabled);
        assertFalse(isV4);
        assertEq(v3Pool, 0x5116773e18A9C7bB03EBB961b38678E45E238923);
        assertEq(v3Fee, 10000);
        assertEq(buyPrice, 89090000000000);

        // Clanker
        address clankerAddr = 0x1bc0c42215582d5A085795f4baDbaC3ff36d1Bcb;
        (enabled,, isV4, v3Pool, v3Fee,,,,,,, buyPrice,,,,,,,,,,) = treasury.strategicTokens(clankerAddr);
        assertTrue(enabled);
        assertFalse(isV4);
        assertEq(v3Pool, 0xC1a6FBeDAe68E1472DbB91FE29B51F7a0Bd44F97);
        assertEq(buyPrice, 25e18);
    }

    // ==================== REBALANCE CAP SETTINGS ====================
    function test_setRebalanceCapSettings_revertNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        treasury.setRebalanceCapSettings(1, 1, 1);
    }

    // ==================== TOKEN INFO BALANCE ====================
    function test_tokenInfoShowsBalance() public view {
        TokenInfo memory info = treasury.getKnownToken(treasury.WETH());
        assertEq(info.currentBalance, 100 ether);
    }

    // ==================== EDGE CASES ====================
    function test_burnEntireBalance() public {
        uint256 balance = IERC20(treasury.TUSD()).balanceOf(address(treasury));
        vm.prank(owner);
        treasury.burnTUSD(balance);
        assertEq(IERC20(treasury.TUSD()).balanceOf(address(treasury)), 0);
    }
}
