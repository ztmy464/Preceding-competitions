// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { Holding } from "./Holding.sol";
import { OperationsLib } from "./libraries/OperationsLib.sol";

import { IWETH } from "./interfaces/IWETH.sol";
import { IHolding } from "./interfaces/core/IHolding.sol";
import { IHoldingManager } from "./interfaces/core/IHoldingManager.sol";
import { IManager } from "./interfaces/core/IManager.sol";

import { ISharesRegistry } from "./interfaces/core/ISharesRegistry.sol";
import { IStablesManager } from "./interfaces/core/IStablesManager.sol";

/**
 * @title HoldingManager
 *
 * @notice Manages holding creation, management, and interaction for a more secure and dynamic flow.
 *
 * @dev This contract inherits functionalities from `Ownable2Step`, `Pausable`, and `ReentrancyGuard`.
 *
 * @author Hovooo (@hovooo), Cosmin Grigore (@gcosmintech).
 *
 * @custom:security-contact support@jigsaw.finance
 */
contract HoldingManager is IHoldingManager, Ownable2Step, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Returns holding address associated with the user.
     */
    mapping(address user => address holding) public override userHolding;

    /**
     * @notice Returns user address associated with the holding.
     */
    mapping(address holding => address user) public override holdingUser;

    /**
     * @notice Returns true if provided address is a holding within protocol.
     */
    mapping(address holding => bool exists) public override isHolding;

    /**
     * @notice Returns the address of the holding implementation to be cloned from.
     */
    address public immutable override holdingImplementationReference;

    /**
     * @notice Contract that contains all the necessary configs of the protocol.
     */
    IManager public immutable override manager;

    /**
     * @notice Returns the address of the WETH contract to save on `manager.WETH()` calls.
     */
    address public immutable override WETH;

    /**
     * @notice Creates a new HoldingManager Contract.
     * @param _initialOwner The initial owner of the contract
     * @param _manager Contract that holds all the necessary configs of the protocol.
     */
    constructor(address _initialOwner, address _manager) Ownable(_initialOwner) {
        require(_manager != address(0), "3065");
        manager = IManager(_manager);
        holdingImplementationReference = address(new Holding());
        WETH = manager.WETH();
    }
// @auidt-high
    // -- User specific methods --

    /**
     * @notice Creates holding for the msg.sender.
     *
     * @notice Requirements:
     * - `msg.sender` must not have a holding within the protocol, as only one holding is allowed per address.
     * - Must be called from an EOA or whitelisted contract.
     *
     * @notice Effects:
     * - Clones `holdingImplementationReference`.
     * - Updates `userHolding` and `holdingUser` mappings with newly deployed `newHoldingAddress`.
     * - Initiates the `newHolding`.
     *
     * @notice Emits:
     * - `HoldingCreated` event indicating successful Holding creation.
     *
     * @return The address of the new holding.
     */
    function createHolding() external override nonReentrant whenNotPaused returns (address) {
        require(userHolding[msg.sender] == address(0), "1101");

        if (msg.sender != tx.origin) {
            require(manager.isContractWhitelisted(msg.sender), "1000");
        }

        // Instead of deploying the contract, it is cloned to save on gas.
        address newHoldingAddress = Clones.clone(holdingImplementationReference);
        emit HoldingCreated({ user: msg.sender, holdingAddress: newHoldingAddress });

        isHolding[newHoldingAddress] = true;
        userHolding[msg.sender] = newHoldingAddress;
        holdingUser[newHoldingAddress] = msg.sender;

        Holding newHolding = Holding(newHoldingAddress);
        newHolding.init(address(manager));

        return newHoldingAddress;
    }

    /**
     * @notice Deposits a whitelisted token into the Holding.
     *
     * @notice Requirements:
     * - `_token` must be a whitelisted token.
     * - `_amount` must be greater than zero.
     * - `msg.sender` must have a valid holding.
     *
     * @param _token Token's address.
     * @param _amount Amount to deposit.
     */
    function deposit(
        address _token,
        uint256 _amount
    )
        external
        override
        validToken(_token)
        validAmount(_amount)
        validHolding(userHolding[msg.sender])
        nonReentrant
        whenNotPaused
    {
        _deposit({ _from: msg.sender, _token: _token, _amount: _amount });
    }

    /**
     * @notice Wraps native coin and deposits WETH into the holding.
     *
     * @dev This function must receive ETH in the transaction.
     *
     * @notice Requirements:
     *  - WETH must be whitelisted within protocol.
     * - `msg.sender` must have a valid holding.
     */
    function wrapAndDeposit()
        external
        payable
        override
        validToken(WETH)
        validHolding(userHolding[msg.sender])
        nonReentrant
        whenNotPaused
    {
        _wrap();
        _deposit({ _from: address(this), _token: WETH, _amount: msg.value });
    }

    /**
     * @notice Withdraws a token from a Holding to a user.
     *
     * @notice Requirements:
     * - `_token` must be a valid address.
     * - `_amount` must be greater than zero.
     * - `msg.sender` must have a valid holding.
     *
     * @notice Effects:
     * - Withdraws the `_amount` of `_token` from the holding.
     * - Transfers the `_amount` of `_token` to `msg.sender`.
     * - Deducts any applicable fees.
     *
     * @param _token Token user wants to withdraw.
     * @param _amount Withdrawal amount.
     */
    function withdraw(
        address _token,
        uint256 _amount
    )
        external
        override
        validAddress(_token)
        validAmount(_amount)
        validHolding(userHolding[msg.sender])
        nonReentrant
        whenNotPaused
    {
        IHolding holding = IHolding(userHolding[msg.sender]);
        (uint256 userAmount, uint256 feeAmount) = _withdraw({ _token: _token, _amount: _amount });

        // Transfer the fee amount to the fee address.
        if (feeAmount > 0) {
            holding.transfer({ _token: _token, _to: manager.feeAddress(), _amount: feeAmount });
        }

        // Transfer the remaining amount to the user.
        holding.transfer({ _token: _token, _to: msg.sender, _amount: userAmount });
    }

    /**
     * @notice Withdraws WETH from holding and unwraps it before sending it to the user.
     *
     * @notice Requirements:
     * - `_amount` must be greater than zero.
     * - `msg.sender` must have a valid holding.
     * - The low level native coin transfers must succeed.
     *
     * @notice Effects
     * - Transfers WETH from Holding address to address(this).
     * - Unwraps the WETH into native coin.
     * - Withdraws the `_amount` of WETH from the holding.
     * - Deducts any applicable fees.
     * - Transfers the unwrapped amount to `msg.sender`.
     *
     * @param _amount Withdrawal amount.
     */
    function withdrawAndUnwrap(
        uint256 _amount
    ) external override validAmount(_amount) validHolding(userHolding[msg.sender]) nonReentrant whenNotPaused {
        IHolding(userHolding[msg.sender]).transfer({ _token: WETH, _to: address(this), _amount: _amount });
        _unwrap(_amount);
        (uint256 userAmount, uint256 feeAmount) = _withdraw({ _token: WETH, _amount: _amount });

        if (feeAmount > 0) {
            (bool feeSuccess,) = payable(manager.feeAddress()).call{ value: feeAmount }("");
            require(feeSuccess, "3016");
        }

        (bool success,) = payable(msg.sender).call{ value: userAmount }("");
        require(success, "3016");
    }

    /**
     * @notice Borrows jUSD stablecoin to the user or to the holding contract.
     *
     * @dev The _amount does not account for the collateralization ratio and is meant to represent collateral's amount
     * equivalent to jUSD's value the user wants to receive.
     * @dev Ensure that the user will not become insolvent after borrowing before calling this function, as this
     * function will revert ("3009") if the supplied `_amount` does not adhere to the collateralization ratio set in
     * the registry for the specific collateral.
     *
     * @notice Requirements:
     * - `msg.sender` must have a valid holding.
     *
     * @notice Effects:
     * - Calls borrow function on `Stables Manager` Contract resulting in minting stablecoin based on the `_amount` of
     * `_token` collateral.
     *
     * @notice Emits:
     * - `Borrowed` event indicating successful borrow operation.
     *
     * @param _token Collateral token.
     * @param _amount The collateral amount equivalent for borrowed jUSD.
     * @param _mintDirectlyToUser If true, mints to user instead of holding.
     * @param _minJUsdAmountOut The minimum amount of jUSD that is expected to be received.
     *
     * @return jUsdMinted The amount of jUSD minted.
     */
    function borrow(
        address _token,
        uint256 _amount,
        uint256 _minJUsdAmountOut,
        bool _mintDirectlyToUser
    ) external override nonReentrant whenNotPaused validHolding(userHolding[msg.sender]) returns (uint256 jUsdMinted) {
        address holding = userHolding[msg.sender];

        jUsdMinted = _getStablesManager().borrow({
            _holding: holding,
            _token: _token,
            _amount: _amount,
            _minJUsdAmountOut: _minJUsdAmountOut,
            _mintDirectlyToUser: _mintDirectlyToUser
        });

        emit Borrowed({ holding: holding, token: _token, jUsdMinted: jUsdMinted, mintToUser: _mintDirectlyToUser });
    }

    /**
     * @notice Borrows jUSD stablecoin to the user or to the holding contract using multiple collaterals.
     *
     * @dev This function will fail if any `amount` supplied in the `_data` does not adhere to the collateralization
     * ratio set in the registry for the specific collateral. For instance, if the collateralization ratio is 200%, the
     * maximum `_amount` that can be used to borrow is half of the user's free collateral, otherwise the user's holding
     * will become insolvent after borrowing.
     *
     * @notice Requirements:
     * - `msg.sender` must have a valid holding.
     * - `_data` must contain at least one entry.
     *
     * @notice Effects:
     * - Mints jUSD stablecoin for each entry in `_data` based on the collateral amounts.
     *
     * @notice Emits:
     * - `Borrowed` event for each entry indicating successful borrow operation.
     * - `BorrowedMultiple` event indicating successful multiple borrow operation.
     *
     * @param _data Struct containing data for each collateral type.
     * @param _mintDirectlyToUser If true, mints to user instead of holding.
     *
     * @return  The amount of jUSD minted for each collateral type.
     */
    function borrowMultiple(
        BorrowData[] calldata _data,
        bool _mintDirectlyToUser
    ) external override validHolding(userHolding[msg.sender]) nonReentrant whenNotPaused returns (uint256[] memory) {
        require(_data.length > 0, "3006");

        address holding = userHolding[msg.sender];

        uint256[] memory jUsdMintedAmounts = new uint256[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            uint256 jUsdMinted = _getStablesManager().borrow({
                _holding: holding,
                _token: _data[i].token,
                _amount: _data[i].amount,
                _minJUsdAmountOut: _data[i].minJUsdAmountOut,
                _mintDirectlyToUser: _mintDirectlyToUser
            });

            emit Borrowed({
                holding: holding,
                token: _data[i].token,
                jUsdMinted: jUsdMinted,
                mintToUser: _mintDirectlyToUser
            });

            jUsdMintedAmounts[i] = jUsdMinted;
        }

        emit BorrowedMultiple({ holding: holding, length: _data.length, mintedToUser: _mintDirectlyToUser });
        return jUsdMintedAmounts;
    }

    /**
     * @notice Repays jUSD stablecoin debt from the user's or to the holding's address and frees up the locked
     * collateral.
     *
     * @notice Requirements:
     * - `msg.sender` must have a valid holding.
     *
     * @notice Effects:
     * - Repays `_amount` jUSD stablecoin.
     *
     * @notice Emits:
     * - `Repaid` event indicating successful debt repayment operation.
     *
     * @param _token Collateral token.
     * @param _amount The repaid amount.
     * @param _repayFromUser If true, Stables Manager will burn jUSD from the msg.sender, otherwise user's holding.
     */
    function repay(
        address _token,
        uint256 _amount,
        bool _repayFromUser
    ) external override nonReentrant whenNotPaused validHolding(userHolding[msg.sender]) {
        address holding = userHolding[msg.sender];

        emit Repaid({ holding: holding, token: _token, amount: _amount, repayFromUser: _repayFromUser });
        _getStablesManager().repay({
            _holding: holding,
            _token: _token,
            _amount: _amount,
            _burnFrom: _repayFromUser ? msg.sender : holding
        });
    }

    /**
     * @notice Repays multiple jUSD stablecoin debts from the user's or to the holding's address and frees up the locked
     * collateral assets.
     *
     * @notice Requirements:
     * - `msg.sender` must have a valid holding.
     * - `_data` must contain at least one entry.
     *
     * @notice Effects:
     * - Repays stablecoin for each entry in `_data.
     *
     * @notice Emits:
     * - `Repaid` event indicating successful debt repayment operation.
     * - `RepaidMultiple` event indicating successful multiple repayment operation.
     *
     * @param _data Struct containing data for each collateral type.
     * @param _repayFromUser If true, it will burn from user's wallet, otherwise from user's holding.
     */
    function repayMultiple(
        RepayData[] calldata _data,
        bool _repayFromUser
    ) external override validHolding(userHolding[msg.sender]) nonReentrant whenNotPaused {
        require(_data.length > 0, "3006");

        address holding = userHolding[msg.sender];
        for (uint256 i = 0; i < _data.length; i++) {
            emit Repaid({
                holding: holding,
                token: _data[i].token,
                amount: _data[i].amount,
                repayFromUser: _repayFromUser
            });
            _getStablesManager().repay({
                _holding: holding,
                _token: _data[i].token,
                _amount: _data[i].amount,
                _burnFrom: _repayFromUser ? msg.sender : holding
            });
        }

        emit RepaidMultiple({ holding: holding, length: _data.length, repaidFromUser: _repayFromUser });
    }

    /**
     * @notice Allows the contract to accept incoming Ether transfers.
     * @dev This function is executed when the contract receives Ether with no data in the transaction.
     * @dev Only allows transfers from the WETH contract.
     *
     * @notice Emits:
     * - `Received` event to log the sender's address and the amount received.
     */
    receive() external payable {
        require(msg.sender == WETH, "1000");
        emit Received({ from: msg.sender, amount: msg.value });
    }

    // -- Administration --

    /**
     * @notice Triggers stopped state.
     */
    function pause() external override onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     */
    function unpause() external override onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Renounce ownership override to avoid losing contract's ownership.
     */
    function renounceOwnership() public pure override {
        revert("1000");
    }

    // -- Private methods --

    /**
     * @notice Returns the stables manager contract.
     * @return The IStablesManager instance.
     */
    function _getStablesManager() private view returns (IStablesManager) {
        return IStablesManager(manager.stablesManager());
    }

    /**
     * @notice Wraps native coin.
     *
     * @notice Requirements:
     * - The transaction must include ETH.
     * - The amount of ETH sent must be greater than zero.
     *
     * @notice Effects:
     * - Converts the sent ETH to WETH.
     *
     * @notice Emits:
     * - `NativeCoinWrapped` event indicating successful native coin's wrapping.
     */
    function _wrap() private {
        require(msg.value > 0, "2001");
        emit NativeCoinWrapped({ user: msg.sender, amount: msg.value });
        IWETH(WETH).deposit{ value: msg.value }();
    }

    /**
     * @notice Unwraps WETH.
     *
     * @notice Requirements:
     * - The contract must have enough WETH to unwrap the specified amount.
     *
     * @notice Effects:
     * - Converts the specified amount of WETH to ETH.
     *
     * @notice Emits:
     * - `NativeCoinUnwrapped` event indicating successful WETH's  unwrapping.
     *
     * @param _amount The amount of WETH to unwrap.
     */
    function _unwrap(
        uint256 _amount
    ) private {
        emit NativeCoinUnwrapped({ user: msg.sender, amount: _amount });
        IWETH(WETH).withdraw(_amount);
    }

    //~ @audit-medium CCC Holding owners can hide portion of their collateral from bad debt liquidation
    // ~ CCC user via customized call flow passby normal interaction process
    /* 
    donates 0.1 WETH directly to holding and invests into strategy2 directly using StrategyManager.instead of use holdingmanger.depoist.
    strategies pull these funds simply from holding contract without caring for the accounted value of collateral[holding].
    */

    //~ mitigation: modify the _amount of _retrieveCollateral 
    //~ from  ISharesRegistry(registryAddress).collateral(holding)  to  type(uint256).max 
    /**
     * @notice Deposits a specified amount of a token into the holding.
     *
     * @notice Requirements:
     * - `_from` must have approved the contract to spend `_amount` of `_token`.
     *
     * @notice Effects:
     * - Transfers `_amount` of `_token` from `_from` to the holding.
     * - Adds `_amount` of `_token` to the collateral in the Stables Manager Contract.
     *
     * @notice Emits:
     * - `Deposit` event indicating successful deposit operation.
     *
     * @param _from The address from which the token is transferred.
     * @param _token The token address.
     * @param _amount The amount to deposit.
     */
    function _deposit(address _from, address _token, uint256 _amount) private {
        address holding = userHolding[msg.sender];

        emit Deposit(holding, _token, _amount);
        if (_from == address(this)) {
            IERC20(_token).safeTransfer({ to: holding, value: _amount });
        } else {
            IERC20(_token).safeTransferFrom({ from: _from, to: holding, value: _amount });
        }

        _getStablesManager().addCollateral({ _holding: holding, _token: _token, _amount: _amount });
    }

    //~ @audit-medium Withdrawals of rewards earned through strategies should not be charged with withdrawal fees (Unreasonable charges)
    /* 
    rewards has been taken performanceFee, the withdraw() function again charges a withdrawal fee on these rewards as well.
     
    the withdrawal fee is supposed to be for users exiting the
    system by taking out the collateral, while the rewards earned should be solely belonging to the holding
    owner, as the protocol has already taken upto a massive 25 % cut.
     */
    /**
     * @notice Withdraws a specified amount of a token from the holding.
     *
     * @notice Requirements:
     * - The `_token` must be withdrawable.
     * -The holding must remain solvent after withdrawal if the `_token` is used as a collateral.
     *
     * @notice Effects:
     * - Removes `_amount` of `_token` from the collateral in the Stables Manager Contract if the `_token` is used as a
     * collateral.
     * - Calculates any applicable withdrawal fee.
     * @notice Emits:
     * - `Withdrawal` event indicating successful withdrawal operation.
     *
     * @param _token The token address.
     * @param _amount The amount to withdraw.
     *
     * @return The available amount to be withdrawn and the withdrawal fee amount.
     */
    function _withdraw(address _token, uint256 _amount) private returns (uint256, uint256) {
        require(manager.isTokenWithdrawable(_token), "3071");
        address holding = userHolding[msg.sender];
        //~ airdropped token or collateral
        // Perform the check to see if this is an airdropped token or user actually has collateral for it
        (, address _tokenRegistry) = _getStablesManager().shareRegistryInfo(_token);
        //~ if is collateral token,update collateral records
        if (_tokenRegistry != address(0) && ISharesRegistry(_tokenRegistry).collateral(holding) > 0) {
            _getStablesManager().removeCollateral({ _holding: holding, _token: _token, _amount: _amount });
        }
        uint256 withdrawalFee = manager.withdrawalFee();
        uint256 withdrawalFeeAmount = 0;
        if (withdrawalFee > 0) withdrawalFeeAmount = OperationsLib.getFeeAbsolute(_amount, withdrawalFee);
        emit Withdrawal({ holding: holding, token: _token, totalAmount: _amount, feeAmount: withdrawalFeeAmount });

        return (_amount - withdrawalFeeAmount, withdrawalFeeAmount);
    }

    // -- Modifiers --

    /**
     * @notice Validates that the address is not zero.
     * @param _address The address to validate.
     */
    modifier validAddress(
        address _address
    ) {
        require(_address != address(0), "3000");
        _;
    }

    /**
     * @notice Validates that the holding exists.
     * @param _holding The address of the holding.
     */
    modifier validHolding(
        address _holding
    ) {
        require(isHolding[_holding], "3002");
        _;
    }

    /**
     * @notice Validates that the amount is greater than zero.
     * @param _amount The amount to validate.
     */
    modifier validAmount(
        uint256 _amount
    ) {
        require(_amount > 0, "2001");
        _;
    }

    /**
     * @notice Validates that the token is whitelisted.
     * @param _token The address of the token.
     */
    modifier validToken(
        address _token
    ) {
        require(manager.isTokenWhitelisted(_token), "3001");
        _;
    }
}
