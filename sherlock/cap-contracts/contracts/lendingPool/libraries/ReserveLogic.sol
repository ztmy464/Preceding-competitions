// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ILender } from "../../interfaces/ILender.sol";
import { ValidationLogic } from "./ValidationLogic.sol";

/// @title Reserve Logic
/// @author kexley, Cap Labs
/// @notice Add, remove or pause reserves on the Lender
library ReserveLogic {
    /// @dev Reserve added event
    event ReserveAssetAdded(
        address indexed asset, address vault, address debtToken, address interestReceiver, uint256 id
    );

    /// @dev Reserve removed event
    event ReserveAssetRemoved(address indexed asset);

    /// @dev Min borrow set event
    event ReserveMinBorrowUpdated(address indexed asset, uint256 minBorrow);

    /// @dev Reserve asset pause state updated event
    event ReserveAssetPauseStateUpdated(address indexed asset, bool paused);

    /// @dev No more reserves allowed
    error NoMoreReservesAllowed();

    /// @notice Add asset to the lender
    /// @param $ Lender storage
    /// @param params Parameters for adding an asset
    /// @return filled True if filling in empty space or false if appended
    function addAsset(ILender.LenderStorage storage $, ILender.AddAssetParams memory params)
        external
        returns (bool filled)
    {
        ValidationLogic.validateAddAsset($, params);

        uint256 id;

        for (uint256 i; i < $.reservesCount; ++i) {
            // Fill empty space if available
            if ($.reservesList[i] == address(0)) {
                $.reservesList[i] = params.asset;
                id = i;
                filled = true;
                break;
            }
        }

        if (!filled) {
            if ($.reservesCount + 1 >= 256) revert NoMoreReservesAllowed();
            id = $.reservesCount;
            $.reservesList[$.reservesCount] = params.asset;
        }

        ILender.ReserveData storage reserve = $.reservesData[params.asset];
        reserve.id = id;
        reserve.vault = params.vault;
        reserve.debtToken = params.debtToken;
        reserve.interestReceiver = params.interestReceiver;
        reserve.decimals = IERC20Metadata(params.asset).decimals();
        reserve.paused = true;
        reserve.minBorrow = params.minBorrow;

        emit ReserveAssetAdded(params.asset, params.vault, params.debtToken, params.interestReceiver, id);
    }

    /// @notice Set the minimum borrow amount for an asset
    /// @param $ Lender storage
    /// @param _asset Asset address
    /// @param _minBorrow Minimum borrow amount
    function setMinBorrow(ILender.LenderStorage storage $, address _asset, uint256 _minBorrow) external {
        ValidationLogic.validateSetMinBorrow($, _asset);
        $.reservesData[_asset].minBorrow = _minBorrow;

        emit ReserveMinBorrowUpdated(_asset, _minBorrow);
    }

    /// @notice Remove asset from lending when there is no borrows
    /// @param $ Lender storage
    /// @param _asset Asset address
    function removeAsset(ILender.LenderStorage storage $, address _asset) external {
        ValidationLogic.validateRemoveAsset($, _asset);

        $.reservesList[$.reservesData[_asset].id] = address(0);
        delete $.reservesData[_asset];

        emit ReserveAssetRemoved(_asset);
    }

    /// @notice Pause an asset from being borrowed
    /// @param $ Lender storage
    /// @param _asset Asset address
    /// @param _pause True if pausing or false if unpausing
    function pauseAsset(ILender.LenderStorage storage $, address _asset, bool _pause) external {
        ValidationLogic.validatePauseAsset($, _asset);
        $.reservesData[_asset].paused = _pause;

        emit ReserveAssetPauseStateUpdated(_asset, _pause);
    }
}
