// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { SymbioticNetworkMiddleware } from
    "../../contracts/delegation/providers/symbiotic/SymbioticNetworkMiddleware.sol";
import { SymbioticVaultConfig } from "../../contracts/deploy/interfaces/SymbioticsDeployConfigs.sol";
import { TestDeployer } from "../../test/deploy/TestDeployer.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBaseDelegator } from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import { INetworkRestakeDelegator } from "@symbioticfi/core/src/interfaces/delegator/INetworkRestakeDelegator.sol";

import { ISlasher } from "@symbioticfi/core/src/interfaces/slasher/ISlasher.sol";
import { console } from "forge-std/console.sol";

contract SymbioticSlashAssumptionsTest is TestDeployer {
    function setUp() public {
        _deployCapTestEnvironment();
        _initSymbioticVaultsLiquidity(env);

        // reset the initial stakes for this test
        {
            vm.startPrank(env.symbiotic.users.vault_admin);

            for (uint256 i = 0; i < env.testUsers.agents.length; i++) {
                address agent = env.testUsers.agents[i];
                _symbioticVaultDelegateToAgent(symbioticWethVault, env.symbiotic.networkAdapter, agent, 2e18);
            }

            _timeTravel(symbioticWethVault.vaultEpochDuration + 1 days);

            vm.stopPrank();
        }

        vm.startPrank(env.users.middleware_admin);

        SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware).setFeeAllowed(0.09e18);
        vm.stopPrank();
    }

    function _get_stake_at(SymbioticVaultConfig memory _vault, address _agent, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        IBaseDelegator delegator = IBaseDelegator(_vault.delegator);
        SymbioticNetworkMiddleware networkMiddleware =
            SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware);
        return delegator.stakeAt(networkMiddleware.subnetwork(_agent), _agent, uint48(_timestamp), "");
    }

    function test_add_agent() public {
        vm.startPrank(env.users.middleware_admin);
        address agent = makeAddr("agent");

        vm.expectRevert();
        SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware).registerAgent(address(0), agent);

        vm.expectRevert();
        SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware).registerAgent(
            symbioticWethVault.vault, address(0)
        );

        SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware).registerAgent(
            symbioticWethVault.vault, agent
        );
        address vault = SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware).vaults(agent);
        assertEq(vault, symbioticWethVault.vault);
        vm.stopPrank();
    }

    function _set_delegation_amount(SymbioticVaultConfig memory _vault, address _agent, uint256 _amount) internal {
        vm.startPrank(env.symbiotic.users.vault_admin);
        _symbioticVaultDelegateToAgent(_vault, env.symbiotic.networkAdapter, _agent, _amount);
        vm.stopPrank();
    }

    function test_can_slash_after_restaker_undelegation() public {
        SymbioticVaultConfig memory _vault = symbioticWethVault;
        SymbioticNetworkMiddleware _middleware =
            SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware);

        // we work from the perspective of the network
        address agent1 = env.testUsers.agents[0];
        address agent2 = env.testUsers.agents[1];
        address agent3 = env.testUsers.agents[2];

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 2e18); // this is what the TestDeployer sets
        assertEq(_get_stake_at(_vault, agent2, block.timestamp), 2e18); // this is what the TestDeployer sets
        assertEq(_get_stake_at(_vault, agent3, block.timestamp), 2e18); // this is what the TestDeployer sets

        // now, the restaker completely undelegates from the usdt vault
        _timeTravel(1 days);

        // the stake should immediately drop to 0
        _set_delegation_amount(_vault, agent1, 0);
        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 0);

        _timeTravel(3);

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 0);
        assertEq(_get_stake_at(_vault, agent1, block.timestamp - 1), 0);
        assertEq(_get_stake_at(_vault, agent1, block.timestamp - 2), 0);
        assertEq(_get_stake_at(_vault, agent1, block.timestamp - 3), 0);
        assertEq(_get_stake_at(_vault, agent1, block.timestamp - 4), 2e18);
        assertEq(_get_stake_at(_vault, agent1, block.timestamp - 5), 2e18);

        /// ==== try slashing
        bytes32 agent1_subnetwork = _middleware.subnetwork(agent1);
        vm.startPrank(address(_middleware));

        // we cannot request a slash for "right now", even though there is a stake to slash
        vm.expectRevert(ISlasher.InvalidCaptureTimestamp.selector);
        ISlasher(_vault.slasher).slash(agent1_subnetwork, agent1, 10, uint48(block.timestamp), "");

        // we cannot request a slash for a timestamp where there is no stake
        vm.expectRevert(ISlasher.InsufficientSlash.selector);
        ISlasher(_vault.slasher).slash(agent1_subnetwork, agent1, 10, uint48(block.timestamp - 1), "");

        // we can slash for a timestamp where there is a stake
        ISlasher(_vault.slasher).slash(agent1_subnetwork, agent1, 10, uint48(block.timestamp - 4), "");
    }

    function test_setting_shares_but_reading_stake() public {
        SymbioticVaultConfig memory _vault = symbioticWethVault;

        // we work from the perspective of the network
        address agent1 = env.testUsers.agents[0];
        address agent2 = env.testUsers.agents[1];
        address agent3 = env.testUsers.agents[2];

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 2e18); // this is what the TestDeployer sets
        assertEq(_get_stake_at(_vault, agent2, block.timestamp), 2e18); // this is what the TestDeployer sets
        assertEq(_get_stake_at(_vault, agent3, block.timestamp), 2e18); // this is what the TestDeployer sets

        _timeTravel(1);

        _set_delegation_amount(_vault, agent1, 0);

        _timeTravel(1);

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 0);
        assertEq(_get_stake_at(_vault, agent2, block.timestamp), 2e18);
        assertEq(_get_stake_at(_vault, agent3, block.timestamp), 2e18);

        _timeTravel(1);

        _set_delegation_amount(_vault, agent2, 0);

        _timeTravel(1);

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 0);
        assertEq(_get_stake_at(_vault, agent2, block.timestamp), 0);
        assertEq(_get_stake_at(_vault, agent3, block.timestamp), 2e18);

        _timeTravel(1);

        _set_delegation_amount(_vault, agent3, 0);

        _timeTravel(1);

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 0);
        assertEq(_get_stake_at(_vault, agent2, block.timestamp), 0);
        assertEq(_get_stake_at(_vault, agent3, block.timestamp), 0);

        _timeTravel(1);

        _set_delegation_amount(_vault, agent1, 10);

        _timeTravel(1);

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 10);
        assertEq(_get_stake_at(_vault, agent2, block.timestamp), 0);
        assertEq(_get_stake_at(_vault, agent3, block.timestamp), 0);

        _set_delegation_amount(_vault, agent2, 20);

        _timeTravel(1);

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 10);
        assertEq(_get_stake_at(_vault, agent2, block.timestamp), 20);
        assertEq(_get_stake_at(_vault, agent3, block.timestamp), 0);
    }

    function test_slashing_decreases_the_operator_total_stake() public {
        SymbioticVaultConfig memory _vault = symbioticWethVault;
        SymbioticNetworkMiddleware _middleware =
            SymbioticNetworkMiddleware(env.symbiotic.networkAdapter.networkMiddleware);

        address agent1 = _getRandomAgent();
        bytes32 agent1_subnetwork = _middleware.subnetwork(agent1);

        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 2e18);

        // slash 10% of the stake
        vm.startPrank(address(_middleware));
        ISlasher(_vault.slasher).slash(agent1_subnetwork, agent1, 0.2e18, uint48(block.timestamp - 1), "");
        vm.stopPrank();

        _timeTravel(1);

        // the total stake should decrease by 10%
        assertEq(_get_stake_at(_vault, agent1, block.timestamp), 1.8e18);
    }
}
