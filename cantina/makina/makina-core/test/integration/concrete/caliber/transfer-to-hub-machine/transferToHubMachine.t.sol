// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {ICaliber} from "src/interfaces/ICaliber.sol";
import {Errors} from "src/libraries/Errors.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

import {Caliber_Integration_Concrete_Test} from "../Caliber.t.sol";

contract TransferToHubMachine_Integration_Concrete_Test is Caliber_Integration_Concrete_Test {
    function test_RevertWhen_CallerNotMechanic_WhileNotInRecoveryMode() public {
        vm.expectRevert(Errors.UnauthorizedCaller.selector);
        caliber.transferToHubMachine(address(accountingToken), 1e18, "");

        vm.prank(securityCouncil);
        vm.expectRevert(Errors.UnauthorizedCaller.selector);
        caliber.transferToHubMachine(address(accountingToken), 1e18, "");
    }

    function test_RevertWhen_TokenNonPriceable() public {
        MockERC20 baseToken2 = new MockERC20("baseToken2", "BT2", 18);
        uint256 inputAmount = 1e18;
        deal(address(baseToken2), address(caliber), inputAmount, true);

        vm.prank(mechanic);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceFeedRouteNotRegistered.selector, address(baseToken2)));
        caliber.transferToHubMachine(address(baseToken2), inputAmount, "");
    }

    function test_RevertGiven_InsufficientBalance() public {
        uint256 inputAmount = 1e18;

        vm.prank(address(mechanic));
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, address(caliber), 0, inputAmount)
        );
        caliber.transferToHubMachine(address(accountingToken), inputAmount, "");
    }

    function test_TransferToHubMachine() public {
        uint256 inputAmount = 1e18;
        deal(address(accountingToken), address(caliber), inputAmount, true);

        vm.expectEmit(true, false, false, true, address(caliber));
        emit ICaliber.TransferToHubMachine(address(accountingToken), inputAmount);
        vm.prank(mechanic);
        caliber.transferToHubMachine(address(accountingToken), inputAmount, "");

        assertEq(accountingToken.balanceOf(address(caliber)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
    }

    function test_RevertWhen_CallerNotSC_WhileInRecoveryMode() public whileInRecoveryMode {
        vm.expectRevert(Errors.UnauthorizedCaller.selector);
        caliber.transferToHubMachine(address(accountingToken), 1e18, "");

        vm.prank(mechanic);
        vm.expectRevert(Errors.UnauthorizedCaller.selector);
        caliber.transferToHubMachine(address(accountingToken), 1e18, "");
    }

    function test_RevertWhen_TokenNonPriceable_WhileInRecoveryMode() public whileInRecoveryMode {
        MockERC20 baseToken2 = new MockERC20("baseToken2", "BT2", 18);
        uint256 inputAmount = 1e18;
        deal(address(baseToken2), address(caliber), inputAmount, true);

        vm.prank(securityCouncil);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceFeedRouteNotRegistered.selector, address(baseToken2)));
        caliber.transferToHubMachine(address(baseToken2), inputAmount, "");
    }

    function test_RevertGiven_InsufficientBalance_WhileInRecoveryMode() public whileInRecoveryMode {
        uint256 inputAmount = 1e18;

        vm.prank(address(securityCouncil));
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, address(caliber), 0, inputAmount)
        );
        caliber.transferToHubMachine(address(accountingToken), inputAmount, "");
    }

    function test_TransferToHubMachine_WhileInRecoveryMode() public whileInRecoveryMode {
        uint256 inputAmount = 1e18;
        deal(address(accountingToken), address(caliber), inputAmount, true);

        vm.expectEmit(true, false, false, true, address(caliber));
        emit ICaliber.TransferToHubMachine(address(accountingToken), inputAmount);
        vm.prank(securityCouncil);
        caliber.transferToHubMachine(address(accountingToken), inputAmount, "");

        assertEq(accountingToken.balanceOf(address(caliber)), 0);
        assertEq(accountingToken.balanceOf(address(machine)), inputAmount);
    }
}
