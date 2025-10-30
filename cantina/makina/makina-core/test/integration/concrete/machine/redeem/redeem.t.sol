// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IMachine} from "src/interfaces/IMachine.sol";
import {Errors} from "src/libraries/Errors.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

import {Machine_Integration_Concrete_Test} from "../Machine.t.sol";

contract Redeem_Integration_Concrete_Test is Machine_Integration_Concrete_Test {
    function test_RevertWhen_ReentrantCall() public {
        accountingToken.scheduleReenter(
            MockERC20.Type.Before, address(machine), abi.encodeCall(IMachine.redeem, (0, address(0), 0))
        );

        vm.expectRevert(ReentrancyGuardUpgradeable.ReentrancyGuardReentrantCall.selector);
        vm.prank(machineRedeemer);
        machine.redeem(0, address(1), 0);
    }

    function test_RevertGiven_WhileInRecoveryMode() public whileInRecoveryMode {
        vm.expectRevert(Errors.RecoveryMode.selector);
        machine.redeem(1e18, address(this), 0);
    }

    function test_RevertWhen_CallerNotRedeemer() public {
        vm.expectRevert(Errors.UnauthorizedCaller.selector);
        machine.redeem(1e18, address(this), 0);
    }

    function test_RevertGiven_MaxWithdrawExceeded() public {
        uint256 inputAmount = 1e18;

        deal(address(accountingToken), machineDepositor, inputAmount, true);

        // deposit assets
        vm.startPrank(machineDepositor);
        accountingToken.approve(address(machine), inputAmount);
        uint256 shares = machine.deposit(inputAmount, machineRedeemer, 0);
        vm.stopPrank();

        // move assets to caliber
        vm.prank(mechanic);
        machine.transferToHubCaliber(address(accountingToken), 1);

        // redeem shares
        uint256 expectedAssets = machine.convertToAssets(shares);
        vm.expectRevert(abi.encodeWithSelector(Errors.ExceededMaxWithdraw.selector, expectedAssets, inputAmount - 1));
        vm.prank(machineRedeemer);
        machine.redeem(shares, address(this), expectedAssets);
    }

    function test_RevertWhen_SlippageProtectionTriggered() public {
        uint256 inputAmount = 1e18;

        deal(address(accountingToken), machineDepositor, inputAmount, true);

        // deposit assets
        vm.startPrank(machineDepositor);
        accountingToken.approve(address(machine), inputAmount);
        uint256 shares = machine.deposit(inputAmount, machineRedeemer, 0);
        vm.stopPrank();

        // try redeeming shares
        uint256 expectedAssets = machine.convertToAssets(shares);
        vm.expectRevert(Errors.SlippageProtection.selector);
        vm.prank(machineRedeemer);
        machine.redeem(shares, address(this), expectedAssets + 1);
    }

    function test_Redeem() public {
        uint256 inputAmount = 3e18;

        deal(address(accountingToken), machineDepositor, inputAmount, true);

        // deposit assets
        vm.startPrank(machineDepositor);
        accountingToken.approve(address(machine), inputAmount);
        uint256 shares = machine.deposit(inputAmount, machineRedeemer, 0);
        vm.stopPrank();

        uint256 balAssetsReceiverBefore = accountingToken.balanceOf(address(this));
        uint256 balAssetsMachineBefore = accountingToken.balanceOf(address(machine));
        uint256 balSharesRedeemerBefore = IERC20(machine.shareToken()).balanceOf(machineRedeemer);

        // redeem partial shares
        uint256 sharesToRedeem = shares / 3;
        uint256 expectedAssets = machine.convertToAssets(sharesToRedeem);
        vm.expectEmit(true, true, true, true, address(machine));
        emit IMachine.Redeem(machineRedeemer, address(this), expectedAssets, sharesToRedeem);
        vm.prank(machineRedeemer);
        machine.redeem(sharesToRedeem, address(this), expectedAssets);

        uint256 balAssetsReceiverAfter = accountingToken.balanceOf(address(this));
        uint256 balAssetsMachineAfter = accountingToken.balanceOf(address(machine));
        uint256 balSharesRedeemerAfter = IERC20(machine.shareToken()).balanceOf(machineRedeemer);

        assertEq(balAssetsReceiverAfter - balAssetsReceiverBefore, expectedAssets);
        assertEq(balAssetsMachineBefore - balAssetsMachineAfter, expectedAssets);
        assertEq(balSharesRedeemerBefore - balSharesRedeemerAfter, sharesToRedeem);
        assertEq(machine.lastTotalAum(), balAssetsMachineAfter);

        balAssetsReceiverBefore = balAssetsReceiverAfter;
        balAssetsMachineBefore = balAssetsMachineAfter;
        balSharesRedeemerBefore = balSharesRedeemerAfter;

        // redeem remaining shares
        sharesToRedeem = balSharesRedeemerAfter;
        expectedAssets = machine.convertToAssets(sharesToRedeem);
        vm.expectEmit(true, true, true, true, address(machine));
        emit IMachine.Redeem(machineRedeemer, address(this), expectedAssets, sharesToRedeem);
        vm.prank(machineRedeemer);
        machine.redeem(sharesToRedeem, address(this), expectedAssets);

        balAssetsReceiverAfter = accountingToken.balanceOf(address(this));
        balAssetsMachineAfter = accountingToken.balanceOf(address(machine));
        balSharesRedeemerAfter = IERC20(machine.shareToken()).balanceOf(machineRedeemer);

        assertEq(balAssetsReceiverAfter - balAssetsReceiverBefore, expectedAssets);
        assertEq(balAssetsMachineBefore - balAssetsMachineAfter, expectedAssets);
        assertEq(balSharesRedeemerBefore - balSharesRedeemerAfter, sharesToRedeem);
        assertEq(machine.lastTotalAum(), balAssetsMachineAfter);
        assertEq(balAssetsMachineAfter, 0);
        assertEq(balSharesRedeemerAfter, 0);
    }
}
