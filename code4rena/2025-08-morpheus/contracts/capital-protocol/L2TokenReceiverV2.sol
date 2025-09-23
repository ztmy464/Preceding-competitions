// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {IL2TokenReceiverV2, IERC165, IERC721Receiver} from "../interfaces/capital-protocol/IL2TokenReceiverV2.sol";
import {INonfungiblePositionManager} from "../interfaces/uniswap-v3/INonfungiblePositionManager.sol";

// L2代币接收器合约，负责在L2层处理代币交换和Uniswap V3流动性管理
contract L2TokenReceiverV2 is IL2TokenReceiverV2, OwnableUpgradeable, UUPSUpgradeable {
    // Uniswap V3交换路由器地址
    address public router;
    // Uniswap V3 NFT流动性头寸管理器地址
    address public nonfungiblePositionManager;

    // 第二个交换参数配置（用于特定的代币交换对）
    SwapParams public secondSwapParams;

    // Storage changes for L2TokenReceiverV2
    // 第一个交换参数配置（V2版本新增）
    SwapParams public firstSwapParams;

    constructor() {
        _disableInitializers();
    }

    // 合约初始化函数
    function L2TokenReceiver__init(
        address router_,                          // Uniswap V3路由器地址
        address nonfungiblePositionManager_,      // NFT头寸管理器地址
        // SwapParams memory firstSwapParams_,    // 第一个交换参数（已注释）
        SwapParams memory secondSwapParams_       // 第二个交换参数
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        router = router_;
        nonfungiblePositionManager = nonfungiblePositionManager_;

        // _addAllowanceUpdateSwapParams(firstSwapParams_, true);  // 已注释
        // 设置第二个交换参数并授权相关代币
        _addAllowanceUpdateSwapParams(secondSwapParams_, false);
    }

    // 检查合约是否支持指定接口
    function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {
        return
            interfaceId_ == type(IL2TokenReceiverV2).interfaceId ||
            interfaceId_ == type(IERC721Receiver).interfaceId ||      // 支持接收ERC721 NFT
            interfaceId_ == type(IERC165).interfaceId;
    }

    // 编辑交换参数配置（仅限合约拥有者）
    function editParams(SwapParams memory newParams_, bool isEditFirstParams_) external onlyOwner {
        // 获取要编辑的当前参数
        SwapParams memory params_ = _getSwapParams(isEditFirstParams_);

        // ------------------------------ 重置旧代币授权 -------------------------------
        // 如果输入代币发生变化，重置对旧输入代币的授权
        if (params_.tokenIn != address(0) && params_.tokenIn != newParams_.tokenIn) {
            // 重置路由器的授权
            TransferHelper.safeApprove(params_.tokenIn, router, 0);
            // 重置NFT头寸管理器的授权
            TransferHelper.safeApprove(params_.tokenIn, nonfungiblePositionManager, 0);
        }

        // 如果输出代币发生变化，重置对旧输出代币的授权
        if (params_.tokenOut != address(0) && params_.tokenOut != newParams_.tokenOut) {
            // 重置NFT头寸管理器的授权（输出代币也可能用于增加流动性）
            TransferHelper.safeApprove(params_.tokenOut, nonfungiblePositionManager, 0);
        }

        // ------------------------------ 设置新参数和授权 -------------------------------
        _addAllowanceUpdateSwapParams(newParams_, isEditFirstParams_);
    }

    // 提取指定代币到指定地址（仅限合约拥有者）
    function withdrawToken(address recipient_, address token_, uint256 amount_) external onlyOwner {
        TransferHelper.safeTransfer(token_, recipient_, amount_);
    }

    // 提取指定NFT代币到指定地址（仅限合约拥有者）
    function withdrawTokenId(address recipient_, address token_, uint256 tokenId_) external onlyOwner {
        // 安全转移ERC721代币（如Uniswap V3 LP NFT）
        IERC721(token_).safeTransferFrom(address(this), recipient_, tokenId_);
    }

    // 执行单跳代币交换（仅限合约拥有者）
    function swap(
        uint256 amountIn_,              // 输入代币数量
        uint256 amountOutMinimum_,      // 最小输出数量（滑点保护）
        uint256 deadline_,              // 交易截止时间
        bool isUseFirstSwapParams_      // 是否使用第一组交换参数
    ) external onlyOwner returns (uint256) {
        // ------------------------------ 获取交换参数 -------------------------------
        SwapParams memory params_ = _getSwapParams(isUseFirstSwapParams_);

        // ------------------------------ 构建交换参数 -------------------------------
        // 构建Uniswap V3精确输入单跳交换参数
        ISwapRouter.ExactInputSingleParams memory swapParams_ = ISwapRouter.ExactInputSingleParams({
            tokenIn: params_.tokenIn,                    // 输入代币地址
            tokenOut: params_.tokenOut,                  // 输出代币地址
            fee: params_.fee,                           // 交换池手续费等级
            recipient: address(this),                   // 接收地址（本合约）
            deadline: deadline_,                        // 截止时间
            amountIn: amountIn_,                       // 输入数量
            amountOutMinimum: amountOutMinimum_,       // 最小输出数量
            sqrtPriceLimitX96: params_.sqrtPriceLimitX96 // 价格限制（平方根格式）
        });

        // ------------------------------ 执行交换 -------------------------------
        // 通过Uniswap V3路由器执行精确输入交换
        uint256 amountOut_ = ISwapRouter(router).exactInputSingle(swapParams_);

        emit TokensSwapped(params_.tokenIn, params_.tokenOut, amountIn_, amountOut_, amountOutMinimum_);

        return amountOut_;
    }

    // 为现有的流动性头寸增加流动性（仅限合约拥有者）
    function increaseLiquidityCurrentRange(
        uint256 tokenId_,         // 流动性NFT的token ID
        uint256 amountAdd0_,      // 要添加的token0数量
        uint256 amountAdd1_,      // 要添加的token1数量
        uint256 amountMin0_,      // 最小token0数量（滑点保护）
        uint256 amountMin1_       // 最小token1数量（滑点保护）
    ) external onlyOwner returns (uint128 liquidity_, uint256 amount0_, uint256 amount1_) {
        // ------------------------------ 构建增加流动性参数 -------------------------------
        // 构建增加流动性的参数结构
        INonfungiblePositionManager.IncreaseLiquidityParams memory params_ = INonfungiblePositionManager
            .IncreaseLiquidityParams({
                tokenId: tokenId_,              // NFT头寸ID
                amount0Desired: amountAdd0_,    // 期望添加的token0数量
                amount1Desired: amountAdd1_,    // 期望添加的token1数量
                amount0Min: amountMin0_,        // 最小token0数量
                amount1Min: amountMin1_,        // 最小token1数量
                deadline: block.timestamp       // 使用当前时间戳作为截止时间
            });

        // ------------------------------ 执行增加流动性 -------------------------------
        // 通过NFT头寸管理器增加流动性
        (liquidity_, amount0_, amount1_) = INonfungiblePositionManager(nonfungiblePositionManager).increaseLiquidity(
            params_
        );

        emit LiquidityIncreased(tokenId_, amount0_, amount1_, liquidity_, amountMin0_, amountMin1_);
    }

    // 收集指定流动性头寸的手续费收入
    function collectFees(uint256 tokenId_) external returns (uint256 amount0_, uint256 amount1_) {
        // ------------------------------ 构建收费参数 -------------------------------
        // 构建收集手续费的参数结构
        INonfungiblePositionManager.CollectParams memory params_ = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId_,                  // NFT头寸ID
            recipient: address(this),           // 手续费接收地址（本合约）
            amount0Max: type(uint128).max,      // 最大收集token0数量（收集全部）
            amount1Max: type(uint128).max       // 最大收集token1数量（收集全部）
        });

        // ------------------------------ 执行收费 -------------------------------
        // 通过NFT头寸管理器收集手续费
        (amount0_, amount1_) = INonfungiblePositionManager(nonfungiblePositionManager).collect(params_);

        emit FeesCollected(tokenId_, amount0_, amount1_);
    }

    // 返回合约版本号
    function version() external pure returns (uint256) {
        return 2;
    }

    // ERC721接收器回调函数，允许合约接收NFT
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // 内部函数：添加代币授权并更新交换参数
    function _addAllowanceUpdateSwapParams(SwapParams memory newParams_, bool isEditFirstParams_) private {
        require(newParams_.tokenIn != address(0), "L2TR: invalid tokenIn");
        require(newParams_.tokenOut != address(0), "L2TR: invalid tokenOut");

        // ------------------------------ 设置代币授权 -------------------------------
        // 授权输入代币给路由器（用于交换）
        TransferHelper.safeApprove(newParams_.tokenIn, router, type(uint256).max);
        // 授权输入代币给NFT头寸管理器（用于增加流动性）
        TransferHelper.safeApprove(newParams_.tokenIn, nonfungiblePositionManager, type(uint256).max);

        // 授权输出代币给NFT头寸管理器（输出代币也可能用于增加流动性）
        TransferHelper.safeApprove(newParams_.tokenOut, nonfungiblePositionManager, type(uint256).max);

        // ------------------------------ 更新参数存储 -------------------------------
        if (isEditFirstParams_) {
            firstSwapParams = newParams_;
        } else {
            secondSwapParams = newParams_;
        }
    }

    // 内部函数：根据标志获取对应的交换参数
    function _getSwapParams(bool isUseFirstSwapParams_) internal view returns (SwapParams memory) {
        return isUseFirstSwapParams_ ? firstSwapParams : secondSwapParams;
    }

    // UUPS升级授权函数（仅限合约拥有者）
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}