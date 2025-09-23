// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import {ILayerZeroEndpoint} from "@layerzerolabs/lz-evm-sdk-v1-0.7/contracts/interfaces/ILayerZeroEndpoint.sol";

import {IGatewayRouter} from "@arbitrum/token-bridge-contracts/contracts/tokenbridge/libraries/gateway/IGatewayRouter.sol";

import {IL1SenderV2, IERC165} from "../interfaces/capital-protocol/IL1SenderV2.sol";
import {IDistributor} from "../interfaces/capital-protocol/IDistributor.sol";
import {IWStETH} from "../interfaces/tokens/IWStETH.sol";

// L1发送器合约，负责处理跨链桥接和代币交换
contract L1SenderV2 is IL1SenderV2, OwnableUpgradeable, UUPSUpgradeable {
    /** @dev stETH token address */
    // stETH代币地址（以太坊质押代币）
    address public stETH;

    /** @dev `Distributor` contract address. */
    // 分发器合约地址
    address public distributor;

    /** @dev The config for Arbitrum bridge. Send wstETH to the Arbitrum */
    // Arbitrum桥接配置，用于将wstETH发送到Arbitrum链
    ArbitrumBridgeConfig public arbitrumBridgeConfig;

    /** @dev The config for LayerZero. Send MOR mint message to the Arbitrum */
    // LayerZero配置，用于向Arbitrum发送MOR铸币消息
    LayerZeroConfig public layerZeroConfig;

    /** @dev UPGRADE `L1SenderV2` storage updates, add Uniswap integration  */
    // Uniswap交换路由器地址，用于代币交换
    address public uniswapSwapRouter;

    /**********************************************************************************************/
    /*** Init, IERC165                                                                          ***/
    /**********************************************************************************************/

    constructor() {
        _disableInitializers();
    }

    // 合约初始化函数
    function L1SenderV2__init() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // 检查合约是否支持指定接口
    function supportsInterface(bytes4 interfaceId_) external pure returns (bool) {
        return interfaceId_ == type(IL1SenderV2).interfaceId || interfaceId_ == type(IERC165).interfaceId;
    }

    /**********************************************************************************************/
    /*** Global contract management functionality for the contract `owner()`                    ***/
    /**********************************************************************************************/

    // 设置stETH代币地址（仅限合约拥有者）
    function setStETh(address value_) external onlyOwner {
        require(value_ != address(0), "L1S: invalid stETH address");

        stETH = value_;

        emit stETHSet(value_);
    }

    // 设置分发器合约地址（仅限合约拥有者）
    function setDistributor(address value_) external onlyOwner {
        // 验证新地址是否实现了IDistributor接口
        require(IERC165(value_).supportsInterface(type(IDistributor).interfaceId), "L1S: invalid distributor address");

        distributor = value_;

        emit DistributorSet(value_);
    }

    /**
     * https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments
     */
    // 设置Uniswap交换路由器地址（仅限合约拥有者）
    function setUniswapSwapRouter(address value_) external onlyOwner {
        require(value_ != address(0), "L1S: invalid `uniswapSwapRouter` address");

        uniswapSwapRouter = value_;

        emit UniswapSwapRouterSet(value_);
    }

    /**********************************************************************************************/
    /*** LayerZero functionality                                                                ***/
    /**********************************************************************************************/

    /**
     * @dev https://docs.layerzero.network/v1/deployments/deployed-contracts
     * Gateway - see `EndpointV1` at the link
     * Receiver - `L2MessageReceiver` address
     * Receiver Chain Id - see `EndpointId` at the link
     * Zro Payment Address - the address of the ZRO token holder who would pay for the transaction
     * Adapter Params - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
     */
    // 设置LayerZero跨链配置（仅限合约拥有者）
    function setLayerZeroConfig(LayerZeroConfig calldata layerZeroConfig_) external onlyOwner {
        layerZeroConfig = layerZeroConfig_;

        emit LayerZeroConfigSet(layerZeroConfig_);
    }

    // 通过LayerZero发送铸币消息到目标链（仅限分发器调用）
    //~ 在目标链 L2 上会部署一个 L2MessageReceiver 或类似的合约。
    //~ 它实现了 LayerZero 的 lzReceive(...) 接口，当收到 L1 发来的消息时：
    //~ 解析 payload（得到 user 和 amount）,调用 Token 合约 mint() 给 user
    function sendMintMessage(address user_, uint256 amount_, address refundTo_) external payable {
        // 只有分发器可以调用此函数
        require(_msgSender() == distributor, "L1S: the `msg.sender` isn't `distributor`");

        LayerZeroConfig storage config = layerZeroConfig;

        // ------------------------------ 构建跨链消息 -------------------------------
        // 编码接收者和发送者地址
        bytes memory receiverAndSenderAddresses_ = abi.encodePacked(config.receiver, address(this));
        // 编码用户地址和铸币数量作为消息载荷
        bytes memory payload_ = abi.encode(user_, amount_);

        // https://docs.layerzero.network/v1/developers/evm/evm-guides/send-messages
        // ------------------------------ 发送跨链消息 -------------------------------
        // 通过LayerZero端点发送消息到目标链
        ILayerZeroEndpoint(config.gateway).send{value: msg.value}(
            config.receiverChainId,    // 目标链ID
            receiverAndSenderAddresses_, // 接收者和发送者地址
            payload_,                  // 消息载荷（用户地址和数量）
            payable(refundTo_),        // 退款地址
            config.zroPaymentAddress,  // ZRO代币支付地址
            config.adapterParams       // 适配器参数
        );

        emit MintMessageSent(user_, amount_);
    }

    /**********************************************************************************************/
    /*** Arbitrum bridge functionality                                                          ***/
    /**********************************************************************************************/

    /**
     * @dev https://docs.arbitrum.io/build-decentralized-apps/reference/contract-addresses
     * wstETH - the wstETH token address
     * Gateway - see `L1 Gateway Router` at the link
     * Receiver - `L2MessageReceiver` address
     */
    // 设置Arbitrum桥接配置（仅限合约拥有者）
    function setArbitrumBridgeConfig(ArbitrumBridgeConfig calldata newConfig_) external onlyOwner {
        require(stETH != address(0), "L1S: stETH is not set");
        require(newConfig_.receiver != address(0), "L1S: invalid receiver");

        ArbitrumBridgeConfig memory oldConfig_ = arbitrumBridgeConfig;

        // ------------------------------ 重置旧配置的授权 -------------------------------
        if (oldConfig_.wstETH != address(0)) {
            // 重置对旧wstETH合约的授权
            IERC20(stETH).approve(oldConfig_.wstETH, 0);
            // 重置对旧网关的授权
            //~ getGateway: 输入一个 L1 Token（比如 wstETH），
            //~ 返回它的 Gateway 合约(Token 跨链的中转合约，负责 L1 ↔ L2 的资产转移)
            IERC20(oldConfig_.wstETH).approve(IGatewayRouter(oldConfig_.gateway).getGateway(oldConfig_.wstETH), 0);
        }

        // ------------------------------ 设置新配置的授权 -------------------------------
        // 授权新wstETH合约可以使用stETH
        IERC20(stETH).approve(newConfig_.wstETH, type(uint256).max);
        // 授权新网关可以使用wstETH进行桥接
        IERC20(newConfig_.wstETH).approve(
            IGatewayRouter(newConfig_.gateway).getGateway(newConfig_.wstETH),
            type(uint256).max
        );

        arbitrumBridgeConfig = newConfig_;

        emit ArbitrumBridgeConfigSet(newConfig_);
    }

    // 将wstETH发送到Arbitrum链（仅限合约拥有者）
    function sendWstETH(
        uint256 gasLimit_,           // Gas限制
        uint256 maxFeePerGas_,       // 最大Gas费用
        uint256 maxSubmissionCost_   // 最大提交成本
    ) external payable onlyOwner returns (bytes memory) {
        ArbitrumBridgeConfig memory config_ = arbitrumBridgeConfig;
        require(config_.wstETH != address(0), "L1S: wstETH isn't set");

        // ------------------------------ 包装stETH为wstETH -------------------------------
        // 获取合约中的stETH余额
        uint256 stETHBalance_ = IERC20(stETH).balanceOf(address(this));
        if (stETHBalance_ > 0) {
            // 将stETH包装成wstETH（wrapped staked ETH）
            //~ wstETH 本身不会 rebase，而是通过 兑换率变化来反映收益
            IWStETH(config_.wstETH).wrap(stETHBalance_);
        }

        // 获取包装后的wstETH数量
        uint256 amount_ = IWStETH(config_.wstETH).balanceOf(address(this));

        // ------------------------------ 执行跨链桥接 -------------------------------
        // 构建桥接数据，包含提交成本和空字符串
        bytes memory data_ = abi.encode(maxSubmissionCost_, "");

        //~ 通过Arbitrum网关路由器发送wstETH到L2
        bytes memory res_ = IGatewayRouter(config_.gateway).outboundTransfer{value: msg.value}(
            config_.wstETH,        // 要桥接的代币地址
            config_.receiver,      // L2接收者地址
            amount_,               // 桥接数量
            gasLimit_,             // Gas限制
            maxFeePerGas_,         // 最大Gas费用
            data_                  // 桥接数据
        );

        emit WstETHSent(amount_, gasLimit_, maxFeePerGas_, maxSubmissionCost_, res_);

        return res_;
    }

    /**********************************************************************************************/
    /*** Uniswap functionality                                                                  ***/
    /**********************************************************************************************/

    /**
     * @dev https://docs.uniswap.org/contracts/v3/guides/swaps/multihop-swaps
     *
     * Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence
     * of token addresses and poolFees that define the pools used in the swaps.
     * The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where
     * tokenIn/tokenOut parameter is the shared token across the pools.
     * Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
     */
    // 通过Uniswap V3执行多跳代币交换（仅限合约拥有者）
    function swapExactInputMultihop(
        address[] calldata tokens_,      // 代币地址数组，按交换顺序排列
        uint24[] calldata poolsFee_,     // 每个交换池的手续费数组
        uint256 amountIn_,               // 输入代币数量
        uint256 amountOutMinimum_,       // 最小输出代币数量（滑点保护）
        uint256 deadline_                // 交易截止时间
    ) external onlyOwner returns (uint256) {
        // ------------------------------ 参数验证 -------------------------------
        // 验证代币数组长度（至少2个代币）和费用数组长度（比代币数组少1）
        require(tokens_.length >= 2 && tokens_.length == poolsFee_.length + 1, "L1S: invalid array length");
        require(amountIn_ != 0, "L1S: invalid `amountIn_` value");
        require(amountOutMinimum_ != 0, "L1S: invalid `amountOutMinimum_` value");

        // 授权Uniswap路由器使用输入代币
        TransferHelper.safeApprove(tokens_[0], uniswapSwapRouter, amountIn_);

        // ------------------------------ 构建交换路径 -------------------------------
        // START create the `path`
        // 按照Uniswap V3的格式构建交换路径
        // 格式：(tokenIn, fee, tokenOut/tokenIn, fee, tokenOut)
        bytes memory path_;
        for (uint256 i = 0; i < poolsFee_.length; i++) {
            // 将代币地址和对应的池费用编码到路径中
            path_ = abi.encodePacked(path_, tokens_[i], poolsFee_[i]);
        }
        // 添加最后一个代币地址
        path_ = abi.encodePacked(path_, tokens_[tokens_.length - 1]);
        // END

        // ------------------------------ 执行多跳交换 -------------------------------
        // 构建Uniswap交换参数
        ISwapRouter.ExactInputParams memory params_ = ISwapRouter.ExactInputParams({
            path: path_,                    // 交换路径
            recipient: address(this),       // 接收地址（本合约）
            deadline: deadline_,            // 截止时间
            amountIn: amountIn_,           // 输入数量
            amountOutMinimum: amountOutMinimum_ // 最小输出数量
        });

        // 执行精确输入的多跳交换
        uint256 amountOut_ = ISwapRouter(uniswapSwapRouter).exactInput(params_);

        emit TokensSwapped(path_, amountIn_, amountOut_);

        return amountOut_;
    }

    /**********************************************************************************************/
    /*** UUPS                                                                                   ***/
    /**********************************************************************************************/

    // 返回合约版本号
    function version() external pure returns (uint256) {
        return 2;
    }

    // UUPS升级授权函数（仅限合约拥有者）
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}