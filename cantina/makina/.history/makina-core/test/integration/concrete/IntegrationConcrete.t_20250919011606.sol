// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IMockAcrossV3SpokePool} from "test/mocks/IMockAcrossV3SpokePool.sol";
import {MockBorrowModule} from "test/mocks/MockBorrowModule.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {MockERC4626} from "test/mocks/MockERC4626.sol";
import {MockFeeManager} from "test/mocks/MockFeeManager.sol";
import {MockPriceFeed} from "test/mocks/MockPriceFeed.sol";
import {MockFlashLoanModule} from "test/mocks/MockFlashLoanModule.sol";
import {MockSupplyModule} from "test/mocks/MockSupplyModule.sol";
import {MockPool} from "test/mocks/MockPool.sol";
import {MerkleProofs} from "test/utils/MerkleProofs.sol";
import {Machine} from "src/machine/Machine.sol";
import {Caliber} from "src/caliber/Caliber.sol";
import {CaliberMailbox} from "src/caliber/CaliberMailbox.sol";

import {Base_Test, Base_Hub_Test, Base_Spoke_Test} from "test/base/Base.t.sol";

abstract contract Integration_Concrete_Test is Base_Test {
    /// @dev A denotes the accounting token, B denotes the base token
    /// and E is the reference currency of the oracle registry.
    uint256 internal constant PRICE_A_E = 150;
    uint256 internal constant PRICE_B_E = 60000;
    uint256 internal constant PRICE_B_A = 400;

    MockERC20 public accountingToken;
    MockERC20 public baseToken;

    MockFlashLoanModule internal flashLoanModule;

    MockERC4626 internal vault;
    MockSupplyModule internal supplyModule;
    MockBorrowModule internal borrowModule;
    MockPool internal pool;

    IMockAcrossV3SpokePool internal acrossV3SpokePool;

    MockPriceFeed internal aPriceFeed1;
    MockPriceFeed internal bPriceFeed1;

    function setUp() public virtual override {
        accountingToken = new MockERC20("accountingToken", "ACT", 18);
        baseToken = new MockERC20("baseToken", "BT", 18);

        flashLoanModule = new MockFlashLoanModule();

        vault = new MockERC4626("vault", "VLT", IERC20(baseToken), 0);
        supplyModule = new MockSupplyModule(IERC20(baseToken));
        borrowModule = new MockBorrowModule(IERC20(baseToken));
        pool = new MockPool(address(accountingToken), address(baseToken), "MockPool", "MP");

        acrossV3SpokePool = IMockAcrossV3SpokePool(_deployCode(getMockAcrossV3SpokePoolCode(), 0));

        aPriceFeed1 = new MockPriceFeed(18, int256(PRICE_A_E * 1e18), block.timestamp);
        bPriceFeed1 = new MockPriceFeed(18, int256(PRICE_B_E * 1e18), block.timestamp);

        vm.startPrank(dao);
        oracleRegistry.setFeedRoute(
            address(accountingToken), address(aPriceFeed1), 2 * DEFAULT_PF_STALE_THRSHLD, address(0), 0
        );
        oracleRegistry.setFeedRoute(
            address(baseToken), address(bPriceFeed1), 2 * DEFAULT_PF_STALE_THRSHLD, address(0), 0
        );
        swapModule.setSwapperTargets(ZEROX_SWAPPER_ID, address(pool), address(pool));
        vm.stopPrank();
    }

    modifier withForeignTokenRegistered(address localToken, uint256 chainId, address foreignToken) {
        vm.prank(dao);
        tokenRegistry.setToken(localToken, chainId, foreignToken);
        _;
    }

    ///
    /// Helper functions
    ///

    function _setUpCaliberMerkleRoot(Caliber _caliber) internal {
        MerkleProofs.MerkleTreeParams memory params = MerkleProofs.MerkleTreeParams({
            caliber: address(_caliber),
            mockAccountingToken: address(accountingToken),
            mockBaseToken: address(baseToken),
            mockVault: address(vault),
            mockVaultPosId: VAULT_POS_ID,
            mockSupplyModule: address(supplyModule),
            mockSupplyModulePosId: SUPPLY_POS_ID,
            mockBorrowModule: address(borrowModule),
            mockBorrowModulePosId: BORROW_POS_ID,
            mockPool: address(pool),
            mockPoolPosId: POOL_POS_ID,
            mockFlashLoanModule: address(flashLoanModule),
            mockLoopPosId: LOOP_POS_ID,
            lendingMarketPosGroupId: LENDING_MARKET_POS_GROUP_ID
        });
        // generate merkle tree for instructions involving mock base token and vault
        MerkleProofs._generateMerkleData(params);

        vm.prank(riskManager);
        _caliber.scheduleAllowedInstrRootUpdate(MerkleProofs._getAllowedInstrMerkleRoot());
        skip(_caliber.timelockDuration());
    }

    function _addLiquidityToMockPool(uint256 _amount1, uint256 _amount2) internal {
        deal(address(accountingToken), address(this), _amount1, true);
        deal(address(baseToken), address(this), _amount2, true);
        accountingToken.approve(address(pool), _amount1);
        baseToken.approve(address(pool), _amount2);
        pool.addLiquidity(_amount1, _amount2);
    }

    function _checkEncodedCaliberPosValue(
        bytes memory encodedData,
        uint256 expectedId,
        uint256 expectedValue,
        bool expectedIsDebt
    ) internal pure {
        (uint256 id, uint256 value, bool isDebt) = abi.decode(encodedData, (uint256, uint256, bool));
        assertEq(id, expectedId);
        assertEq(value, expectedValue);
        assertEq(isDebt, expectedIsDebt);
    }

    function _checkEncodedCaliberBTValue(bytes memory encodedData, address expectedAddress, uint256 expectedValue)
        internal
        pure
    {
        (address token, uint256 value) = abi.decode(encodedData, (address, uint256));
        assertEq(token, expectedAddress);
        assertEq(value, expectedValue);
    }

    function _checkBridgeCounterValue(bytes memory encodedData, address expectedAddress, uint256 expectedValue)
        internal
        pure
    {
        (address token, uint256 value) = abi.decode(encodedData, (address, uint256));
        assertEq(token, expectedAddress);
        assertEq(value, expectedValue);
    }
}

abstract contract Integration_Concrete_Hub_Test is Integration_Concrete_Test, Base_Hub_Test {
    uint256 public constant SPOKE_CHAIN_ID = 1000;
    uint16 public constant WORMHOLE_SPOKE_CHAIN_ID = 2000;

    Machine public machine;
    Caliber public caliber;

    function setUp() public virtual override(Integration_Concrete_Test, Base_Hub_Test) {
        Base_Hub_Test.setUp();
        Integration_Concrete_Test.setUp();

        vm.prank(dao);
        hubCoreRegistry.setFlashLoanModule(address(flashLoanModule));

        feeManager = new MockFeeManager(dao, DEFAULT_FEE_MANAGER_FIXED_FEE_RATE, DEFAULT_FEE_MANAGER_PERF_FEE_RATE);

        (machine, caliber) = _deployMachine(address(accountingToken), bytes32(0), TEST_DEPLOYMENT_SALT);
    }

    modifier whileInRecoveryMode() {
        vm.startPrank(securityCouncil);
        machine.setRecoveryMode(true);
        vm.stopPrank();
        _;
    }

    modifier withTokenAsBT(address _token) {
        vm.prank(riskManagerTimelock);
        caliber.addBaseToken(_token);
        _;
    }

    modifier withSpokeCaliber(uint256 chainId, address mailbox) {
        vm.prank(dao);
        machine.setSpokeCaliber(chainId, mailbox, new uint16[](0), new address[](0));
        _;
    }

    modifier withBridgeAdapter(uint16 bridgeId) {
        vm.prank(dao);
        machine.createBridgeAdapter(bridgeId, DEFAULT_MAX_BRIDGE_LOSS_BPS, "");
        _;
    }

    modifier withSpokeBridgeAdapter(uint256 chainId, uint16 bridgeId, address adapter) {
        vm.prank(dao);
        machine.setSpokeBridgeAdapter(chainId, bridgeId, adapter);
        _;
    }
}

abstract contract Integration_Concrete_Spoke_Test is Integration_Concrete_Test, Base_Spoke_Test {
    address public hubMachineAddr;

    Caliber public caliber;
    CaliberMailbox public caliberMailbox;

    function setUp() public virtual override(Integration_Concrete_Test, Base_Spoke_Test) {
        Base_Spoke_Test.setUp();
        Integration_Concrete_Test.setUp();

        vm.prank(dao);
        spokeCoreRegistry.setFlashLoanModule(address(flashLoanModule));

        hubMachineAddr = makeAddr("hubMachine");

        (caliber, caliberMailbox) =
            _deployCaliber(hubMachineAddr, address(accountingToken), bytes32(0), TEST_DEPLOYMENT_SALT);
    }

    modifier whileInRecoveryMode() {
        vm.prank(securityCouncil);
        caliberMailbox.setRecoveryMode(true);
        _;
    }

    modifier withTokenAsBT(address _token) {
        vm.prank(riskManagerTimelock);
        caliber.addBaseToken(_token);
        _;
    }

    modifier withBridgeAdapter(uint16 bridgeId) {
        vm.prank(dao);
        caliberMailbox.createBridgeAdapter(bridgeId, DEFAULT_MAX_BRIDGE_LOSS_BPS, "");
        _;
    }

    modifier withHubBridgeAdapter(uint16 bridgeId, address foreignAdapter) {
        vm.prank(dao);
        caliberMailbox.setHubBridgeAdapter(bridgeId, foreignAdapter);
        _;
    }
}
