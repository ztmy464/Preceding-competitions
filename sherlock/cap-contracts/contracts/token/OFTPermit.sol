// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.20;

import { OFTCore } from "@layerzerolabs/oft-evm/contracts/OFTCore.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title OFT Permit Contract
/// @author kexley, Cap Labs, LayerZero Labs
/// @notice OFT is an ERC-20 Permit token that extends the functionality of the OFTCore contract.
abstract contract OFTPermit is OFTCore, ERC20, ERC20Permit {
    /// @dev Constructor for the OFT contract
    /// @param _name The name of the OFT
    /// @param _symbol The symbol of the OFT
    /// @param _lzEndpoint The LayerZero endpoint address
    /// @param _delegate The delegate capable of making OApp configurations inside of the endpoint
    constructor(string memory _name, string memory _symbol, address _lzEndpoint, address _delegate)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        OFTCore(decimals(), _lzEndpoint, _delegate)
        Ownable(_delegate)
    { }

    /// @dev Retrieves the address of the underlying ERC20 implementation
    /// @return The address of the OFT token
    /// @dev In the case of OFT, address(this) and erc20 are the same contract
    function token() public view returns (address) {
        return address(this);
    }

    /// @notice Indicates whether the OFT contract requires approval of the 'token()' to send
    /// @return requiresApproval Needs approval of the underlying token implementation
    /// @dev In the case of OFT where the contract IS the token, approval is NOT required
    function approvalRequired() external pure virtual returns (bool) {
        return false;
    }

    /// @dev Burns tokens from the sender's specified balance
    /// @param _from The address to debit the tokens from
    /// @param _amountLD The amount of tokens to send in local decimals
    /// @param _minAmountLD The minimum amount to send in local decimals
    /// @param _dstEid The destination chain ID
    /// @return amountSentLD The amount sent in local decimals
    /// @return amountReceivedLD The amount received in local decimals on the remote
    function _debit(address _from, uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid)
        internal
        virtual
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        // @dev In NON-default OFT, amountSentLD could be 100, with a 10% fee, the amountReceivedLD amount is 90,
        // therefore amountSentLD CAN differ from amountReceivedLD.

        // @dev Default OFT burns on src.
        _burn(_from, amountSentLD);
    }

    /// @dev Credits tokens to the specified address
    /// @param _to The address to credit the tokens to
    /// @param _amountLD The amount of tokens to credit in local decimals
    /// @dev _srcEid The source chain ID
    /// @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals
    function _credit(address _to, uint256 _amountLD, uint32 /*_srcEid*/ )
        internal
        virtual
        override
        returns (uint256 amountReceivedLD)
    {
        if (_to == address(0x0)) _to = address(0xdead); // _mint(...) does not support address(0x0)
        // @dev Default OFT mints on dst.
        _mint(_to, _amountLD);
        // @dev In the case of NON-default OFT, the _amountLD MIGHT not be == amountReceivedLD.
        return _amountLD;
    }
}
