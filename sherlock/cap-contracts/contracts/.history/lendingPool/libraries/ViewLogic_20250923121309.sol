// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { IDelegation } from "../../interfaces/IDelegation.sol";

import { ILender } from "../../interfaces/ILender.sol";
import { IOracle } from "../../interfaces/IOracle.sol";
import { IVault } from "../../interfaces/IVault.sol";

import { AgentConfiguration } from "./configuration/AgentConfiguration.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title View Logic
/// @author kexley, Cap Labs
/// @notice View functions to see the state of an agent's health
library ViewLogic {
    using AgentConfiguration for ILender.AgentConfigurationMap;
    using Math for uint256;

    uint256 constant SECONDS_IN_YEAR = 31536000;

    /// @notice Calculate the maximum amount that can be borrowed for a given asset
    /// @param $ Lender storage
    /// @param _agent Agent address
    /// @param _asset Asset to borrow
    /// @return maxBorrowableAmount Maximum amount that can be borrowed in asset decimals
    function maxBorrowable(ILender.LenderStorage storage $, address _agent, address _asset)
        external
        view
        returns (uint256 maxBorrowableAmount)
    {
        (uint256 totalDelegation,, uint256 totalDebt,,, uint256 health) = agent($, _agent);
        uint256 unrealizedInterest = accruedRestakerInterest($, _agent, _asset);

        // health is below liquidation threshold, no borrowing allowed
        if (health < 1e27) return 0;

        uint256 ltv = IDelegation($.delegation).ltv(_agent);
        uint256 borrowCapacity = totalDelegation * ltv / 1e27;

        //  already at or above borrow capacity
        if (totalDebt >= borrowCapacity) return 0;

        // Calculate remaining borrow capacity in USD (8 decimals)
        uint256 remainingCapacity = borrowCapacity - totalDebt;

        // Convert to asset amount using price and decimals
        (uint256 assetPrice,) = IOracle($.oracle).getPrice(_asset);
        if (assetPrice == 0) return 0;

        uint256 assetDecimals = $.reservesData[_asset].decimals;
        maxBorrowableAmount = remainingCapacity * (10 ** assetDecimals) / assetPrice;

        // Get total available assets using the vault's availableBalance function
        uint256 totalAvailable = IVault($.reservesData[_asset].vault).availableBalance(_asset);
        if (totalAvailable < unrealizedInterest) return 0;
        totalAvailable -= unrealizedInterest;

        // Limit maxBorrowableAmount by total available assets
        if (totalAvailable < maxBorrowableAmount) {
            maxBorrowableAmount = totalAvailable;
        }
    }

    /// @notice Calculate the maximum amount that can be liquidated for a given asset
    /// @param $ Lender storage
    /// @param _agent Agent address
    /// @param _asset Asset to liquidate
    /// @return maxLiquidatableAmount Maximum amount that can be liquidated in asset decimals
    function maxLiquidatable(ILender.LenderStorage storage $, address _agent, address _asset)
        external
        view
        returns (uint256 maxLiquidatableAmount)
    {
        (uint256 totalDelegation,, uint256 totalDebt,, uint256 liquidationThreshold, uint256 health) = agent($, _agent);
        if (health >= 1e27) return 0;

        (uint256 assetPrice,) = IOracle($.oracle).getPrice(_asset);
        if (assetPrice == 0) return 0;

        ILender.ReserveData storage reserve = $.reservesData[_asset];
        uint256 decPow = 10 ** reserve.decimals;

        // Calculate maximum liquidatable amount
        if (totalDelegation * liquidationThreshold > $.targetHealth * totalDebt) {
            return 0;
        }

        maxLiquidatableAmount = (($.targetHealth * totalDebt) - (totalDelegation * liquidationThreshold)) * decPow
            / (($.targetHealth - liquidationThreshold) * assetPrice);

        // Cap at the agent's debt for this asset
        uint256 agentDebt = debt($, _agent, _asset);
        if (agentDebt < maxLiquidatableAmount + reserve.minBorrow) maxLiquidatableAmount = agentDebt;
    }

    /// @notice Calculate the agent data
    /// @param $ Lender storage
    /// @param _agent Agent address
    /// @return totalDelegation Total delegation of an agent in USD, encoded with 8 decimals
    /// @return totalSlashableCollateral Total slashable collateral of an agent in USD, encoded with 8 decimals
    /// @return totalDebt Total debt of an agent in USD, encoded with 8 decimals
    /// @return ltv Loan to value ratio, encoded in ray (1e27)
    /// @return liquidationThreshold Liquidation ratio of an agent, encoded in ray (1e27)
    /// @return health Health status of an agent, encoded in ray (1e27)
    function agent(ILender.LenderStorage storage $, address _agent)
        public
        view
        returns (
            uint256 totalDelegation,
            uint256 totalSlashableCollateral,
            uint256 totalDebt,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 health
        )
    {
        totalDelegation = IDelegation($.delegation).coverage(_agent);
        totalSlashableCollateral = IDelegation($.delegation).slashableCollateral(_agent);
        liquidationThreshold = IDelegation($.delegation).liquidationThreshold(_agent);

        // Extract debt calculation to a separate function to reduce local variables
        totalDebt = calculateTotalDebt($, _agent);

        ltv = totalDelegation == 0 ? 0 : (totalDebt * 1e27) / totalDelegation;
        health = totalDebt == 0 ? type(uint256).max : (totalDelegation * liquidationThreshold) / totalDebt;
    }

    /// @notice Get the current debt balances for an agent for a specific asset
    /// @param $ Lender storage
    /// @param _agent Agent address to check debt for
    /// @param _asset Asset to check debt for
    /// @return totalDebt Total debt amount in asset decimals
    function debt(ILender.LenderStorage storage $, address _agent, address _asset)
        public
        view
        returns (uint256 totalDebt)
    {
        totalDebt =
            IERC20($.reservesData[_asset].debtToken).balanceOf(_agent) + accruedRestakerInterest($, _agent, _asset);
    }

    /// @notice Calculate the accrued restaker interest for an agent for a specific asset
    /// @param $ Lender storage
    /// @param _agent Agent address
    /// @param _asset Asset to calculate accrued interest for
    /// @return accruedInterest Accrued restaker interest in asset decimals
    function accruedRestakerInterest(ILender.LenderStorage storage $, address _agent, address _asset)
        public
        view
        returns (uint256 accruedInterest)
    {
        ILender.ReserveData storage reserve = $.reservesData[_asset];
        uint256 totalDebt = IERC20(reserve.debtToken).balanceOf(_agent);
        uint256 rate = IOracle($.oracle).restakerRate(_agent);
        uint256 elapsedTime = block.timestamp - reserve.lastRealizationTime[_agent];

        accruedInterest = totalDebt * rate * elapsedTime / (1e27 * SECONDS_IN_YEAR);
    }

    /// @notice Helper function to calculate the total debt of an agent across all assets
    /// @param $ Lender storage
    /// @param _agent Agent address
    /// @return totalDebt Total debt of an agent in USD, encoded with 8 decimals
    function calculateTotalDebt(ILender.LenderStorage storage $, address _agent)
        private
        view
        returns (uint256 totalDebt)
    {
        for (uint256 i; i < $.reservesCount; ++i) {
            if (!$.agentConfig[_agent].isBorrowing(i)) {
                continue;
            }

            address asset = $.reservesList[i];
            (uint256 assetPrice,) = IOracle($.oracle).getPrice(asset);
            if (assetPrice == 0) continue;

            ILender.ReserveData storage reserve = $.reservesData[asset];

            totalDebt += (IERC20(reserve.debtToken).balanceOf(_agent) + accruedRestakerInterest($, _agent, asset))
                .mulDiv(assetPrice, 10 ** reserve.decimals, Math.Rounding.Ceil);
        }
    }

    /// @dev Get the bonus for a liquidation in percentage ray decimals, max for emergencies and none if health is too low
    /// @param $ Lender storage
    /// @param _agent Agent address
    /// @return maxBonus Bonus percentage in ray decimals
    function bonus(ILender.LenderStorage storage $, address _agent) internal view returns (uint256 maxBonus) {
        (uint256 totalDelegation,, uint256 totalDebt,,,) = agent($, _agent);

        if (totalDelegation > totalDebt) {
            // Emergency liquidations get max bonus
            if (totalDelegation * $.emergencyLiquidationThreshold / totalDebt < 1e27) {
                maxBonus = $.bonusCap;
            } else {
                // Pro-rata bonus for non-emergency liquidations
                if (block.timestamp > ($.liquidationStart[_agent] + $.grace)) {
                    uint256 elapsed = block.timestamp - ($.liquidationStart[_agent] + $.grace);
                    uint256 duration = $.expiry - $.grace;
                    if (elapsed > duration) elapsed = duration;
                    maxBonus = $.bonusCap * elapsed / duration;
                }
            }

            uint256 maxHealthyBonus = (totalDelegation - totalDebt) * 1e27 / totalDebt;
            if (maxBonus > maxHealthyBonus) maxBonus = maxHealthyBonus;
        }
    }
}
