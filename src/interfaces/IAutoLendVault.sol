// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAutoLendVault
/// @notice Interface for the AutoLend Vault contract
/// @dev Implements ERC4626-like interface for tokenized vault
interface IAutoLendVault {
    /// @notice Emitted when the vault is rebalanced between pools
    /// @param fromAToB True if rebalancing from pool A to B, false otherwise
    /// @param amount Amount moved between pools
    /// @param timestamp Block timestamp of rebalance
    event Rebalanced(bool indexed fromAToB, uint256 amount, uint256 timestamp);

    /// @notice Emitted when a user deposits assets
    /// @param user Address of the depositor
    /// @param assets Amount of assets deposited
    /// @param shares Amount of shares minted
    event Deposited(address indexed user, uint256 assets, uint256 shares);

    /// @notice Emitted when a user withdraws assets
    /// @param user Address of the withdrawer
    /// @param assets Amount of assets withdrawn
    /// @param shares Amount of shares burned
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);

    /// @notice Deposit assets into the vault
    /// @param assets Amount of assets to deposit
    /// @param receiver Address to receive the vault shares
    /// @return shares Amount of shares minted
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Withdraw assets from the vault
    /// @param shares Amount of shares to burn
    /// @param receiver Address to receive the assets
    /// @param owner Address that owns the shares
    /// @return assets Amount of assets withdrawn
    function withdraw(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    /// @notice Rebalance funds between pool A and pool B
    /// @param fromAToB True to move from A to B, false to move from B to A
    /// @dev Can only be called by authorized reactive contract
    function rebalance(bool fromAToB) external;

    /// @notice Get total assets under management
    /// @return Total assets in both pools
    function totalAssets() external view returns (uint256);

    /// @notice Get current allocation between pools
    /// @return balanceA Assets in pool A
    /// @return balanceB Assets in pool B
    function getCurrentAllocation() external view returns (uint256 balanceA, uint256 balanceB);

    /// @notice Convert assets to shares
    /// @param assets Amount of assets
    /// @return shares Equivalent amount of shares
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Convert shares to assets
    /// @param shares Amount of shares
    /// @return assets Equivalent amount of assets
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Get the asset token address
    /// @return Address of the underlying asset
    function asset() external view returns (address);

    /// @notice Get balance of shares for an address
    /// @param account Address to check
    /// @return Balance of vault shares
    function balanceOf(address account) external view returns (uint256);

    /// @notice Get total supply of vault shares
    /// @return Total shares in circulation
    function totalSupply() external view returns (uint256);
}
