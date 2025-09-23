// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SymbioticNetworkAdapterParams } from "../contracts/deploy/interfaces/SymbioticsDeployConfigs.sol";
import { DeployCapNetworkAdapter } from "../contracts/deploy/service/providers/symbiotic/DeployCapNetworkAdapter.sol";

import { SymbioticAddressbook, SymbioticUtils } from "../contracts/deploy/utils/SymbioticUtils.sol";
import { WalletUtils } from "../contracts/deploy/utils/WalletUtils.sol";

import {
    ImplementationsConfig,
    InfraConfig,
    LibsConfig,
    UsersConfig,
    VaultConfig
} from "../contracts/deploy/interfaces/DeployConfigs.sol";
import {
    SymbioticNetworkAdapterConfig,
    SymbioticNetworkAdapterImplementationsConfig
} from "../contracts/deploy/interfaces/SymbioticsDeployConfigs.sol";

import { ConfigureDelegation } from "../contracts/deploy/service/ConfigureDelegation.sol";
import { DeploySymbioticVault } from "../contracts/deploy/service/providers/symbiotic/DeploySymbioticVault.sol";
import { InfraConfigSerializer } from "./config/InfraConfigSerializer.sol";
import { SymbioticAdapterConfigSerializer } from "./config/SymbioticAdapterConfigSerializer.sol";
import { WalletUsersConfig } from "./config/WalletUsersConfig.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

contract DeployTestnetSymbioticAdapter is
    Script,
    SymbioticUtils,
    WalletUtils,
    DeploySymbioticVault,
    DeployCapNetworkAdapter,
    ConfigureDelegation,
    SymbioticAdapterConfigSerializer,
    WalletUsersConfig,
    InfraConfigSerializer
{
    SymbioticAddressbook symbioticAb;

    UsersConfig users;
    InfraConfig infra;
    ImplementationsConfig implems;
    LibsConfig libs;

    SymbioticNetworkAdapterImplementationsConfig networkAdapterImplems;
    SymbioticNetworkAdapterConfig networkAdapter;

    function run() external {
        uint48 vaultEpochDuration = 7 days; // mainnet & unit tests
        //uint48 vaultEpochDuration = 5 minutes; // testnet

        vm.startBroadcast();

        // Get the broadcast address (deployer's address)
        users = _getUsersConfig();
        (implems, libs, infra) = _readInfraConfig();

        symbioticAb = _getSymbioticAddressbook();

        networkAdapterImplems = _deploySymbioticNetworkAdapterImplems();
        networkAdapter = _deploySymbioticNetworkAdapterInfra(
            infra,
            symbioticAb,
            networkAdapterImplems,
            SymbioticNetworkAdapterParams({ vaultEpochDuration: vaultEpochDuration, feeAllowed: 1000 })
        );

        _registerNetworkForCapDelegation(infra, networkAdapter.networkMiddleware);
        _initSymbioticNetworkAdapterAccessControl(infra, networkAdapter, users);
        _registerCapNetwork(symbioticAb, networkAdapter);

        // Save the symbiotic adapter config
        _saveSymbioticConfig(networkAdapterImplems, networkAdapter);

        vm.stopBroadcast();
    }
}
