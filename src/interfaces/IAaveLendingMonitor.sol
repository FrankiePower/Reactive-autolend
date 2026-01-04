// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAaveLendingMonitor
/// @notice Interface for the Reactive Aave Lending Monitor contract
interface IAaveLendingMonitor {
    /// @notice Emitted when a new rate is seen from a pool
    /// @param reserve Address of the reserve asset
    /// @param liquidityRate New liquidity rate
    /// @param blockNumber Block number when rate was seen
    event RateUpdated(address indexed reserve, uint256 liquidityRate, uint256 blockNumber);

    /// @notice Emitted when rebalancing is triggered
    /// @param fromAToB Direction of rebalancing
    /// @param rateA Rate of pool A
    /// @param rateB Rate of pool B
    /// @param delta Rate difference
    event RebalanceTriggered(bool fromAToB, uint256 rateA, uint256 rateB, uint256 delta);

    /// @notice Get the configuration of the monitor
    /// @return poolAddress Aave pool address
    /// @return reserveA Pool A reserve address
    /// @return reserveB Pool B reserve address
    /// @return vaultAddress Vault address to callback
    /// @return chainId Destination chain ID
    function getConfig()
        external
        view
        returns (
            address poolAddress,
            address reserveA,
            address reserveB,
            address vaultAddress,
            uint256 chainId
        );

    /// @notice Get current state of pool rates
    /// @return rateA Current rate of pool A
    /// @return rateB Current rate of pool B
    /// @return lastUpdateA Last update block for pool A
    /// @return lastUpdateB Last update block for pool B
    function getPoolStates()
        external
        view
        returns (uint256 rateA, uint256 rateB, uint256 lastUpdateA, uint256 lastUpdateB);

    /// @notice Get rebalancing parameters
    /// @return threshold Minimum rate difference to trigger rebalance (in basis points)
    /// @return cooldownPeriod Minimum blocks between rebalances
    /// @return lastRebalanceBlock Last block when rebalance occurred
    function getRebalanceParams()
        external
        view
        returns (uint256 threshold, uint256 cooldownPeriod, uint256 lastRebalanceBlock);
}
