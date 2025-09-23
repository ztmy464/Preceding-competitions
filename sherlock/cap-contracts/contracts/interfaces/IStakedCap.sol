// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/// @title Staked Cap Token Interface
/// @author kexley, Cap Labs
/// @notice Interface for the staked cap token that distributes yield accrued from agents borrowing underlying assets
interface IStakedCap {
    /// @dev Storage for the staked cap token
    /// @param storedTotal Total amount of the token stored
    /// @param totalLocked Total amount of the token locked
    /// @param lastNotify Last notify timestamp
    /// @param lockDuration Lock duration
    struct StakedCapStorage {
        uint256 storedTotal;
        uint256 totalLocked;
        uint256 lastNotify;
        uint256 lockDuration;
    }

    /// @dev Emitted when the yield is notified
    event Notify(address indexed caller, uint256 amount);

    /// @dev Notify is not allowed when the yield is still vesting
    error StillVesting();

    /// @notice Initialize the staked cap token by matching the name and symbol of the underlying
    /// @param _accessControl Address of the access control
    /// @param _asset Address of the cap token
    /// @param _lockDuration Duration in seconds for profit locking
    function initialize(address _accessControl, address _asset, uint256 _lockDuration) external;

    /// @notice Notify the yield to start vesting
    function notify() external;

    /// @notice Remaining locked profit after a notification
    /// @return locked Amount remaining to be vested
    function lockedProfit() external view returns (uint256 locked);

    /// @notice Last notify timestamp
    /// @return lastNotify Last notify timestamp
    function lastNotify() external view returns (uint256 lastNotify);

    /// @notice Lock duration
    /// @return lockDuration Lock duration
    function lockDuration() external view returns (uint256 lockDuration);
}
