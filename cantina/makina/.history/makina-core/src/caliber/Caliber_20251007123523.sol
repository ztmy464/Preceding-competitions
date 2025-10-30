// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ERC721HolderUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {ERC1155HolderUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {DecimalsUtils} from "../libraries/DecimalsUtils.sol";
import {Errors} from "../libraries/Errors.sol";
import {IWeirollVM} from "../interfaces/IWeirollVM.sol";
import {ICoreRegistry} from "../interfaces/ICoreRegistry.sol";
import {ICaliber} from "../interfaces/ICaliber.sol";
import {IMachineEndpoint} from "../interfaces/IMachineEndpoint.sol";
import {IMakinaGovernable} from "../interfaces/IMakinaGovernable.sol";
import {IOracleRegistry} from "../interfaces/IOracleRegistry.sol";
import {ISwapModule} from "../interfaces/ISwapModule.sol";
import {MakinaContext} from "../utils/MakinaContext.sol";

contract Caliber is
    MakinaContext,
    AccessManagedUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    ICaliber
{
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    /// @dev Full scale value in basis points.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev Flag to indicate end of values in the accounting output state.
    bytes32 private constant ACCOUNTING_OUTPUT_STATE_END = bytes32(type(uint256).max);

    /// @inheritdoc ICaliber
    address public immutable weirollVm;

    /// @custom:storage-location erc7201:makina.storage.Caliber
    struct CaliberStorage {
        address _hubMachineEndpoint;                              // Hub机器端点地址
        address _accountingToken;                                 // 会计代币地址
        uint256 _positionStaleThreshold;                          // 头寸会计数据过期阈值（秒）isAccountingFresh()
        bytes32 _allowedInstrRoot;                                // 允许执行的指令Merkle树根
        uint256 _timelockDuration;                                // 指令根更新的时间锁持续时间
        bytes32 _pendingAllowedInstrRoot;                         // 待更新的指令Merkle树根
        uint256 _pendingTimelockExpiry;                           // 待更新指令根的时间锁过期时间
        uint256 _maxPositionIncreaseLossBps;                      // 头寸增加时允许的最大价值损失（基点）✅
        uint256 _maxPositionDecreaseLossBps;                      // 头寸减少时允许的最大价值损失（基点）
        uint256 _maxSwapLossBps;                                  // 基础代币交换时允许的最大价值损失（基点）
        uint256 _managedPositionId;                               // 当前正在管理的头寸ID
        bool _isManagedPositionDebt;                              // 当前管理的头寸是否为债务
        bool _isManagingFlashloan;                                // 是否正在管理闪电贷
        uint256 _cooldownDuration;                                // 操作冷却期持续时间
        uint256 _lastBTSwapTimestamp;                             // 上次基础代币交换的时间戳
        mapping(bytes32 executionHash => uint256 timestamp) _lastExecutionTimestamp; // 记录每个执行哈希的最后执行时间戳
        mapping(uint256 posId => Position pos) _positionById;     // 通过ID映射头寸数据
        mapping(uint256 groupId => EnumerableSet.UintSet positionIds) _positionIdGroups; // 按组ID映射头寸ID集合
        EnumerableSet.UintSet _positionIds;                       // 所有头寸ID的集合
        EnumerableSet.AddressSet _baseTokens;                     // 所有基础代币的地址集合
        EnumerableSet.AddressSet _instrRootGuardians;             // 指令根监护人地址集合
    }

    // keccak256(abi.encode(uint256(keccak256("makina.storage.Caliber")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CaliberStorageLocation = 0x32461bf02c7aa4aa351cd04411b6c7b9348073fbccf471c7b347bdaada044b00;

    function _getCaliberStorage() private pure returns (CaliberStorage storage $) {
        assembly {
            $.slot := CaliberStorageLocation
        }
    }

    constructor(address _registry, address _weirollVm) MakinaContext(_registry) {
        weirollVm = _weirollVm;
        _disableInitializers();
    }
    
    /// @inheritdoc ICaliber
    function initialize(CaliberInitParams calldata cParams, address _accountingToken, address _hubMachineEndpoint)
        external
        override
        initializer
    {
        CaliberStorage storage $ = _getCaliberStorage();
        //~ _createCaliber(cParams, accountingToken, mailbox, salt);
        $._accountingToken = _accountingToken;
        $._hubMachineEndpoint = _hubMachineEndpoint;  //~ mailbox（spoke Caliber）  Machine（hub Caliber）
        $._positionStaleThreshold = cParams.initialPositionStaleThreshold;
        $._allowedInstrRoot = cParams.initialAllowedInstrRoot;
        $._timelockDuration = cParams.initialTimelockDuration;
        $._maxPositionIncreaseLossBps = cParams.initialMaxPositionIncreaseLossBps;
        $._maxPositionDecreaseLossBps = cParams.initialMaxPositionDecreaseLossBps;
        $._maxSwapLossBps = cParams.initialMaxSwapLossBps;
        $._cooldownDuration = cParams.initialCooldownDuration;
        _addBaseToken(_accountingToken);

        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __ERC1155Holder_init();
    }

    modifier onlyOperator() {
        IMakinaGovernable _hubMachineEndpoint = IMakinaGovernable(_getCaliberStorage()._hubMachineEndpoint);
        if (
            msg.sender
                != (
                    _hubMachineEndpoint.recoveryMode()
                        ? _hubMachineEndpoint.securityCouncil()
                        : _hubMachineEndpoint.mechanic()
                )
        ) {
            revert Errors.UnauthorizedCaller();
        }
        _;
    }

    modifier onlyRiskManager() {
        if (msg.sender != IMakinaGovernable(_getCaliberStorage()._hubMachineEndpoint).riskManager()) {
            revert Errors.UnauthorizedCaller();
        }
        _;
    }

    modifier onlyRiskManagerTimelock() {
        if (msg.sender != IMakinaGovernable(_getCaliberStorage()._hubMachineEndpoint).riskManagerTimelock()) {
            revert Errors.UnauthorizedCaller();
        }
        _;
    }

    /// @inheritdoc IAccessManaged
    function authority() public view override returns (address) {
        return IAccessManaged(_getCaliberStorage()._hubMachineEndpoint).authority();
    }

    /// @inheritdoc ICaliber
    function hubMachineEndpoint() external view override returns (address) {
        return _getCaliberStorage()._hubMachineEndpoint;
    }

    /// @inheritdoc ICaliber
    function accountingToken() external view override returns (address) {
        return _getCaliberStorage()._accountingToken;
    }

    /// @inheritdoc ICaliber
    function positionStaleThreshold() external view override returns (uint256) {
        return _getCaliberStorage()._positionStaleThreshold;
    }

    /// @inheritdoc ICaliber
    function allowedInstrRoot() public view override returns (bytes32) {
        CaliberStorage storage $ = _getCaliberStorage();
        return ($._pendingTimelockExpiry == 0 || block.timestamp < $._pendingTimelockExpiry)
            ? $._allowedInstrRoot
            : $._pendingAllowedInstrRoot;
    }

    /// @inheritdoc ICaliber
    function timelockDuration() external view override returns (uint256) {
        return _getCaliberStorage()._timelockDuration;
    }

    /// @inheritdoc ICaliber
    function pendingAllowedInstrRoot() public view override returns (bytes32) {
        CaliberStorage storage $ = _getCaliberStorage();
        return ($._pendingTimelockExpiry == 0 || block.timestamp >= $._pendingTimelockExpiry)
            ? bytes32(0)
            : $._pendingAllowedInstrRoot;
    }

    /// @inheritdoc ICaliber
    function pendingTimelockExpiry() public view override returns (uint256) {
        CaliberStorage storage $ = _getCaliberStorage();
        return ($._pendingTimelockExpiry == 0 || block.timestamp >= $._pendingTimelockExpiry)
            ? 0
            : $._pendingTimelockExpiry;
    }

    /// @inheritdoc ICaliber
    function maxPositionIncreaseLossBps() external view override returns (uint256) {
        return _getCaliberStorage()._maxPositionIncreaseLossBps;
    }

    /// @inheritdoc ICaliber
    function maxPositionDecreaseLossBps() external view override returns (uint256) {
        return _getCaliberStorage()._maxPositionDecreaseLossBps;
    }

    /// @inheritdoc ICaliber
    function maxSwapLossBps() external view override returns (uint256) {
        return _getCaliberStorage()._maxSwapLossBps;
    }

    /// @inheritdoc ICaliber
    function cooldownDuration() external view returns (uint256) {
        return _getCaliberStorage()._cooldownDuration;
    }

    /// @inheritdoc ICaliber
    function getPositionsLength() external view override returns (uint256) {
        return _getCaliberStorage()._positionIds.length();
    }

    /// @inheritdoc ICaliber
    function getPositionId(uint256 idx) external view override returns (uint256) {
        return _getCaliberStorage()._positionIds.at(idx);
    }

    /// @inheritdoc ICaliber
    function getPosition(uint256 posId) external view override returns (Position memory) {
        return _getCaliberStorage()._positionById[posId];
    }

    /// @inheritdoc ICaliber
    function isBaseToken(address token) external view override returns (bool) {
        return _getCaliberStorage()._baseTokens.contains(token);
    }

    /// @inheritdoc ICaliber
    function getBaseTokensLength() external view override returns (uint256) {
        return _getCaliberStorage()._baseTokens.length();
    }

    /// @inheritdoc ICaliber
    function getBaseToken(uint256 idx) external view override returns (address) {
        return _getCaliberStorage()._baseTokens.at(idx);
    }

    /// @inheritdoc ICaliber
    function isInstrRootGuardian(address user) external view override returns (bool) {
        CaliberStorage storage $ = _getCaliberStorage();
        return user == IMakinaGovernable($._hubMachineEndpoint).riskManager()
            || user == IMakinaGovernable($._hubMachineEndpoint).securityCouncil() || $._instrRootGuardians.contains(user);
    }

    //~ ✅ 
    /// @inheritdoc ICaliber
    function isAccountingFresh() external view returns (bool) {
        CaliberStorage storage $ = _getCaliberStorage();

        uint256 len = $._positionIds.length();
        uint256 currentTimestamp = block.timestamp;
        for (uint256 i; i < len; ++i) {
            if (
                currentTimestamp - $._positionById[$._positionIds.at(i)].lastAccountingTime >= $._positionStaleThreshold
            ) {
                return false;
            }
        }

        return true;
    }

    //~ ✅ 
     /// @inheritdoc ICaliber
    function getDetailedAum() external view override returns (uint256, bytes[] memory, bytes[] memory) {
        //~ q: 这里怎么这样检查重入？而且是 view？ 
        if (_reentrancyGuardEntered()) {
            revert ReentrancyGuardReentrantCall();
        }

        CaliberStorage storage $ = _getCaliberStorage();

        uint256 currentTimestamp = block.timestamp;
        uint256 aum;
        uint256 debt;

        //~ Count the positions Values
        uint256 len = $._positionIds.length();
        bytes[] memory positionsValues = new bytes[](len);
        for (uint256 i; i < len; ++i) {
            uint256 posId = $._positionIds.at(i);
            Position memory pos = $._positionById[posId];
            if (currentTimestamp - $._positionById[posId].lastAccountingTime >= $._positionStaleThreshold) {
                revert Errors.PositionAccountingStale(posId);
            } else if (pos.isDebt) {
                debt += pos.value;
            } else {
                aum += pos.value;
            }
            positionsValues[i] = abi.encode(posId, pos.value, pos.isDebt);
        }

        //~ Count the baseTokens Values
        len = $._baseTokens.length();
        bytes[] memory baseTokensValues = new bytes[](len);
        for (uint256 i; i < len; ++i) {
            address bt = $._baseTokens.at(i);
            uint256 btBal = IERC20(bt).balanceOf(address(this));
            uint256 value = btBal == 0 ? 0 : _accountingValueOf(bt, btBal);
            aum += value;
            baseTokensValues[i] = abi.encode(bt, value);
        }

        uint256 netAum = aum > debt ? aum - debt : 0;

        return (netAum, positionsValues, baseTokensValues);
    }

    /// @inheritdoc ICaliber
    function addBaseToken(address token) external override onlyRiskManagerTimelock {
        _addBaseToken(token);
    }

    /// @inheritdoc ICaliber
    function removeBaseToken(address token) external override onlyRiskManagerTimelock {
        CaliberStorage storage $ = _getCaliberStorage();

        if (token == $._accountingToken) {
            revert Errors.AccountingToken();
        }
        if (!$._baseTokens.remove(token)) {
            revert Errors.NotBaseToken();
        }
        if (IERC20(token).balanceOf(address(this)) > 0) {
            revert Errors.NonZeroBalance();
        }

        emit BaseTokenRemoved(token);
    }

    //~ ✅ 
    /// @inheritdoc ICaliber
    function accountForPosition(Instruction calldata instruction)
        external
        override
        nonReentrant
        returns (uint256, int256)
    {
        CaliberStorage storage $ = _getCaliberStorage();
        if (!$._positionIds.contains(instruction.positionId)) {
            revert Errors.PositionDoesNotExist();
        }
        if (instruction.groupId != 0 && $._positionIdGroups[instruction.groupId].length() > 1) {
            revert Errors.PositionIsGrouped();
        }
        return _accountForPosition(instruction, true);
    }

    /// @inheritdoc ICaliber
    function accountForPositionBatch(Instruction[] calldata instructions, uint256[] calldata groupIds)
        external
        override
        nonReentrant
        returns (uint256[] memory, int256[] memory)
    {
        CaliberStorage storage $ = _getCaliberStorage();
        //~ q: 这俩长度不用相等吗？
        uint256 groupsLen = groupIds.length;
        uint256 instructionsLen = instructions.length;

        // mark all positions in the provided groups as stale
        for (uint256 i; i < groupsLen; ++i) {
            uint256 groupId = groupIds[i];
            if (groupId == 0) {
                revert Errors.ZeroGroupId();
            }
            uint256 groupLen = $._positionIdGroups[groupId].length();
            for (uint256 j; j < groupLen; ++j) {
                delete $._positionById[$._positionIdGroups[groupId].at(j)].lastAccountingTime;
            }
        }

        uint256[] memory values = new uint256[](instructionsLen);
        int256[] memory changes = new int256[](instructionsLen);

        // run accounting instructions
        for (uint256 i; i < instructionsLen; ++i) {
            uint256 positionId = instructions[i].positionId;
            if (!$._positionIds.contains(positionId)) {
                revert Errors.PositionDoesNotExist();
            }
            uint256 groupId = instructions[i].groupId;
            if (groupId != 0 && $._positionIdGroups[groupId].length() > 1) {
                if (!_includesGroupId(groupIds, groupId)) {
                    revert Errors.GroupIdNotProvided();
                }
            }
            (values[i], changes[i]) = _accountForPosition(instructions[i], true);
        }

        // check that all positions in provided groups were accounted for
        for (uint256 i; i < groupsLen; ++i) {
            uint256 groupId = groupIds[i];
            uint256 groupLen = $._positionIdGroups[groupId].length();
            for (uint256 j; j < groupLen; ++j) {
                uint256 positionId = $._positionIdGroups[groupId].at(j);
                if ($._positionById[positionId].lastAccountingTime == 0) {
                    revert Errors.MissingInstructionForGroup(groupId);
                }
            }
        }

        return (values, changes);
    }

    /// @inheritdoc ICaliber
    function managePosition(Instruction calldata mgmtInstruction, Instruction calldata acctInstruction)
        external
        override
        nonReentrant
        onlyOperator
        returns (uint256, int256)
    {
        return _managePosition(mgmtInstruction, acctInstruction);
    }

    /// @inheritdoc ICaliber
    function managePositionBatch(Instruction[] calldata mgmtInstructions, Instruction[] calldata acctInstructions)
        external
        override
        nonReentrant
        onlyOperator
        returns (uint256[] memory, int256[] memory)
    {
        uint256 len = mgmtInstructions.length;
        if (len != acctInstructions.length) {
            revert Errors.MismatchedLengths();
        }

        uint256[] memory values = new uint256[](len);
        int256[] memory changes = new int256[](len);

        for (uint256 i; i < len; ++i) {
            (values[i], changes[i]) = _managePosition(mgmtInstructions[i], acctInstructions[i]);
        }

        return (values, changes);
    }

    /// @inheritdoc ICaliber
    function manageFlashLoan(Instruction calldata instruction, address token, uint256 amount) external override {
        CaliberStorage storage $ = _getCaliberStorage();

        if ($._isManagingFlashloan) {
            revert Errors.ManageFlashLoanReentrantCall();
        }

        address _flashLoanModule = ICoreRegistry(registry).flashLoanModule();
        if (msg.sender != _flashLoanModule) {
            revert Errors.NotFlashLoanModule();
        }
        if ($._managedPositionId == 0) {
            revert Errors.DirectManageFlashLoanCall();
        }
        if (instruction.instructionType != InstructionType.FLASHLOAN_MANAGEMENT) {
            revert Errors.InvalidInstructionType();
        }
        if ($._managedPositionId != instruction.positionId || $._isManagedPositionDebt != instruction.isDebt) {
            revert Errors.InstructionsMismatch();
        }
        if (instruction.isDebt) {
            revert Errors.InvalidDebtFlag();
        }
        $._isManagingFlashloan = true;
        IERC20(token).safeTransferFrom(_flashLoanModule, address(this), amount);
        _checkInstructionIsAllowed(instruction);
        _execute(instruction.commands, instruction.state);
        IERC20(token).safeTransfer(_flashLoanModule, amount);
        $._isManagingFlashloan = false;
    }

    //~ ✅ 
    /// @inheritdoc ICaliber
    function harvest(Instruction calldata instruction, ISwapModule.SwapOrder[] calldata swapOrders)
        external
        override
        nonReentrant
        onlyOperator
    {
        if (instruction.instructionType != InstructionType.HARVEST) {
            revert Errors.InvalidInstructionType();
        }
        _checkInstructionIsAllowed(instruction);
        _execute(instruction.commands, instruction.state);
        uint256 len = swapOrders.length;
        for (uint256 i; i < len; ++i) {
            _swap(swapOrders[i]);
        }
    }

    //~ ✅ 
    /// @inheritdoc ICaliber
    function swap(ISwapModule.SwapOrder calldata order) external override nonReentrant onlyOperator {
        _swap(order);
    }

    /// @inheritdoc ICaliber
    function transferToHubMachine(address token, uint256 amount, bytes calldata data) external override onlyOperator {
        CaliberStorage storage $ = _getCaliberStorage();
        IERC20(token).forceApprove($._hubMachineEndpoint, amount);

        //~ CaliberMailbox和Machine都实现了相同的IMachineEndpoint接口
        IMachineEndpoint($._hubMachineEndpoint).manageTransfer(token, amount, data);
        emit TransferToHubMachine(token, amount);
    }

    //~ ✅ 
    /// @inheritdoc ICaliber
    function notifyIncomingTransfer(address token, uint256 amount) external override nonReentrant {
        CaliberStorage storage $ = _getCaliberStorage();
        address _hubMachineEndpoint = $._hubMachineEndpoint;
        if (msg.sender != _hubMachineEndpoint) {
            revert Errors.NotMachineEndpoint();
        }
        if (!$._baseTokens.contains(token)) {
            revert Errors.NotBaseToken();
        }
        IERC20(token).safeTransferFrom(_hubMachineEndpoint, address(this), amount);
        emit IncomingTransfer(token, amount);
    }

    /// @inheritdoc ICaliber
    function setPositionStaleThreshold(uint256 newPositionStaleThreshold) external override onlyRiskManagerTimelock {
        CaliberStorage storage $ = _getCaliberStorage();
        emit PositionStaleThresholdChanged($._positionStaleThreshold, newPositionStaleThreshold);
        $._positionStaleThreshold = newPositionStaleThreshold;
    }

    /// @inheritdoc ICaliber
    function setTimelockDuration(uint256 newTimelockDuration) external override onlyRiskManagerTimelock {
        CaliberStorage storage $ = _getCaliberStorage();
        emit TimelockDurationChanged($._timelockDuration, newTimelockDuration);
        $._timelockDuration = newTimelockDuration;
    }

    /// @inheritdoc ICaliber
    function scheduleAllowedInstrRootUpdate(bytes32 newAllowedInstrRoot) external override onlyRiskManager {
        CaliberStorage storage $ = _getCaliberStorage();
        _updateAllowedInstrRoot();
        if ($._pendingTimelockExpiry != 0) {
            revert Errors.ActiveUpdatePending();
        }
        if (newAllowedInstrRoot == $._allowedInstrRoot) {
            revert Errors.SameRoot();
        }
        $._pendingAllowedInstrRoot = newAllowedInstrRoot;
        $._pendingTimelockExpiry = block.timestamp + $._timelockDuration;
        emit NewAllowedInstrRootScheduled(newAllowedInstrRoot, $._pendingTimelockExpiry);
    }

    /// @inheritdoc ICaliber
    function cancelAllowedInstrRootUpdate() external override {
        CaliberStorage storage $ = _getCaliberStorage();
        IMachineEndpoint _hubMachineEndpoint = IMachineEndpoint($._hubMachineEndpoint);
        if (
            msg.sender != _hubMachineEndpoint.riskManager() && msg.sender != _hubMachineEndpoint.securityCouncil()
                && !_getCaliberStorage()._instrRootGuardians.contains(msg.sender)
        ) {
            revert Errors.UnauthorizedCaller();
        }
        if ($._pendingTimelockExpiry == 0 || block.timestamp >= $._pendingTimelockExpiry) {
            revert Errors.NoPendingUpdate();
        }
        emit NewAllowedInstrRootCancelled($._pendingAllowedInstrRoot);
        delete $._pendingAllowedInstrRoot;
        delete $._pendingTimelockExpiry;
    }

    /// @inheritdoc ICaliber
    function setMaxPositionIncreaseLossBps(uint256 newMaxPositionIncreaseLossBps)
        external
        override
        onlyRiskManagerTimelock
    {
        CaliberStorage storage $ = _getCaliberStorage();
        emit MaxPositionIncreaseLossBpsChanged($._maxPositionIncreaseLossBps, newMaxPositionIncreaseLossBps);
        $._maxPositionIncreaseLossBps = newMaxPositionIncreaseLossBps;
    }

    /// @inheritdoc ICaliber
    function setMaxPositionDecreaseLossBps(uint256 newMaxPositionDecreaseLossBps)
        external
        override
        onlyRiskManagerTimelock
    {
        CaliberStorage storage $ = _getCaliberStorage();
        emit MaxPositionDecreaseLossBpsChanged($._maxPositionDecreaseLossBps, newMaxPositionDecreaseLossBps);
        $._maxPositionDecreaseLossBps = newMaxPositionDecreaseLossBps;
    }

    /// @inheritdoc ICaliber
    function setMaxSwapLossBps(uint256 newMaxSwapLossBps) external override onlyRiskManagerTimelock {
        CaliberStorage storage $ = _getCaliberStorage();
        emit MaxSwapLossBpsChanged($._maxSwapLossBps, newMaxSwapLossBps);
        $._maxSwapLossBps = newMaxSwapLossBps;
    }

    /// @inheritdoc ICaliber
    function setCooldownDuration(uint256 newCooldownDuration) external override onlyRiskManagerTimelock {
        CaliberStorage storage $ = _getCaliberStorage();
        emit CooldownDurationChanged($._cooldownDuration, newCooldownDuration);
        $._cooldownDuration = newCooldownDuration;
    }

    /// @inheritdoc ICaliber
    function addInstrRootGuardian(address newGuardian) external override restricted {
        CaliberStorage storage $ = _getCaliberStorage();
        IMachineEndpoint _hubMachineEndpoint = IMachineEndpoint($._hubMachineEndpoint);
        if (
            newGuardian == _hubMachineEndpoint.riskManager() || newGuardian == _hubMachineEndpoint.securityCouncil()
                || !$._instrRootGuardians.add(newGuardian)
        ) {
            revert Errors.AlreadyRootGuardian();
        }
        emit InstrRootGuardianAdded(newGuardian);
    }

    /// @inheritdoc ICaliber
    function removeInstrRootGuardian(address guardian) external override restricted {
        CaliberStorage storage $ = _getCaliberStorage();
        IMachineEndpoint _hubMachineEndpoint = IMachineEndpoint($._hubMachineEndpoint);
        if (guardian == _hubMachineEndpoint.riskManager() || guardian == _hubMachineEndpoint.securityCouncil()) {
            revert Errors.ProtectedRootGuardian();
        }
        if (!$._instrRootGuardians.remove(guardian)) {
            revert Errors.NotRootGuardian();
        }
        emit InstrRootGuardianRemoved(guardian);
    }

    /// @dev Adds a new base token to storage.
    function _addBaseToken(address token) internal {
        CaliberStorage storage $ = _getCaliberStorage();

        if (token == address(0)) {
            revert Errors.ZeroTokenAddress();
        }
        if (!$._baseTokens.add(token)) {
            revert Errors.AlreadyBaseToken();
        }

        emit BaseTokenAdded(token);

        if (!IOracleRegistry(ICoreRegistry(registry).oracleRegistry()).isFeedRouteRegistered(token)) {
            revert Errors.PriceFeedRouteNotRegistered(token);
        }
    }

    //~ ✅
    /// @dev Manages and accounts for a position by executing the provided instructions.
    function _managePosition(Instruction calldata mgmtInstruction, Instruction calldata acctInstruction)
        internal
        returns (uint256, int256)
    {
        CaliberStorage storage $ = _getCaliberStorage();

        uint256 posId = mgmtInstruction.positionId;
        if (posId == 0) {
            revert Errors.ZeroPositionId();
        }
        if (posId != acctInstruction.positionId || mgmtInstruction.isDebt != acctInstruction.isDebt) {
            revert Errors.InstructionsMismatch();
        }
        if (mgmtInstruction.instructionType != InstructionType.MANAGEMENT) {
            revert Errors.InvalidInstructionType();
        }

        $._managedPositionId = posId;
        $._isManagedPositionDebt = mgmtInstruction.isDebt;

        // -------- 1. account to update position value
        _accountForPosition(acctInstruction, true);

        _checkInstructionIsAllowed(mgmtInstruction);

        // -------- 计算操作前合约持有的所有受影响代币的总价值
        uint256 affectedTokensValueBefore;
        //~ @audit
        /* 
        处理的代币范围可能不同 会影响吗：
        - affectedTokensValue 基于 mgmtInstruction.affectedTokens （管理指令中定义的受影响代币）
        - 头寸价值计算基于 acctInstruction.affectedTokens （会计指令中定义的代币）
        */
        uint256 atLen = mgmtInstruction.affectedTokens.length;
        for (uint256 i; i < atLen; ++i) {
            address _affectedToken = mgmtInstruction.affectedTokens[i];
            if (!$._baseTokens.contains(_affectedToken)) {
                revert Errors.InvalidAffectedToken();
            }
            //~ q: affectedTokensValue change 和 position change 为什么可以不一致？
            // _accountForPosition:
            // currentValue += _accountingValueOf(token, amounts[i]);
            affectedTokensValueBefore +=
                _accountingValueOf(_affectedToken, IERC20(_affectedToken).balanceOf(address(this)));
        }

        // -------- execute management instruction
        _execute(mgmtInstruction.commands, mgmtInstruction.state);

        // -------- 2. account again 获取操作后的头寸价值和变化量
        (uint256 value, int256 change) = _accountForPosition(acctInstruction, false);

        //----- 标记同组其他头寸为过期 
        if (acctInstruction.groupId != 0) {
            _invalidateGroupedPositions(acctInstruction.groupId);
        }

        uint256 affectedTokensValueAfter;
        for (uint256 i; i < atLen; ++i) {
            address _affectedToken = mgmtInstruction.affectedTokens[i];
            affectedTokensValueAfter +=
                _accountingValueOf(_affectedToken, IERC20(_affectedToken).balanceOf(address(this)));
        }

        //~ q: affectedTokensValue change 和 position change 为什么可以不一致？
        bool isPositionIncrease = change >= 0;
        uint256 absChange = isPositionIncrease ? uint256(change) : uint256(-change);
        uint256 maxLossBps = isPositionIncrease ? $._maxPositionIncreaseLossBps : $._maxPositionDecreaseLossBps;

        // -------- check
        //~ MakinaGovernable.sol 
        if (isPositionIncrease && IMachineEndpoint($._hubMachineEndpoint).recoveryMode()) {
            revert Errors.RecoveryMode();
        }

        bytes32 executionHash = keccak256(abi.encodePacked(posId, mgmtInstruction.commands, isPositionIncrease));
        if (block.timestamp - $._lastExecutionTimestamp[executionHash] < $._cooldownDuration) {
            revert Errors.OngoingCooldown();
        }

        if (affectedTokensValueAfter < affectedTokensValueBefore) {
            //~ affectedTokensValue 减少 且 （是债务 position 增加）（不是债务 position 减少）
            if (mgmtInstruction.isDebt == isPositionIncrease) {
                revert Errors.InvalidPositionChangeDirection();
            }
            _checkPositionMinDelta(absChange, affectedTokensValueBefore - affectedTokensValueAfter, maxLossBps);
        } else {
            //~ affectedTokensValue 增加 且 （不是债务 position 增加）（是债务 position 减少）
            if (mgmtInstruction.isDebt == isPositionIncrease) {
                _checkPositionMaxDelta(absChange, affectedTokensValueAfter - affectedTokensValueBefore, maxLossBps);
            }
        }

        $._lastExecutionTimestamp[executionHash] = block.timestamp;
        $._managedPositionId = 0;
        $._isManagedPositionDebt = false;

        return (value, change);
    }

    //~ ✅
    /// @dev Computes the accounting value of a position. Depending on last and current value, the
    ///      position is then either created, closed or simply updated in storage.
    function _accountForPosition(Instruction calldata instruction, bool checks) internal returns (uint256, int256) {
        if (checks) {
            if (instruction.instructionType != InstructionType.ACCOUNTING) {
                revert Errors.InvalidInstructionType();
            }
            _checkInstructionIsAllowed(instruction);
        }
        // -------- execute and get amounts
        uint256[] memory amounts;
        {
            bytes[] memory returnedState = _execute(instruction.commands, instruction.state);
            amounts = _decodeAccountingOutputState(returnedState);
        }

        CaliberStorage storage $ = _getCaliberStorage();

        uint256 posId = instruction.positionId;
        //~ q: 如果 posId 不存在，还可以 $._positionById[posId] 吗？
        Position storage pos = $._positionById[posId];
        uint256 lastValue = pos.value;
        uint256 currentValue;

        // -------- calc the token amount --> _accountingToken amount
        uint256 len = instruction.affectedTokens.length;
        if (amounts.length != len) {
            revert Errors.InvalidAccounting();
        }
        for (uint256 i; i < len; ++i) {
            address token = instruction.affectedTokens[i];
            if (!$._baseTokens.contains(token)) {
                revert Errors.InvalidAffectedToken();
            }
            currentValue += _accountingValueOf(token, amounts[i]);
        }

        // -------- close update or create position for posId
        uint256 groupId = instruction.groupId;
        if (lastValue > 0 && currentValue == 0) {
            // ----- close position
            $._positionIds.remove(posId);
            if (groupId != 0) {
                $._positionIdGroups[groupId].remove(posId);
            }
            delete $._positionById[posId];
            emit PositionClosed(posId);
        } else if (currentValue > 0) {
            // ----- update position
            pos.value = currentValue;
            pos.lastAccountingTime = block.timestamp;
            if (lastValue == 0) {
                // ----- create position
                pos.isDebt = instruction.isDebt;
                $._positionIds.add(posId);
                if (groupId != 0) {
                    $._positionIdGroups[groupId].add(posId);
                }
                emit PositionCreated(posId, currentValue);
            } else {
                emit PositionUpdated(posId, currentValue);
            }
        }

        return (currentValue, int256(currentValue) - int256(lastValue));
    }

    //~ ✅
    /// @dev Decodes the output state of an accounting instruction into an array of amounts.
    function _decodeAccountingOutputState(bytes[] memory state) internal pure returns (uint256[] memory) {
        uint256 len = state.length;
        uint256[] memory amounts = new uint256[](len);

        uint256 i;
        for (; i < len; ++i) {
            //~ state 可能有意添加 type(uint256).max 作为结束标记
            if (bytes32(state[i]) == ACCOUNTING_OUTPUT_STATE_END) {
                break;
            }
            amounts[i] = uint256(bytes32(state[i]));
        }

        // Resize the array to the actual number of values.
        assembly {
            mstore(amounts, i)
        }

        return amounts;
    }

    //~ ✅
    /// @dev Marks all positions in a given group as stale, except for the position currently being managed.
    function _invalidateGroupedPositions(uint256 groupId) internal {
        CaliberStorage storage $ = _getCaliberStorage();
        uint256 groupLen = $._positionIdGroups[groupId].length();
        for (uint256 i; i < groupLen; ++i) {
            uint256 posId = $._positionIdGroups[groupId].at(i);
            if (posId != $._managedPositionId) {
                delete $._positionById[posId].lastAccountingTime;
            }
        }
    }

    /// @dev Checks if a given group ID is included in the provided array of group IDs.
    function _includesGroupId(uint256[] calldata groupIds, uint256 groupId) internal pure returns (bool) {
        uint256 len = groupIds.length;
        for (uint256 i = 0; i < len; ++i) {
            if (groupIds[i] == groupId) {
                return true;
            }
        }
        return false;
    }

    /// @dev Computes the accounting value of a given token amount.
    function _accountingValueOf(address token, uint256 amount) internal view returns (uint256) {
        CaliberStorage storage $ = _getCaliberStorage();
        if (token == $._accountingToken) {
            return amount;
        }
        uint256 price = IOracleRegistry(ICoreRegistry(registry).oracleRegistry()).getPrice(token, $._accountingToken);
        return amount.mulDiv(price, 10 ** DecimalsUtils._getDecimals(token));
    }

    /// @dev Checks that absolute position value change is greater than minimum value relative to affected token balance changes and loss tolerance.
    function _checkPositionMinDelta(uint256 positionValChange, uint256 affectedTokensValChange, uint256 maxLossBps)
        internal
        pure
    {
        uint256 minChange = affectedTokensValChange.mulDiv(MAX_BPS - maxLossBps, MAX_BPS, Math.Rounding.Ceil);
        if (positionValChange < minChange) {
            revert Errors.MaxValueLossExceeded();
        }
    }

    /// @dev Checks that absolute position value change is less than maximum value relative to affected token balance changes and loss tolerance.
    function _checkPositionMaxDelta(uint256 positionValChange, uint256 affectedTokensValChange, uint256 maxLossBps)
        internal
        pure
    {
        uint256 maxChange = affectedTokensValChange.mulDiv(MAX_BPS + maxLossBps, MAX_BPS);
        if (positionValChange > maxChange) {
            revert Errors.MaxValueLossExceeded();
        }
    }

    //~ 所有指令必须通过Merkle证明验证，确保指令已获授权 
    /// @dev Checks if the given instruction is allowed by verifying its Merkle proof against the allowed instructions root.
    /// @param instruction The instruction to check.
    function _checkInstructionIsAllowed(Instruction calldata instruction) internal {
        bytes32 commandsHash = keccak256(abi.encodePacked(instruction.commands));
        bytes32 stateHash = _getStateHash(instruction.state, instruction.stateBitmap);
        bytes32 affectedTokensHash = keccak256(abi.encodePacked(instruction.affectedTokens));
        bytes32 instructionLeaf = keccak256(
            abi.encode(
                keccak256(
                    abi.encode(
                        commandsHash,
                        stateHash,
                        instruction.stateBitmap,
                        instruction.positionId,
                        instruction.isDebt,
                        instruction.groupId,
                        affectedTokensHash,
                        instruction.instructionType
                    )
                )
            )
        );
        if (!MerkleProof.verify(instruction.merkleProof, _updateAllowedInstrRoot(), instructionLeaf)) {
            revert Errors.InvalidInstructionProof();
        }
    }

    /// @dev Computes a hash of the state array, selectively including elements as specified by a bitmap.
    ///      This enables a weiroll script to have both fixed and variable parameters.
    /// @param state The state array to hash.
    /// @param bitmap The bitmap where each bit determines whether the corresponding element in state is included or ignored in the hash computation.
    /// @return hash The hash of the state array.
    function _getStateHash(bytes[] calldata state, uint128 bitmap) internal pure returns (bytes32) {
        if (bitmap == uint128(0)) {
            return bytes32(0);
        }

        uint8 i;
        bytes memory hashInput;

        // Iterate through the state and hash values corresponding to indices marked in the bitmap.
        for (i; i < state.length; ++i) {
            // If the bit is set as 1, hash the state value.
            if (bitmap & (0x80000000000000000000000000000000 >> i) != 0) {
                hashInput = bytes.concat(hashInput, keccak256(state[i]));
            }
        }
        return keccak256(hashInput);
    }

    /// @dev Updates the allowed instructions root if a pending update is scheduled and the timelock has expired.
    /// @return currentRoot The current allowed instructions root.
    function _updateAllowedInstrRoot() internal returns (bytes32) {
        CaliberStorage storage $ = _getCaliberStorage();
        if ($._pendingTimelockExpiry != 0 && block.timestamp >= $._pendingTimelockExpiry) {
            $._allowedInstrRoot = $._pendingAllowedInstrRoot;
            delete $._pendingAllowedInstrRoot;
            delete $._pendingTimelockExpiry;
        }
        return $._allowedInstrRoot;
    }

    //~ ✅ swap to accountingToken
    function _swap(ISwapModule.SwapOrder calldata order) internal {
        CaliberStorage storage $ = _getCaliberStorage();
        if (IMachineEndpoint($._hubMachineEndpoint).recoveryMode() && order.outputToken != $._accountingToken) {
            revert Errors.RecoveryMode();
        } else if (!$._baseTokens.contains(order.outputToken)) {
            revert Errors.InvalidOutputToken();
        }

        // ~ q: 为什么  inputToken 是 baseToken 时，需要检查 ValueLoss？
        uint256 valBefore;
        bool isInputBaseToken = $._baseTokens.contains(order.inputToken);
        if (isInputBaseToken) {
            if (block.timestamp - $._lastBTSwapTimestamp < $._cooldownDuration) {
                revert Errors.OngoingCooldown();
            }
            valBefore = _accountingValueOf(order.inputToken, order.inputAmount);
        }

        address _swapModule = ICoreRegistry(registry).swapModule();
        IERC20(order.inputToken).forceApprove(_swapModule, order.inputAmount);
        uint256 amountOut = ISwapModule(_swapModule).swap(order);
        IERC20(order.inputToken).forceApprove(_swapModule, 0);

        if (isInputBaseToken) {
            uint256 valAfter = _accountingValueOf(order.outputToken, amountOut);
            if (valAfter < valBefore.mulDiv(MAX_BPS - $._maxSwapLossBps, MAX_BPS, Math.Rounding.Ceil)) {
                revert Errors.MaxValueLossExceeded();
            }
            $._lastBTSwapTimestamp = block.timestamp;
        }
    }

    /// @dev Executes a set of commands on the Weiroll VM, via a delegatecall.
    /// @param commands The commands to execute.
    /// @param state The state to pass to the VM.
    /// @return outState The new state after executing the commands.
    function _execute(bytes32[] calldata commands, bytes[] memory state) internal returns (bytes[] memory) {
        bytes memory returndata =
            Address.functionDelegateCall(weirollVm, abi.encodeCall(IWeirollVM.execute, (commands, state)));
        return abi.decode(returndata, (bytes[]));
    }
}
