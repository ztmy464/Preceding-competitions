// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMachine} from "@makina-core/interfaces/IMachine.sol";

import {IDirectDepositor} from "../interfaces/IDirectDepositor.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";
import {MachinePeriphery} from "../utils/MachinePeriphery.sol";
import {Whitelist} from "../utils/Whitelist.sol";

//~ 为什么 abstract模块 的状态变量 都有自己 指定固定的存储槽位置？ 
/* 
看起来确实像普通继承，但 Makina 的架构不是传统继承——而是「虚拟机式模块组合」
🔹 每个模块（Whitelist / Positions / Swaps）：

是一个「逻辑片段」，不一定被 Caliber 编译期合并；
在运行时由 VM 进行调度执行（dispatch）；
VM 在执行模块逻辑时，会 delegatecall 到该模块逻辑；
所以多个模块共享同一个存储上下文。

换句话说：
Makina 的“组合”是运行时的，不是编译期的继承。
 */
contract DirectDepositor is MachinePeriphery, Whitelist, IDirectDepositor {
    using SafeERC20 for IERC20;

    constructor(address _registry) MachinePeriphery(_registry) {}

    function initialize(bytes calldata data) external virtual override initializer {
        (bool _whitelistStatus) = abi.decode(data, (bool));
        __Whitelist_init(_whitelistStatus);
    }

    /// @inheritdoc IDirectDepositor
    function deposit(uint256 assets, address receiver, uint256 minShares)
        public
        virtual
        override
        whitelistCheck
        returns (uint256)
    {
        address _machine = machine();
        address asset = IMachine(_machine).accountingToken();

        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        IERC20(asset).forceApprove(_machine, assets);

        return IMachine(_machine).deposit(assets, receiver, minShares);
    }

    /// @inheritdoc IWhitelist
    function setWhitelistStatus(bool enabled) external override onlyRiskManager {
        _setWhitelistStatus(enabled);
    }

    /// @inheritdoc IWhitelist
    function setWhitelistedUsers(address[] calldata users, bool whitelisted) external override onlyRiskManager {
        _setWhitelistedUsers(users, whitelisted);
    }
}
