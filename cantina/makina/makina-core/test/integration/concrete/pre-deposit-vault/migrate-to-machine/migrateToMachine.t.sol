// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IOwnable2Step} from "src/interfaces/IOwnable2Step.sol";
import {IPreDepositVault} from "src/interfaces/IPreDepositVault.sol";
import {Errors} from "src/libraries/Errors.sol";

import {PreDepositVault_Integration_Concrete_Test} from "../PreDepositVault.t.sol";

contract MigrateToMachine_Integration_Concrete_Test is PreDepositVault_Integration_Concrete_Test {
    function test_RevertWhen_CallerNotPendingMachine() public {
        vm.expectRevert(Errors.NotPendingMachine.selector);
        preDepositVault.migrateToMachine();
    }

    function test_RevertGiven_VaultMigrated() public migrated {
        vm.expectRevert(Errors.Migrated.selector);
        vm.prank(newMachineAddr);
        preDepositVault.migrateToMachine();
    }

    function test_MigrateToMachine() public {
        uint256 preDepositAmount = 1e18;
        deal(address(baseToken), address(preDepositVault), preDepositAmount);

        newMachineAddr = makeAddr("newMachine");
        vm.prank(address(hubCoreFactory));
        preDepositVault.setPendingMachine(newMachineAddr);

        vm.expectEmit(true, false, false, false);
        emit IPreDepositVault.MigrateToMachine(newMachineAddr);
        vm.prank(newMachineAddr);
        preDepositVault.migrateToMachine();

        assertTrue(preDepositVault.migrated());
        assertEq(IOwnable2Step(preDepositVault.shareToken()).pendingOwner(), newMachineAddr);
        assertEq(baseToken.balanceOf(newMachineAddr), preDepositAmount);
    }
}
