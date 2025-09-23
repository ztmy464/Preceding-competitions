// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/// @title Chainlink Interface
/// @author kexley, Cap Labs
/// @notice Interface for Chainlink price feeds
interface IChainlink {
    /// @notice Get the number of decimals of the price feed
    /// @return decimals Number of decimals of the price feed
    function decimals() external view returns (uint8);

    /// @notice Get the latest price of the price feed
    /// @return price Latest price of the price feed
    function latestAnswer() external view returns (int256);

    /// @notice Get the latest round data from the price feed
    /// @return roundId The round ID
    /// @return answer The price answer
    /// @return startedAt Timestamp when the round started
    /// @return updatedAt Timestamp when the round was updated
    /// @return answeredInRound The round ID in which the answer was computed
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}
