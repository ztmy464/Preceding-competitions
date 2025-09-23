// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
//~ OFT（Omnichain Fungible Token）
// https://github.com/LayerZero-Labs/devtools/tree/main/packages/oft-evm/contracts
// OFT：通过 LayerZero 消息跨链时，源链销毁，目标链铸造。
// OFT 已经实现了跨链收发的核心逻辑（_debitFrom/_credit 等），本合约继承它并覆写 _credit

contract Titn is OFT {
    // Bridged token holder may have transfer restricted
    mapping(address => bool) public isBridgedTokenHolder;
    bool private isBridgedTokensTransferLocked;
    address public transferAllowedContract;
    address private lzEndpoint;

    error BridgedTokensTransferLocked();

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        uint256 initialMintAmount
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        _mint(msg.sender, initialMintAmount);
        lzEndpoint = _lzEndpoint;
        isBridgedTokensTransferLocked = true;
    }

    //////////////////////////////
    //  External owner setters  //
    //////////////////////////////

    event TransferAllowedContractUpdated(address indexed transferAllowedContract);
    function setTransferAllowedContract(address _transferAllowedContract) external onlyOwner {
        transferAllowedContract = _transferAllowedContract;
        emit TransferAllowedContractUpdated(_transferAllowedContract);
    }

    function getTransferAllowedContract() external view returns (address) {
        return transferAllowedContract;
    }

    event BridgedTokenTransferLockUpdated(bool isLocked);
    function setBridgedTokenTransferLocked(bool _isLocked) external onlyOwner {
        isBridgedTokensTransferLocked = _isLocked;
        emit BridgedTokenTransferLockUpdated(_isLocked);
    }

    function getBridgedTokenTransferLocked() external view returns (bool) {
        return isBridgedTokensTransferLocked;
    }

    //////////////////////////////
    //         Overrides        //
    //////////////////////////////

    //~ @audit [H-2] The user can send tokens to any address by using two bridge transfers (`send`), 
    //~ even when transfers are restricted. 

    /* 
    当 isBridgedTokensTransferLocked 设置为 true 时，普通用户的 transfer 和 transferFrom 作将受到限制。
    普通用户不应将他们的代币发送到 transferAllowedContract 和 lzEndpoint 以外的任何地址。
    然而，由于桥接(`send`)不受此限制，用户可以通过执行两次桥接转账将代币发送到任何地址。

    only overrides the transfer and transferFrom functions, adding the _validateTransfer validation to restrict.
    However, since bridge operations(`send`) do not use transfer/transferFrom, but instead use mint/burn, 
    this allows users to transfer tokens to any address by performing two bridge operations.
     */

    //~ mitigation：将桥接限制为仅自己的地址. 
    /*     
    function _send(
    SendParam calldata _sendParam,
    MessagingFee calldata _fee,
    address _refundAddress
    ) internal virtual override returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        // Enforce bridging to the same address that is sending from source:
    ~    require(_sendParam.to == bytes32(uint256(uint160(msg.sender))), "Must bridge to your own address");

        ....
    }

    */
    //~ @audit Mitigation Review: 将桥接限制为仅自己的地址可能会影响合约和 AA 钱包的代币集成
    /*     
    function _send(
    SendParam calldata _sendParam,
    MessagingFee calldata _fee,
    address _refundAddress
    ) internal virtual override returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
-       require(_sendParam.to == bytes32(uint256(uint160(msg.sender))), "Must bridge to your own address");
+       if (isBridgedTokensTransferLocked) {
+           require(_sendParam.to == bytes32(uint256(uint160(msg.sender))), "Must bridge to your own address");
+       }
        ....
    }
    */
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        _validateTransfer(msg.sender, to);
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _validateTransfer(from, to);
        return super.transferFrom(from, to, amount);
    }
    /**
     * @dev Validates transfer restrictions.
     * @param from The sender's address.
     * @param to The recipient's address.
     */
    function _validateTransfer(address from, address to) internal view {
        // Arbitrum chain ID
        uint256 arbitrumChainId = 42161;

        // Check if the transfer is restricted
        if (
            from != owner() && // Exclude owner from restrictions
            from != transferAllowedContract && // Allow transfers to the transferAllowedContract
            to != transferAllowedContract && // Allow transfers to the transferAllowedContract
            isBridgedTokensTransferLocked && // Check if bridged transfers are locked
            // Restrict bridged token holders OR apply Arbitrum-specific restriction
            //~ 非 Arbitrum 链上，只有“bridged 过来”的地址会被锁；Arbitrum 链上，默认所有地址都会被锁（除非豁免）
            (isBridgedTokenHolder[from] || block.chainid == arbitrumChainId) &&
            to != lzEndpoint // Allow transfers to LayerZero endpoint
        ) {
            revert BridgedTokensTransferLocked();
        }
    }

    /**
     * @dev Credits tokens to the specified address.
     * @param _to The address to credit the tokens to.
     * @param _amountLD The amount of tokens to credit in local decimals.
     * @dev _srcEid The source chain ID.
     * @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals.
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 /*_srcEid*/
    ) internal virtual override returns (uint256 amountReceivedLD) {
        if (_to == address(0x0)) _to = address(0xdead); // _mint(...) does not support address(0x0)
        // Default OFT mints on dst.
        _mint(_to, _amountLD);

        //~ @audit [M-1] Improper Transfer Restrictions on Non-Bridged Tokens Due to Boolean Bridged Token Tracking
        // 一旦地址收到任何桥接代币（通过跨链桥接），它就会被永久标记为“桥接代币持有者”，
        // 该地址持有的所有代币（包括非桥接代币）都受到转移限制
        // 这种有缺陷的设计允许恶意行为者通过向合法用户发送少量桥接代币来扰乱他们

        //~ mitigation：Track Bridged Token Balances Instead of Booleans

        // Addresses that bridged tokens have some transfer restrictions
        if (!isBridgedTokenHolder[_to]) {
            isBridgedTokenHolder[_to] = true;
        }

        // In the case of NON-default OFT, the _amountLD MIGHT not be == amountReceivedLD.
        return _amountLD;
    }
}