// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAavePool
/// @notice Interface for Aave V3 Pool contract
/// @dev Minimal interface with only the functions we need for AutoLend
interface IAavePool {
    /// @notice Supplies an `amount` of underlying asset into the reserve
    /// @param asset The address of the underlying asset to supply
    /// @param amount The amount to be supplied
    /// @param onBehalfOf The address that will receive the aTokens
    /// @param referralCode Code used to register the integrator originating the operation
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /// @notice Withdraws an `amount` of underlying asset from the reserve
    /// @param asset The address of the underlying asset to withdraw
    /// @param amount The underlying amount to be withdrawn
    /// @param to The address that will receive the underlying
    /// @return The final amount withdrawn
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /// @notice Returns the normalized income of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The reserve's normalized income (liquidity index)
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /// @notice Returns the state and configuration of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return Configuration data struct
    function getReserveData(address asset) external view returns (ReserveData memory);

    /// @notice Emitted on supply
    /// @param reserve The address of the underlying asset of the reserve
    /// @param user The address initiating the supply
    /// @param onBehalfOf The beneficiary of the supply
    /// @param amount The amount supplied
    /// @param referralCode The referral code used
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /// @notice Emitted when reserve data is updated
    /// @param reserve The address of the underlying asset of the reserve
    /// @param liquidityRate The next liquidity rate (supply APY)
    /// @param stableBorrowRate The next stable borrow rate
    /// @param variableBorrowRate The next variable borrow rate
    /// @param liquidityIndex The next liquidity index
    /// @param variableBorrowIndex The next variable borrow index
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    struct ReserveData {
        // Reserve configuration
        uint256 configuration;
        // Liquidity index (normalized income)
        uint128 liquidityIndex;
        // Current supply rate
        uint128 currentLiquidityRate;
        // Variable borrow index
        uint128 variableBorrowIndex;
        // Current variable borrow rate
        uint128 currentVariableBorrowRate;
        // Current stable borrow rate
        uint128 currentStableBorrowRate;
        // Timestamp of last update
        uint40 lastUpdateTimestamp;
        // Id of the reserve
        uint16 id;
        // aToken address
        address aTokenAddress;
        // stableDebtToken address
        address stableDebtTokenAddress;
        // variableDebtToken address
        address variableDebtTokenAddress;
        // Interest rate strategy address
        address interestRateStrategyAddress;
        // Current treasury balance
        uint128 accruedToTreasury;
        // Outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        // Outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }
}
