// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

library Roles {
    uint64 public constant INFRA_SETUP_ROLE = 1;          // 基础设施设置角色
    uint64 public constant STRATEGY_DEPLOYMENT_ROLE = 2;  // 策略部署角色
    uint64 public constant STRATEGY_COMPONENTS_SETUP_ROLE = 3;  // 策略组件设置角色
    uint64 public constant STRATEGY_MANAGEMENT_SETUP_ROLE = 4;  // 策略管理设置角色
}
