// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { IMinter } from "../../interfaces/IMinter.sol";
import { IOracle } from "../../interfaces/IOracle.sol";
import { IVault } from "../../interfaces/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Amount Out Logic
/// @author kexley, Cap Labs
/// @notice Amount out logic for exchanging underlying assets with cap tokens
library MinterLogic {
    /// @dev Ray precision
    uint256 constant RAY_PRECISION = 1e27;

    /// @dev Share precision
    uint256 constant SHARE_PRECISION = 1e33;

    /// @notice Calculate the amount out from a swap including fees
    /// @param $ Storage pointer
    /// @param params Parameters for a swap
    /// @return amount Amount out from a swap
    /// @return fee Fee applied
    function amountOut(IMinter.MinterStorage storage $, IMinter.AmountOutParams memory params)
        external
        view
        returns (uint256 amount, uint256 fee)
    {
        (uint256 amountOutBeforeFee, uint256 newRatio) = _amountOutBeforeFee($.oracle, params);

        if ($.whitelist[msg.sender]) {
            amount = amountOutBeforeFee;
        } else {
            (amount, fee) = _applyFeeSlopes(
                $.fees[params.asset],
                IMinter.FeeSlopeParams({ mint: params.mint, amount: amountOutBeforeFee, ratio: newRatio })
            );
        }
    }

    /// @notice Calculate the output amounts for redeeming a cap token for a proportional weighting
    /// @param $ Storage pointer
    /// @param params Parameters for redeeming
    /// @return amounts Amount of underlying assets withdrawn
    /// @return fees Amount of fees applied
    function redeemAmountOut(IMinter.MinterStorage storage $, IMinter.RedeemAmountOutParams memory params)
        external
        view
        returns (uint256[] memory amounts, uint256[] memory fees)
    {
        uint256 redeemFee = $.whitelist[msg.sender] ? 0 : $.redeemFee;
        uint256 shares = params.amount * SHARE_PRECISION / IERC20(address(this)).totalSupply();
        address[] memory assets = IVault(address(this)).assets();
        uint256 assetLength = assets.length;
        amounts = new uint256[](assetLength);
        fees = new uint256[](assetLength);
        for (uint256 i; i < assetLength; ++i) {
            address asset = assets[i];
            uint256 withdrawAmount = IVault(address(this)).totalSupplies(asset) * shares / SHARE_PRECISION;

            fees[i] = withdrawAmount * redeemFee / RAY_PRECISION;
            amounts[i] = withdrawAmount - fees[i];
        }
    }

    /// @notice Calculate the amount out for a swap before fees
    /// @param _oracle Oracle address
    /// @param params Parameters for a swap
    /// @return amount Amount out from a swap before fees
    /// @return newRatio New ratio of an asset to the overall basket after swap
    function _amountOutBeforeFee(address _oracle, IMinter.AmountOutParams memory params)
        internal
        view
        returns (uint256 amount, uint256 newRatio)
    {
        (uint256 assetPrice,) = IOracle(_oracle).getPrice(params.asset);
        (uint256 capPrice,) = IOracle(_oracle).getPrice(address(this));

        uint256 assetDecimalsPow = 10 ** IERC20Metadata(params.asset).decimals();
        uint256 capDecimalsPow = 10 ** IERC20Metadata(address(this)).decimals();

        uint256 capSupply = IERC20(address(this)).totalSupply();
        uint256 capValue = capSupply * capPrice / capDecimalsPow;
        uint256 allocationValue = IVault(address(this)).totalSupplies(params.asset) * assetPrice / assetDecimalsPow;

        uint256 assetValue;
        if (params.mint) {
            assetValue = params.amount * assetPrice / assetDecimalsPow;
            if (capSupply == 0) {
                newRatio = 0;
                amount = assetValue * capDecimalsPow / assetPrice;
            } else {
                newRatio = (allocationValue + assetValue) * RAY_PRECISION / (capValue + assetValue);
                amount = assetValue * capDecimalsPow / capPrice;
            }
        } else {
            assetValue = params.amount * capPrice / capDecimalsPow;
            if (params.amount == capSupply) {
                newRatio = RAY_PRECISION;
                amount = assetValue * assetDecimalsPow / assetPrice;
            } else {
                if (allocationValue < assetValue || capValue <= assetValue) {
                    newRatio = 0;
                } else {
                    newRatio = (allocationValue - assetValue) * RAY_PRECISION / (capValue - assetValue);
                }
                amount = assetValue * assetDecimalsPow / assetPrice;
            }
        }
    }

    /// @notice Apply fee slopes to a mint or burn
    /// @dev Fees only apply to mints or burns that over-allocate the basket to one asset
    /// @param fees Fee slopes and ratio kinks
    /// @param params Fee slope parameters
    /// @return amount Remaining amount after fee applied
    /// @return fee Fee applied
    function _applyFeeSlopes(IMinter.FeeData memory fees, IMinter.FeeSlopeParams memory params)
        internal
        pure
        returns (uint256 amount, uint256 fee)
    {
        uint256 rate;
        if (params.mint) {
            rate = fees.minMintFee;
            if (params.ratio > fees.optimalRatio) {
                if (params.ratio > fees.mintKinkRatio) {
                    uint256 excessRatio = params.ratio - fees.mintKinkRatio;
                    rate += fees.slope0 + (fees.slope1 * excessRatio / (RAY_PRECISION - fees.mintKinkRatio));
                } else {
                    rate += fees.slope0 * (params.ratio - fees.optimalRatio) / (fees.mintKinkRatio - fees.optimalRatio);
                }
            }
        } else {
            if (params.ratio < fees.optimalRatio) {
                if (params.ratio < fees.burnKinkRatio) {
                    uint256 excessRatio = fees.burnKinkRatio - params.ratio;
                    rate = fees.slope0 + (fees.slope1 * excessRatio / fees.burnKinkRatio);
                } else {
                    rate = fees.slope0 * (fees.optimalRatio - params.ratio) / (fees.optimalRatio - fees.burnKinkRatio);
                }
            }
        }

        if (rate > RAY_PRECISION) rate = RAY_PRECISION;
        fee = params.amount * rate / RAY_PRECISION;
        amount = params.amount - fee;
    }
}
