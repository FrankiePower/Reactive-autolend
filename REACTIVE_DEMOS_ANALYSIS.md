# Reactive Smart Contract Demos - Analysis for AutoLend Project

## Overview

This document analyzes the Reactive Network demo projects to identify the most relevant patterns and implementations for building the AutoLend vault system.

---

## Demo Projects Summary

### 1. Basic Demo ⭐⭐⭐⭐⭐
**Path:** `src/demos/basic/`

**What it does:**
- Demonstrates fundamental reactive contract patterns
- Origin contract emits events when receiving Ether
- Reactive contract listens to events and triggers callbacks when threshold is met (≥0.01 ETH)
- Destination contract receives and processes callbacks

**Key Concepts:**
- Event subscription using `service.subscribe()`
- Event filtering in `react()` function
- Callback emission to destination chain
- Three-contract architecture: Origin → Reactive → Destination

**Relevance to AutoLend:** ⭐⭐⭐⭐⭐
- **Essential foundation** - teaches core reactive patterns we'll use
- Shows how to subscribe to on-chain events
- Demonstrates callback mechanism for triggering actions
- Simple, clear implementation to learn from

**Key Takeaways:**
```solidity
// Subscribe to events in constructor
service.subscribe(
    chainId,
    contractAddress,
    topic_0,  // Event signature
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);

// React to events
function react(LogRecord calldata log) external vmOnly {
    // Check conditions
    if (condition) {
        // Emit callback to trigger action
        bytes memory payload = abi.encodeWithSignature("callback(address)", param);
        emit Callback(destinationChainId, callbackContract, GAS_LIMIT, payload);
    }
}
```

---

### 2. Uniswap V2 Stop Order Demo ⭐⭐⭐⭐⭐
**Path:** `src/demos/uniswap-v2-stop-order/`

**What it does:**
- Monitors Uniswap V2 pair `Sync` events for exchange rate changes
- Automatically executes token swaps when rate crosses threshold
- Tracks order execution and completion states
- Implements stateful reactive logic with `triggered` and `done` flags

**Key Concepts:**
- Monitoring DeFi protocol events (Uniswap Sync)
- Multi-event subscription (pair events + stop order events)
- Threshold-based triggering logic
- State management in reactive contracts
- Exchange rate calculations from reserves

**Relevance to AutoLend:** ⭐⭐⭐⭐⭐
- **MOST RELEVANT DEMO** - directly analogous to our use case
- Monitors DeFi protocol state (pools)
- Compares values and triggers actions based on thresholds
- Implements automated rebalancing logic
- Shows how to track execution state

**Key Patterns for AutoLend:**
```solidity
// State tracking
bool private triggered;
bool private done;

// Threshold comparison
function below_threshold(Reserves memory sync) internal view returns (bool) {
    if (token0) {
        return (sync.reserve1 * coefficient) / sync.reserve0 <= threshold;
    } else {
        return (sync.reserve0 * coefficient) / sync.reserve1 <= threshold;
    }
}

// Multi-event handling
function react(LogRecord calldata log) external vmOnly {
    if (log._contract == stopOrderContract) {
        // Handle completion event
        if (triggered && log.topic_0 == STOP_ORDER_STOP_TOPIC_0) {
            done = true;
        }
    } else {
        // Handle pool sync event
        Reserves memory sync = abi.decode(log.data, (Reserves));
        if (below_threshold(sync) && !triggered) {
            // Trigger rebalancing
            triggered = true;
            emit Callback(...);
        }
    }
}
```

---

### 3. Cron Demo ⭐⭐⭐⭐
**Path:** `src/demos/cron/`

**What it does:**
- Subscribes to periodic CRON events from Reactive Network
- Executes automated logic at fixed block intervals
- Extends `AbstractPausableReactive` for pause/resume support

**Key Concepts:**
- Time-based automation
- CRON event subscription
- Pausable reactive contracts
- Internal callback testing

**Relevance to AutoLend:** ⭐⭐⭐⭐
- **Important for periodic checks** - alternative to event-driven approach
- Can periodically check pool rates instead of waiting for events
- Pause/resume functionality useful for maintenance
- Provides fallback if rate update events are unreliable

**Key Patterns:**
```solidity
contract BasicCronContract is AbstractPausableReactive {
    // Subscribe to CRON events
    service.subscribe(
        block.chainid,
        address(service),
        cronTopic,
        REACTIVE_IGNORE,
        REACTIVE_IGNORE,
        REACTIVE_IGNORE
    );

    // React to periodic events
    function react(LogRecord calldata log) external vmOnly {
        if (log.topic_0 == CRON_TOPIC) {
            // Execute periodic logic
            emit Callback(...);
        }
    }

    // Support pause/resume
    function getPausableSubscriptions() internal view override returns (Subscription[] memory) {
        // Define subscriptions that can be paused
    }
}
```

---

### 4. ERC-20 Turnovers Demo ⭐⭐⭐
**Path:** `src/demos/erc20-turnovers/`

**What it does:**
- Tracks all ERC-20 token transfers across contracts
- Accumulates turnover data in reactive contract state
- Responds to data requests with accumulated information
- Demonstrates request-response pattern

**Key Concepts:**
- Monitoring generic ERC-20 `Transfer` events
- State persistence and accumulation
- Request-response callback pattern
- Multi-origin event tracking

**Relevance to AutoLend:** ⭐⭐⭐
- Shows how to track token movements
- State management for accumulated data
- Request-response pattern could be useful for vault queries
- Less directly applicable than stop order demo

---

### 5. ERC-721 Ownership Demo ⭐⭐
**Path:** `src/demos/erc721-ownership/`

**What it does:**
- Tracks ERC-721 token ownership changes
- Maintains ownership history
- Provides ownership data on request

**Key Concepts:**
- NFT transfer monitoring
- Historical data tracking
- Cross-chain ownership synchronization

**Relevance to AutoLend:** ⭐⭐
- Limited relevance (we're working with ERC-20/lending)
- Shows historical tracking patterns
- Could inspire audit trail functionality

---

### 6. Uniswap V2 History Demo ⭐⭐⭐
**Path:** `src/demos/uniswap-v2-history/`

**What it does:**
- Records historical exchange rates from Uniswap pairs
- Stores reserve snapshots over time
- Allows historical data retrieval by block number

**Key Concepts:**
- Historical data storage in reactive contracts
- Sync event monitoring
- Time-series data management

**Relevance to AutoLend:** ⭐⭐⭐
- Shows how to track pool state over time
- Could be useful for yield trending/analytics
- Demonstrates data structure for time-series storage
- Less critical than real-time monitoring for MVP

---

### 7. Approval Magic Demo ⭐⭐
**Path:** `src/demos/approval-magic/`

**What it does:**
- Implements subscription-based token approval service
- Automatically executes swaps or exchanges when tokens are approved
- Manages subscriber gas costs
- Complex multi-contract interaction flow

**Key Concepts:**
- Subscription service model
- Gas cost management
- Approval-triggered automation
- Service-subscriber architecture

**Relevance to AutoLend:** ⭐⭐
- Interesting pattern but overly complex for our needs
- Subscription model not directly applicable
- Gas management ideas could be useful
- Focus on simpler patterns first

---

## Recommended Demos to Study (Priority Order)

### 🥇 Priority 1: Uniswap V2 Stop Order Demo
**Why:**
- Most similar to AutoLend architecture
- Shows DeFi protocol monitoring
- Demonstrates threshold-based triggering
- Implements automated rebalancing logic
- State management patterns

**What to Learn:**
- How to monitor lending pool events (similar to Sync events)
- Threshold comparison logic for yield deltas
- State tracking (triggered, completed)
- Multi-event subscription patterns
- Callback payload construction for rebalancing

### 🥈 Priority 2: Basic Demo
**Why:**
- Foundation for all reactive patterns
- Clean, simple implementation
- Essential concepts clearly demonstrated

**What to Learn:**
- Event subscription setup
- Basic `react()` function structure
- Callback emission
- Three-contract architecture

### 🥉 Priority 3: Cron Demo
**Why:**
- Alternative to pure event-driven approach
- Useful for periodic rate checks
- Pause/resume functionality

**What to Learn:**
- Periodic execution patterns
- `AbstractPausableReactive` usage
- Fallback strategies for monitoring

### Priority 4: ERC-20 Turnovers Demo
**Why:**
- Token tracking patterns
- State accumulation
- Request-response interactions

**What to Learn:**
- How to monitor token movements in vault
- State management for tracking balances
- Query/response patterns

---

## Architecture Mapping: Demos → AutoLend

### Pattern: Event Monitoring
**From Uniswap Stop Order:**
```solidity
// Monitor Uniswap Sync events
service.subscribe(
    SEPOLIA_CHAIN_ID,
    pairAddress,
    UNISWAP_V2_SYNC_TOPIC_0,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

**Apply to AutoLend:**
```solidity
// Monitor Aave ReserveDataUpdated events for Pool A
service.subscribe(
    SEPOLIA_CHAIN_ID,
    aavePoolA,
    RESERVE_DATA_UPDATED_TOPIC_0,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);

// Monitor Pool B
service.subscribe(
    SEPOLIA_CHAIN_ID,
    aavePoolB,
    RESERVE_DATA_UPDATED_TOPIC_0,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

### Pattern: Threshold Logic
**From Uniswap Stop Order:**
```solidity
function below_threshold(Reserves memory sync) internal view returns (bool) {
    return (sync.reserve1 * coefficient) / sync.reserve0 <= threshold;
}
```

**Apply to AutoLend:**
```solidity
function shouldRebalance(uint256 rateA, uint256 rateB) internal view returns (bool) {
    uint256 delta = rateA > rateB ? rateA - rateB : rateB - rateA;
    uint256 percentDelta = (delta * PRECISION) / (rateA > rateB ? rateA : rateB);
    return percentDelta >= rebalanceThreshold; // e.g., 50 = 0.5%
}
```

### Pattern: State Management
**From Uniswap Stop Order:**
```solidity
bool private triggered;
bool private done;

function react(LogRecord calldata log) external vmOnly {
    if (!triggered && shouldTrigger()) {
        triggered = true;
        emit Callback(...);
    }

    if (triggered && isComplete(log)) {
        done = true;
    }
}
```

**Apply to AutoLend:**
```solidity
bool private rebalancing;
uint256 private lastRebalanceBlock;
uint256 private cooldownPeriod = 100; // blocks

function react(LogRecord calldata log) external vmOnly {
    // Cooldown check
    if (block.number < lastRebalanceBlock + cooldownPeriod) {
        return;
    }

    // Get rates from both pools
    (uint256 rateA, uint256 rateB) = extractRates(log);

    if (!rebalancing && shouldRebalance(rateA, rateB)) {
        rebalancing = true;
        lastRebalanceBlock = block.number;

        // Determine direction and amount
        bool fromAtoB = rateB > rateA;
        uint256 amountToMove = calculateRebalanceAmount(rateA, rateB);

        bytes memory payload = abi.encodeWithSignature(
            "rebalance(uint256,bool)",
            amountToMove,
            fromAtoB
        );

        emit Callback(destinationChainId, vaultAddress, GAS_LIMIT, payload);
    }

    // Check for rebalance completion event
    if (rebalancing && log.topic_0 == REBALANCED_EVENT_TOPIC_0) {
        rebalancing = false;
    }
}
```

### Pattern: Periodic Checks (Alternative Approach)
**From Cron Demo:**
```solidity
function react(LogRecord calldata log) external vmOnly {
    if (log.topic_0 == CRON_TOPIC) {
        // Query current rates (via state reads or events)
        // Make rebalancing decision
        emit Callback(...);
    }
}
```

**Apply to AutoLend:**
- Use CRON as backup if rate update events are infrequent
- Periodically check pool states (e.g., every 100 blocks)
- Compare with event-driven approach for reliability

---

## Key Technical Patterns for AutoLend

### 1. Multi-Pool Monitoring
```solidity
struct PoolState {
    address poolAddress;
    uint256 currentRate;
    uint256 lastUpdate;
}

PoolState public poolA;
PoolState public poolB;

function react(LogRecord calldata log) external vmOnly {
    // Update state for whichever pool emitted event
    if (log._contract == poolA.poolAddress) {
        poolA.currentRate = extractRate(log);
        poolA.lastUpdate = block.number;
    } else if (log._contract == poolB.poolAddress) {
        poolB.currentRate = extractRate(log);
        poolB.lastUpdate = block.number;
    }

    // Check if rebalancing needed
    evaluateRebalancing();
}
```

### 2. Rate Extraction
```solidity
// Aave's ReserveDataUpdated event structure
// event ReserveDataUpdated(
//     address indexed reserve,
//     uint256 liquidityRate,
//     uint256 stableBorrowRate,
//     uint256 variableBorrowRate,
//     uint256 liquidityIndex,
//     uint256 variableBorrowIndex
// )

function extractRate(LogRecord calldata log) internal pure returns (uint256) {
    // Decode event data
    (uint256 liquidityRate, , , , ) = abi.decode(
        log.data,
        (uint256, uint256, uint256, uint256, uint256)
    );
    return liquidityRate;
}
```

### 3. Rebalancing Decision
```solidity
function evaluateRebalancing() internal {
    // Both pools must have recent data
    if (poolA.lastUpdate == 0 || poolB.lastUpdate == 0) {
        return;
    }

    // Cooldown check
    if (block.number < lastRebalanceBlock + cooldownPeriod) {
        return;
    }

    // Calculate yield delta
    uint256 delta = poolA.currentRate > poolB.currentRate
        ? poolA.currentRate - poolB.currentRate
        : poolB.currentRate - poolA.currentRate;

    uint256 percentDelta = (delta * PRECISION) /
        (poolA.currentRate > poolB.currentRate ? poolA.currentRate : poolB.currentRate);

    // Trigger if above threshold
    if (percentDelta >= rebalanceThreshold && !rebalancing) {
        triggerRebalance();
    }
}
```

### 4. Callback Payload Construction
```solidity
function triggerRebalance() internal {
    rebalancing = true;
    lastRebalanceBlock = block.number;

    bool fromAtoB = poolB.currentRate > poolA.currentRate;
    uint256 amountToMove = calculateAmount();

    bytes memory payload = abi.encodeWithSignature(
        "rebalance(uint256,bool)",
        amountToMove,
        fromAtoB
    );

    emit Callback(
        destinationChainId,
        vaultAddress,
        CALLBACK_GAS_LIMIT,
        payload
    );
}
```

---

## Implementation Strategy for AutoLend

### Phase 1: Start with Basic Demo Pattern
1. Set up three-contract architecture
2. Implement basic event subscription
3. Test callback mechanism with simple threshold

### Phase 2: Adapt Uniswap Stop Order Patterns
1. Implement multi-pool monitoring
2. Add threshold comparison logic
3. Implement state tracking (rebalancing, cooldown)
4. Add rebalancing callback

### Phase 3: Add Cron Backup (Optional)
1. Implement periodic rate checks
2. Add pause/resume functionality
3. Combine event-driven + periodic strategies

### Phase 4: Optimize
1. Gas optimization
2. Error handling
3. Edge case coverage
4. Security hardening

---

## Development Environment Setup

Based on the demos, we should use:

### Foundry (Recommended)
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Initialize project
forge init

# Install dependencies
forge install Reactive-Network/reactive-lib
forge install openzeppelin/openzeppelin-contracts

# Compile
forge compile

# Test
forge test -vv
```

### Required Dependencies
- `reactive-lib` - Core reactive contracts and interfaces
- `@openzeppelin/contracts` - Standard contract libraries
- Foundry toolchain (forge, cast, anvil)

### Environment Variables
```bash
# Origin/Destination Chain (Sepolia)
ORIGIN_RPC=<sepolia_rpc_url>
ORIGIN_CHAIN_ID=11155111
ORIGIN_PRIVATE_KEY=<your_private_key>

DESTINATION_RPC=<sepolia_rpc_url>
DESTINATION_CHAIN_ID=11155111
DESTINATION_PRIVATE_KEY=<your_private_key>

# Reactive Network
REACTIVE_RPC=<reactive_rpc_url>
REACTIVE_PRIVATE_KEY=<your_private_key>
SYSTEM_CONTRACT_ADDR=<system_contract_address>

# Callback Proxy
DESTINATION_CALLBACK_PROXY_ADDR=<callback_proxy_address>
```

---

## Recommended Next Steps

1. ✅ **Study Uniswap V2 Stop Order demo contract code in detail**
   - Understand state management
   - Learn threshold logic
   - Analyze callback construction

2. ✅ **Clone and run Basic demo locally**
   - Test full deployment flow
   - Understand event subscription
   - Test callback mechanism

3. ✅ **Design AutoLend reactive contract**
   - Map lending pool events to subscriptions
   - Define state variables
   - Design threshold logic

4. ✅ **Set up Foundry project**
   - Install dependencies
   - Create contract structure
   - Write initial tests

5. ✅ **Implement MVP reactive contract**
   - Two-pool monitoring
   - Basic threshold comparison
   - Simple rebalancing callback

---

## Conclusion

**Most Beneficial Demo: Uniswap V2 Stop Order** ⭐⭐⭐⭐⭐

This demo provides the closest architectural match to our AutoLend requirements:
- Monitors DeFi protocol state changes
- Implements threshold-based automation
- Demonstrates stateful reactive logic
- Shows automated trading/rebalancing patterns

**Recommended Learning Path:**
1. Master **Basic Demo** for fundamentals
2. Deep dive into **Uniswap Stop Order** for core patterns
3. Study **Cron Demo** for periodic monitoring alternative
4. Review **ERC-20 Turnovers** for state management patterns

By combining patterns from these demos, we can build a robust AutoLend reactive monitoring system that automatically rebalances vault funds between lending pools based on yield differentials.
