// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDepositor} from "../interfaces/IDepositor.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

contract yUSDeDepositor is IDepositor, OwnableUpgradeable  {

    IERC4626 public pUSDe;
    IDepositor public pUSDeDepositor;

    IERC4626 public yUSDe;

    event SwapInfoChanged(address indexed token);

    error InvalidAsset(address asset);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_
        , IERC4626 yUSDe_
        , IERC4626 pUSDe_
        , IDepositor pUSDeDepositor_
    ) public virtual initializer {
        __Ownable_init_unchained(owner_);

        yUSDe = yUSDe_;
        pUSDe = pUSDe_;
        pUSDeDepositor = pUSDeDepositor_;
    }


    /**
     * @notice Deposits assets into the vault
     * @dev Accepted assets:
     *      1. pUSDe: Deposited as-is
     *      2. USDe, sUSDe, stables: First staked to receive pUSDe, then deposited
     * @param asset The address of the asset to deposit
     * @param amount The amount of the asset to deposit
     * @return uint256 The amount of yUSDe tokens minted
     */
    function deposit(IERC20 asset, uint256 amount, address receiver) external returns (uint256) {
        address user = _msgSender();
        if (asset == pUSDe) {
            return _deposit_pUSDe(user, amount, receiver);
        }

        return _deposit_pUSDeDepositor(user, asset, amount, receiver);
    }

    function _deposit_pUSDe (address from, uint256 amount, address receiver) internal returns (uint256) {
        require(amount > 0, "Deposit is zero");

        IERC4626 pUSDe_ = pUSDe;
        if (from != address(this)) {
            SafeERC20.safeTransferFrom(pUSDe_, from, address(this), amount);
        }
        SafeERC20.forceApprove(pUSDe_, address(yUSDe), amount);
        return yUSDe.deposit(amount, receiver);
    }

    function _deposit_pUSDeDepositor (address from, IERC20 asset, uint256 amount, address receiver) internal returns (uint256) {
        require(amount > 0, "Deposit is zero");

        uint256 beforeAmount = asset.balanceOf(address(this));

        if (from != address(this)) {
            // Get USDe Tokens
            SafeERC20.safeTransferFrom(asset, from, address(this), amount);
        } else {
            require(beforeAmount >= amount, "Insufficient USDe amount");
        }
        uint256 pUSDeShares = pUSDeDepositor.deposit(asset, amount, address(this));
        return _deposit_pUSDe(address(this), pUSDeShares, receiver);
    }

}
