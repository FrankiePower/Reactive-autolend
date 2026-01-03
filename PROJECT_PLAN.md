# Reactive Auto-Lend Vault - Project Plan

## Project Overview

A cross-chain lending automation vault using Reactive Smart Contracts that automatically rebalances liquidity between two lending pools based on yield signals.

**Deadline:** December 28, 11:59 PM UTC (extended by one week)

---

## Core Requirements

1. **Integrate with at least two lending pools** (e.g., Pool A and Pool B)
   - Pools must expose deposit/withdraw functionality
   - Pools must provide rate information on-chain

2. **Use Reactive Smart Contracts to:**
   - Listen to on-chain events or periodically check state
   - Monitor supply/borrow rates, utilization, or yield proxy
   - Trigger rebalancing transactions when conditions are met
   - Move funds from Pool A → B or B → A based on yield difference

3. **Provide a single vault interface for users:**
   - Users deposit into the vault once
   - Vault allocates and reallocates funds automatically
   - Users can withdraw their share at any time

---

## Architecture

### Smart Contracts

#### 1. AutoLendVault.sol (Main Vault Contract)
**Purpose:** User-facing contract for deposits and fund management

**Key Features:**
- Accept user deposits in a single token (e.g., USDC, DAI)
- Implement share-based accounting (ERC4626-like)
- Allocate funds between Pool A and Pool B
- Handle user withdrawals proportionally
- Execute rebalancing operations

**Core Functions:**
```solidity
deposit(uint256 amount) → uint256 shares
withdraw(uint256 shares) → uint256 amount
balanceOf(address user) → uint256 shares
totalAssets() → uint256 total
currentAllocation() → (uint256 poolA, uint256 poolB)
rebalance(uint256 amountToMove, bool fromAtoB)
```

#### 2. ReactiveLendingMonitor.sol (Reactive Contract)
**Purpose:** Monitor pool yields and trigger rebalancing

**Key Features:**
- Subscribe to lending pool events (rate updates, utilization changes)
- Periodically check pool states
- Compare yields between Pool A and Pool B
- Calculate when rebalancing threshold is exceeded
- Trigger vault rebalancing via callback/transaction

**Core Logic:**
```solidity
// Monitor pool rates
checkRates() → (uint256 rateA, uint256 rateB)
calculateYieldDelta() → uint256 delta
shouldRebalance() → bool

// Reactive callbacks
onPoolRateUpdate(address pool, uint256 newRate)
triggerRebalance(uint256 amount, bool direction)
```

**Configuration:**
- Rebalancing threshold (e.g., 0.5% yield difference)
- Minimum rebalance amount
- Cooldown period between rebalances
- Emergency pause mechanism

#### 3. ILendingPool.sol (Lending Pool Interface)
**Purpose:** Abstract interface for interacting with different lending protocols

**Standard Methods:**
```solidity
deposit(address asset, uint256 amount)
withdraw(address asset, uint256 amount)
getSupplyRate(address asset) → uint256 rate
getUtilization(address asset) → uint256 utilization
balanceOf(address user) → uint256 balance
```

#### 4. Pool Adapters
**Purpose:** Implement specific integrations for different protocols

**AaveAdapter.sol:**
- Integrates with Aave V3 on Sepolia
- Wraps Aave's lending pool methods
- Handles aToken conversions

**CompoundAdapter.sol:**
- Integrates with Compound-like protocols
- Wraps cToken operations
- Handles interest-bearing token logic

**MockLendingPool.sol:**
- Test implementation for local development
- Configurable rates and behavior
- Simulates real pool dynamics

---

## Project Structure

```
Reactive-autolend/
├── contracts/
│   ├── AutoLendVault.sol              # Main vault contract
│   ├── ReactiveLendingMonitor.sol     # Reactive monitoring contract
│   ├── interfaces/
│   │   ├── ILendingPool.sol           # Lending pool interface
│   │   ├── IReactive.sol              # Reactive network interface
│   │   ├── IAutoLendVault.sol         # Vault interface
│   │   └── ILendingPoolAdapter.sol    # Adapter interface
│   ├── adapters/
│   │   ├── AaveAdapter.sol            # Aave V3 integration
│   │   ├── CompoundAdapter.sol        # Compound integration
│   │   └── MockLendingPool.sol        # Test pool implementation
│   └── libraries/
│       ├── ShareMath.sol              # Share calculation utilities
│       └── YieldCalculator.sol        # Yield comparison logic
├── scripts/
│   ├── deploy.ts                      # Main deployment script
│   ├── setup.ts                       # Configure reactive subscriptions
│   ├── test-deposit.ts                # Test user deposits
│   └── test-rebalance.ts              # Test rebalancing
├── test/
│   ├── AutoLendVault.test.ts          # Vault unit tests
│   ├── ReactiveLendingMonitor.test.ts # Reactive logic tests
│   ├── integration.test.ts            # End-to-end tests
│   └── helpers/
│       └── fixtures.ts                # Test fixtures
├── hardhat.config.ts                  # Hardhat configuration
├── package.json                       # Dependencies
├── tsconfig.json                      # TypeScript config
├── .env.example                       # Environment variables template
└── README.md                          # Project readme
```

---

## Implementation Strategy

### Phase 1: Project Setup
**Tasks:**
- [ ] Initialize Hardhat project with TypeScript
- [ ] Install dependencies:
  - `@openzeppelin/contracts`
  - `@reactive-network/sdk`
  - `hardhat`, `ethers`, `chai`
- [ ] Configure networks:
  - Ethereum Sepolia testnet
  - Reactive Network testnet
- [ ] Set up environment variables

### Phase 2: Core Vault Implementation
**Tasks:**
- [ ] Implement `AutoLendVault.sol`:
  - Share-based accounting system
  - Deposit/withdrawal functions
  - Fund allocation tracking
  - Access control (owner, operators)
- [ ] Implement `ILendingPool.sol` interface
- [ ] Create mock lending pools for testing
- [ ] Write unit tests for vault operations

### Phase 3: Lending Pool Integration
**Tasks:**
- [ ] Implement `AaveAdapter.sol` for Aave V3
- [ ] Implement alternative pool adapter (Compound or custom)
- [ ] Add pool registry/management system
- [ ] Test deposit/withdraw to actual pools
- [ ] Verify rate fetching mechanisms

### Phase 4: Reactive Monitoring
**Tasks:**
- [ ] Implement `ReactiveLendingMonitor.sol`:
  - Event subscription logic
  - Rate comparison algorithm
  - Rebalancing trigger conditions
- [ ] Set up reactive callbacks to vault
- [ ] Implement configurable parameters:
  - Yield threshold
  - Cooldown period
  - Min rebalance amount
- [ ] Add emergency pause/unpause

### Phase 5: Rebalancing Logic
**Tasks:**
- [ ] Implement rebalancing function in vault:
  - Withdraw from lower-yield pool
  - Deposit to higher-yield pool
  - Handle slippage and gas costs
- [ ] Add safety checks:
  - Minimum profitability threshold
  - Maximum slippage tolerance
  - Reentrancy protection
- [ ] Optimize gas usage
- [ ] Test rebalancing scenarios

### Phase 6: Testing & Integration
**Tasks:**
- [ ] Write comprehensive unit tests
- [ ] Create integration tests with mock pools
- [ ] Test reactive triggers and callbacks
- [ ] Perform gas optimization
- [ ] Security review and audit checklist
- [ ] Test on Sepolia testnet with real pools

### Phase 7: Deployment
**Tasks:**
- [ ] Deploy vault contract to Sepolia
- [ ] Deploy reactive monitor to Reactive Network
- [ ] Configure pool adapters and addresses
- [ ] Set up reactive subscriptions
- [ ] Verify all contracts on explorers
- [ ] Test end-to-end flow with small amounts

---

## Technical Design Decisions

### 1. Lending Protocols
**Options:**
- **Aave V3** on Sepolia (recommended - well documented, widely used)
- **Compound V3** (if available on Sepolia)
- **Custom mock pools** (for testing and demonstration)

**Decision:** Use Aave V3 as primary + one custom mock pool

### 2. Rebalancing Threshold
**Recommendation:** 0.5% - 1.0% yield difference
- Prevents excessive rebalancing
- Accounts for gas costs
- Balances responsiveness vs efficiency

### 3. Token Choice
**Options:**
- **USDC** (most liquid, widely supported)
- **DAI** (decentralized, good test coverage)
- **USDT** (high TVL but may have limitations)

**Decision:** USDC for production, DAI for testing

### 4. Cooldown Period
**Recommendation:** 1-24 hours between rebalances
- Prevents spam and gas waste
- Allows yields to stabilize
- Configurable based on market conditions

### 5. Share Calculation
**Standard:** ERC4626 Tokenized Vault Standard
- Industry standard for vaults
- Handles share/asset conversions
- Well-tested and audited patterns

### 6. Security Considerations
- Reentrancy guards on all external calls
- Access control for admin functions
- Emergency pause mechanism
- Slippage protection on withdrawals
- Rate limiting on rebalances
- Input validation on all user inputs

---

## Reactive Network Integration

### Event Monitoring
**Subscribe to:**
- `ReserveDataUpdated` events from Aave
- Custom rate update events from pools
- Utilization change events

### State Queries
**Periodic checks for:**
- Current supply rates
- Pool utilization ratios
- Available liquidity

### Trigger Conditions
```solidity
bool shouldRebalance = (
    yieldDelta > threshold &&
    timeSinceLastRebalance > cooldown &&
    potentialProfit > minRebalanceAmount
);
```

### Callback Execution
1. Reactive contract detects condition
2. Calls `vault.rebalance(amount, direction)`
3. Vault validates caller is authorized reactive contract
4. Executes rebalancing transaction
5. Emits `Rebalanced` event

---

## Testing Strategy

### Unit Tests
- Vault deposit/withdrawal math
- Share calculation accuracy
- Pool adapter integrations
- Yield comparison logic
- Access control mechanisms

### Integration Tests
- Full deposit → allocation → rebalance → withdraw flow
- Multiple users with concurrent deposits
- Reactive trigger simulation
- Emergency pause scenarios
- Edge cases (zero balances, max withdrawals)

### Testnet Tests
- Deploy to Sepolia
- Real pool interactions
- Reactive callback verification
- Gas cost analysis
- Multi-block scenarios

---

## Success Criteria

### Minimum Viable Product
- ✅ Users can deposit funds
- ✅ Vault allocates to two pools
- ✅ Reactive contract monitors yields
- ✅ Automatic rebalancing when threshold met
- ✅ Users can withdraw with correct shares

### Nice to Have
- Multiple token support
- More than two pools
- Advanced yield optimization strategies
- Frontend interface
- Detailed analytics and reporting

---

## Timeline Estimate

Given the December 28 deadline, here's a suggested breakdown:

- **Phase 1-2:** Project setup + core vault (2-3 days)
- **Phase 3:** Pool integration (2 days)
- **Phase 4:** Reactive monitoring (2 days)
- **Phase 5:** Rebalancing logic (1-2 days)
- **Phase 6:** Testing (2-3 days)
- **Phase 7:** Deployment & verification (1 day)

**Total:** ~10-13 days of focused development

---

## Resources & References

### Reactive Network
- [Reactive Network Documentation](https://reactive.network/docs)
- Reactive SDK Examples
- Event Subscription Patterns

### Lending Protocols
- [Aave V3 Docs](https://docs.aave.com/developers/)
- [Compound V3 Docs](https://docs.compound.finance/)
- ERC4626 Tokenized Vault Standard

### Development Tools
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Ethers.js v6](https://docs.ethers.org/v6/)

---

## Risk Considerations

### Technical Risks
- Reactive network reliability
- Pool liquidity constraints
- Gas cost exceeding yield gains
- Smart contract vulnerabilities

### Mitigation Strategies
- Implement comprehensive testing
- Add emergency pause mechanisms
- Set minimum profitability thresholds
- Follow security best practices
- Consider audit before mainnet

---

## Future Enhancements

- Multi-chain support (Polygon, Arbitrum, etc.)
- Advanced yield strategies (flash loans, leverage)
- Governance token for vault parameters
- Performance fee mechanism
- Auto-compounding of yields
- Integration with more DeFi protocols
- Machine learning for yield prediction
