// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IDebtToken } from "../../interfaces/IDebtToken.sol";
import { IDelegation } from "../../interfaces/IDelegation.sol";
import { ILender } from "../../interfaces/ILender.sol";
import { IVault } from "../../interfaces/IVault.sol";
import { ValidationLogic } from "./ValidationLogic.sol";
import { ViewLogic } from "./ViewLogic.sol";
import { AgentConfiguration } from "./configuration/AgentConfiguration.sol";

/// @title BorrowLogic
/// @author kexley, Cap Labs
/// @notice Logic for borrowing and repaying assets from the Lender
/// @dev Interest rates for borrowing are not based on utilization like other lending markets.
/// Instead the rates are based on a benchmark rate per asset set by an admin or an alternative
/// lending market rate, whichever is higher. Indexes representing the increase of interest over
/// time are pulled from an oracle. A separate interest rate is set by admin per agent which is
/// paid to the restakers that guarantee the agent.
library BorrowLogic {
    using SafeERC20 for IERC20;
    using AgentConfiguration for ILender.AgentConfigurationMap;

    /// @dev Details of a repayment
    /// @param repaid Amount repaid
    /// @param vaultRepaid Amount repaid to the vault
    /// @param restakerRepaid Amount repaid to the restaker
    /// @param interestRepaid Amount repaid to the interest receiver
    struct RepaymentDetails {
        uint256 repaid;
        uint256 vaultRepaid;
        uint256 restakerRepaid;
        uint256 interestRepaid;
    }

    /// @dev An agent has borrowed an asset from the Lender
    event Borrow(address indexed asset, address indexed agent, uint256 amount);

    /// @dev An agent, or someone on behalf of an agent, has repaid
    event Repay(address indexed asset, address indexed agent, RepaymentDetails details);

    /// @dev An agent has totally repaid their debt of an asset including all interests
    event TotalRepayment(address indexed agent, address indexed asset);

    /// @dev Realize interest before it is repaid by agents
    event RealizeInterest(address indexed asset, uint256 realizedInterest, address interestReceiver);

    /// @dev Trying to realize zero interest
    error ZeroRealization();

    /// @notice Borrow an asset from the Lender, minting a debt token which must be repaid
    /// @dev Interest debt token is updated before principal token is minted to bring index up to date.
    /// Restaker debt token is updated after so the new principal debt can be used in calculations
    /// @param $ Lender storage
    /// @param params Parameters to borrow an asset
    /// @return borrowed Actual amount borrowed
    function borrow(ILender.LenderStorage storage $, ILender.BorrowParams memory params)
        external
        returns (uint256 borrowed)
    {
        /// Realize restaker interest before borrowing
        realizeRestakerInterest($, params.agent, params.asset);

        if (params.maxBorrow) {
            params.amount = ViewLogic.maxBorrowable($, params.agent, params.asset);
        }

        ValidationLogic.validateBorrow($, params);

        IDelegation($.delegation).setLastBorrow(params.agent);

        ILender.ReserveData storage reserve = $.reservesData[params.asset];
        if (!$.agentConfig[params.agent].isBorrowing(reserve.id)) {
            $.agentConfig[params.agent].setBorrowing(reserve.id, true);
        }

        borrowed = params.amount;

        IVault(reserve.vault).borrow(params.asset, borrowed, params.receiver);

        IDebtToken(reserve.debtToken).mint(params.agent, borrowed);

        reserve.debt += borrowed;

        emit Borrow(params.asset, params.agent, borrowed);
    }

    /// @notice Repay an asset, burning the debt token and/or paying down interest
    /// @dev Only the amount owed or specified will be taken from the repayer, whichever is lower.
    /// Interest is expected to have been realized so is included in the reserve debt. Once reserve
    /// debt is paid down the remaining amount is sent to the fee auction.
    /// @param $ Lender storage
    /// @param params Parameters to repay a debt
    /// @return repaid Actual amount repaid
    function repay(ILender.LenderStorage storage $, ILender.RepayParams memory params)
        external
        returns (uint256 repaid)
    {
        /// Realize restaker interest before repaying
        realizeRestakerInterest($, params.agent, params.asset);

        ILender.ReserveData storage reserve = $.reservesData[params.asset];

        /// Can only repay up to the amount owed
        uint256 agentDebt = IERC20(reserve.debtToken).balanceOf(params.agent);
        repaid = Math.min(params.amount, agentDebt);

        uint256 remainingDebt = agentDebt - repaid;
        if (remainingDebt > 0 && remainingDebt < reserve.minBorrow) {
            // Limit repayment to maintain minimum debt if not full repayment
            repaid = agentDebt - reserve.minBorrow;
        }

        IERC20(params.asset).safeTransferFrom(params.caller, address(this), repaid);

        uint256 remaining = repaid;
        uint256 interestRepaid;
        uint256 restakerRepaid;

        if (repaid > reserve.unrealizedInterest[params.agent] + reserve.debt) {
            interestRepaid = repaid - (reserve.debt + reserve.unrealizedInterest[params.agent]);
            remaining -= interestRepaid;
        }

        if (remaining > reserve.unrealizedInterest[params.agent]) {
            restakerRepaid = reserve.unrealizedInterest[params.agent];
            remaining -= restakerRepaid;
        } else {
            restakerRepaid = remaining;
            remaining = 0;
        }

        uint256 vaultRepaid = Math.min(remaining, reserve.debt);

        if (restakerRepaid > 0) {
            reserve.unrealizedInterest[params.agent] -= restakerRepaid;
            reserve.totalUnrealizedInterest -= restakerRepaid;
            IERC20(params.asset).safeTransfer($.delegation, restakerRepaid);
            IDelegation($.delegation).distributeRewards(params.agent, params.asset);
            emit RealizeInterest(params.asset, restakerRepaid, $.delegation);
        }

        if (vaultRepaid > 0) {
            reserve.debt -= vaultRepaid;
            IERC20(params.asset).forceApprove(reserve.vault, vaultRepaid);
            IVault(reserve.vault).repay(params.asset, vaultRepaid);
        }

        if (interestRepaid > 0) {
            IERC20(params.asset).safeTransfer(reserve.interestReceiver, interestRepaid);
            emit RealizeInterest(params.asset, interestRepaid, reserve.interestReceiver);
        }

        IDebtToken(reserve.debtToken).burn(params.agent, repaid);

        if (IERC20(reserve.debtToken).balanceOf(params.agent) == 0) {
            $.agentConfig[params.agent].setBorrowing(reserve.id, false);
            emit TotalRepayment(params.agent, params.asset);
        }

        emit Repay(
            params.asset,
            params.agent,
            RepaymentDetails({
                repaid: repaid,
                vaultRepaid: vaultRepaid,
                restakerRepaid: restakerRepaid,
                interestRepaid: interestRepaid
            })
        );
    }

    /// @notice Realize the interest before it is repaid by borrowing from the vault
    /// @param $ Lender storage
    /// @param _asset Asset to realize interest for
    /// @return realizedInterest Actual realized interest
    function realizeInterest(ILender.LenderStorage storage $, address _asset)
        external
        returns (uint256 realizedInterest)
    {
        ILender.ReserveData storage reserve = $.reservesData[_asset];
        realizedInterest = maxRealization($, _asset);
        if (realizedInterest == 0) revert ZeroRealization();

        reserve.debt += realizedInterest;
        IVault(reserve.vault).borrow(_asset, realizedInterest, reserve.interestReceiver);
        emit RealizeInterest(_asset, realizedInterest, reserve.interestReceiver);
    }

    /// @notice Realize the restaker interest before it is repaid by borrowing from the vault
    /// @dev If more interest is owed than available in the vault then some portion is unrealized
    /// and added to the agent's debt to be paid during repayments.
    /// @param $ Lender storage
    /// @param _agent Address of the restaker
    /// @param _asset Asset to realize restaker interest for
    /// @return realizedInterest Actual realized restaker interest
    function realizeRestakerInterest(ILender.LenderStorage storage $, address _agent, address _asset)
        public
        returns (uint256 realizedInterest)
    {
        ILender.ReserveData storage reserve = $.reservesData[_asset];
        uint256 unrealizedInterest;
        (realizedInterest, unrealizedInterest) = maxRestakerRealization($, _agent, _asset);
        reserve.lastRealizationTime[_agent] = block.timestamp;

        if (realizedInterest == 0 && unrealizedInterest == 0) return 0;

        reserve.debt += realizedInterest;
        reserve.unrealizedInterest[_agent] += unrealizedInterest;
        reserve.totalUnrealizedInterest += unrealizedInterest;

        IDebtToken(reserve.debtToken).mint(_agent, realizedInterest + unrealizedInterest);
        IVault(reserve.vault).borrow(_asset, realizedInterest, $.delegation);
        IDelegation($.delegation).distributeRewards(_agent, _asset);
        emit RealizeInterest(_asset, realizedInterest, $.delegation);
    }

    /// @notice Calculate the maximum interest that can be realized
    /// @param $ Lender storage
    /// @param _asset Asset to calculate max realization for
    /// @return realization Maximum interest that can be realized
    function maxRealization(ILender.LenderStorage storage $, address _asset)
        internal
        view
        returns (uint256 realization)
    {
        ILender.ReserveData storage reserve = $.reservesData[_asset];
        uint256 totalDebt = IERC20(reserve.debtToken).totalSupply();
        uint256 reserves = IVault(reserve.vault).availableBalance(_asset);
        uint256 vaultDebt = reserve.debt;
        uint256 totalUnrealizedInterest = reserve.totalUnrealizedInterest;

        if (totalDebt > vaultDebt + totalUnrealizedInterest) {
            realization = totalDebt - vaultDebt - totalUnrealizedInterest;
        }
        if (reserves < realization) {
            realization = reserves;
        }
        if (reserve.paused) realization = 0;
    }

    /// @notice Calculate the maximum interest that can be realized for a restaker
    /// @param $ Lender storage
    /// @param _agent Address of the restaker
    /// @param _asset Asset to calculate max realization for
    /// @return realization Maximum interest that can be realized
    /// @return unrealizedInterest Unrealized interest that can be realized
    function maxRestakerRealization(ILender.LenderStorage storage $, address _agent, address _asset)
        internal
        view
        returns (uint256 realization, uint256 unrealizedInterest)
    {
        ILender.ReserveData storage reserve = $.reservesData[_asset];
        uint256 accruedInterest = ViewLogic.accruedRestakerInterest($, _agent, _asset);
        uint256 reserves = IVault(reserve.vault).availableBalance(_asset);

        realization = accruedInterest;
        if (reserve.paused) {
            unrealizedInterest = realization;
            realization = 0;
        } else if (realization > reserves) {
            unrealizedInterest = realization - reserves;
            realization = reserves;
        }
    }
}
