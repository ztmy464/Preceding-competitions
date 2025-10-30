// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Errors} from "src/libraries/Errors.sol";
// forge test --match-test test_PreviewDeposit --match-path test/integration/concrete/pre-deposit-vault/preview-deposit/previewDeposit.t.sol -vvvv
import {PreDepositVault_Integration_Concrete_Test} from "../PreDepositVault.t.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IOracleRegistry} from "src/interfaces/IOracleRegistry.sol";
import {IHubCoreRegistry} from "src/interfaces/IHubCoreRegistry.sol";
import {DecimalsUtils} from "src/libraries/DecimalsUtils.sol";
import {console} from "forge-std/console.sol";

contract PreviewDeposit_Integration_Concrete_Test is PreDepositVault_Integration_Concrete_Test {
    function test_RevertGiven_VaultMigrated() public migrated {
        vm.expectRevert(Errors.Migrated.selector);
        preDepositVault.previewDeposit(1e18);
    }

    function test_PreviewDeposit() public view {
        // 添加查看shareToken总供应量的代码
        address shareTokenAddress = preDepositVault.shareToken();
        uint256 shareTokenTotalSupply = IERC20(shareTokenAddress).totalSupply();
        console.log("Share Token Total Supply before previewDeposit:", shareTokenTotalSupply);
        
        // 查看所需变量的值
        address _depositToken = preDepositVault.depositToken();
        console.log("_depositToken:", _depositToken);
        
        // 获取价格
        IOracleRegistry oracleRegistry = IOracleRegistry(IHubCoreRegistry(registry).oracleRegistry());
        uint256 price_d_a = oracleRegistry.getPrice(_depositToken, preDepositVault.accountingToken());
        console.log("price_d_a:", price_d_a);
        
        // 获取dtUnit
        uint256 dtUnit = 10 ** DecimalsUtils._getDecimals(_depositToken);
        console.log("dtUnit:", dtUnit);
        
        // 获取dtBal
        uint256 dtBal = IERC20(_depositToken).balanceOf(address(this));
        console.log("dtBal:", dtBal);
        
        uint256 inputAmount = 3e18;
        uint256 expectedShares = preDepositVault.previewDeposit(inputAmount);
        assertEq(expectedShares, inputAmount * PRICE_B_A);
    }
}
