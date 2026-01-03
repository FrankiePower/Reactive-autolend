# Lending Pool Integration Strategy for AutoLend

## Overview

This document outlines the available lending protocols on Sepolia testnet, how to monitor them, and our recommended integration strategy for the AutoLend reactive vault.

---

## Available Lending Protocols on Sepolia Testnet

### 1. Aave V3 ⭐⭐⭐⭐⭐ (RECOMMENDED)

**Status:** ✅ Fully deployed and active on Sepolia

**Key Contract Addresses (Sepolia):**
- **Pool (Proxy):** `0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951`
- **PoolAddressesProviderRegistry:** `0x812C23640dC89FF6Cb8B5AF44a3094a94b26b93A`

**Why Aave V3:**
- ✅ Most widely used and battle-tested protocol
- ✅ Excellent documentation and developer resources
- ✅ Well-defined events for monitoring (ReserveDataUpdated)
- ✅ Active on Sepolia testnet with testnet mode on app.aave.com
- ✅ Multiple reserves (USDC, DAI, USDT, WETH, etc.)
- ✅ Clear rate information exposed on-chain
- ✅ Proven integration patterns in production

**Supported Assets on Sepolia:**
- USDC, DAI, USDT (stablecoins)
- WETH (wrapped ETH)
- LINK, WBTC (other assets)

**Documentation:**
- [V3 Testnet Addresses](https://docs.aave.com/developers/deployed-contracts/v3-testnet-addresses)
- [Addresses Dashboard](https://aave.com/docs/resources/addresses)
- [Testing & Debugging](https://aave.com/docs/developers/testing-and-debugging)

---

### 2. Compound V3 (Comet) ⭐⭐⭐⭐

**Status:** ✅ Deployed on Sepolia

**Key Contract Addresses (Sepolia):**
- **cUSDCv3 (Comet Proxy):** `0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e`
- **CometWrapper (ERC-4626):** `0xC3836072018B4D590488b851d574556f2EeB895a`
- **COMP Token:** `0x8dCb0C9a616bEdcf70eB826BA8Cfc8a11b420EE7`

**Why Compound V3:**
- ✅ Second most popular lending protocol
- ✅ Active deployment on Sepolia
- ✅ ERC-4626 wrapper available for standard interface
- ✅ Good documentation
- ⚠️ Primarily USDC-focused (less multi-asset than Aave)

**Documentation:**
- [Compound III Documentation](https://docs.compound.finance/)
- [Comet GitHub](https://github.com/compound-finance/comet)
- [Architecture Guide](https://rareskills.io/post/compound-v3-contracts-tutorial)

---

### 3. Morpho ⭐⭐⭐

**Status:** ⚠️ Testnet deployment exists but less documented

**Sepolia Presence:**
- Morpho LTV Vault on Sepolia leveraging Morpho lending market
- Supports WETH and USDC
- Less established testnet ecosystem

**Why Morpho:**
- ✅ Innovative protocol with competitive rates
- ✅ Built on top of Aave/Compound for optimization
- ⚠️ Newer protocol with less testnet documentation
- ⚠️ More complex architecture

**Documentation:**
- [Morpho Sepolia Testnet Docs](https://docs.ltv.finance/morpho_testnet.html)
- [Morpho Protocol](https://morpho.org/)
- [Addresses](https://docs.morpho.org/addresses/)

---

## Recommended Strategy: Two Aave V3 Reserves

### Why This Approach?

**Use Case:** Monitor two different lending markets within Aave V3
- **Option A:** Two different assets (e.g., USDC pool vs DAI pool)
- **Option B:** Same asset, different market configurations (if available)

**Advantages:**
1. **Simplicity:** Single protocol integration, consistent interface
2. **Reliability:** Well-tested events and rate updates
3. **Documentation:** Extensive guides and examples
4. **Testnet Support:** Active Sepolia deployment with faucets
5. **Event Monitoring:** Clear `ReserveDataUpdated` events to track

**Alternative:** Use Aave V3 + Compound V3
- Monitor USDC lending on both protocols
- Compare yields cross-protocol
- More complex but demonstrates real cross-protocol optimization

---

## How to Monitor Lending Pools

### Aave V3 Event Monitoring

#### Key Event: `ReserveDataUpdated`

```solidity
event ReserveDataUpdated(
    address indexed reserve,              // Asset address (e.g., USDC)
    uint256 liquidityRate,                // Supply APY (ray units, 27 decimals)
    uint256 stableBorrowRate,            // Stable borrow rate
    uint256 variableBorrowRate,          // Variable borrow rate
    uint256 liquidityIndex,              // Cumulative liquidity index
    uint256 variableBorrowIndex          // Cumulative variable borrow index
);
```

**Event Topic 0 (Signature Hash):**
```
0x804c9b842b2748a22bb64b345453a3de7ca54a6ca45ce00d415894979e22897a
```

**What We Monitor:**
- `liquidityRate` - This is the supply APY we care about for yield comparison
- Emitted whenever pool conditions change (deposits, withdrawals, borrows, repays)

#### Reactive Contract Subscription

```solidity
// Subscribe to Aave Pool for USDC reserve updates
uint256 constant RESERVE_DATA_UPDATED_TOPIC_0 =
    0x804c9b842b2748a22bb64b345453a3de7ca54a6ca45ce00d415894979e22897a;

service.subscribe(
    SEPOLIA_CHAIN_ID,
    AAVE_POOL_ADDRESS,        // 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951
    RESERVE_DATA_UPDATED_TOPIC_0,
    uint256(uint160(USDC_ADDRESS)),  // topic_1: filter for USDC reserve only
    REACTIVE_IGNORE,
    REACTIVE_IGNORE
);
```

#### Extracting Rate from Event

```solidity
function react(LogRecord calldata log) external vmOnly {
    // Decode the event data
    (
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    ) = abi.decode(log.data, (uint256, uint256, uint256, uint256, uint256));

    // liquidityRate is in Ray (27 decimals)
    // To get APY: liquidityRate / 1e27 * 100 = X%

    // Update our tracked state
    if (log.topic_1 == uint256(uint160(POOL_A_RESERVE))) {
        poolA.currentRate = liquidityRate;
        poolA.lastUpdate = block.number;
    } else if (log.topic_1 == uint256(uint160(POOL_B_RESERVE))) {
        poolB.currentRate = liquidityRate;
        poolB.lastUpdate = block.number;
    }

    // Evaluate if rebalancing is needed
    evaluateRebalancing();
}
```

---

### Compound V3 Event Monitoring (Alternative)

#### Key Events

**1. Supply Event:**
```solidity
event Supply(
    address indexed from,
    address indexed dst,
    uint256 amount
);
```

**2. Withdraw Event:**
```solidity
event Withdraw(
    address indexed src,
    address indexed to,
    uint256 amount
);
```

**3. AccrueInterest Event:**
```solidity
event AccrueInterest(
    uint256 timeStamp,
    uint256 baseSupplyIndex,
    uint256 baseBorrowIndex
);
```

**Monitoring Strategy:**
- Subscribe to `AccrueInterest` events to track rate updates
- Query supply rate via `getSupplyRate()` function
- More complex than Aave's direct rate emission

---

## Recommended Architecture: Two Aave Reserves

### Setup 1: Multi-Asset Strategy

**Pool A: USDC Lending**
- Asset: USDC (Sepolia testnet USDC)
- Aave Reserve: USDC reserve on Aave V3 Sepolia
- Monitor: `ReserveDataUpdated` with topic_1 = USDC address

**Pool B: DAI Lending**
- Asset: DAI (Sepolia testnet DAI)
- Aave Reserve: DAI reserve on Aave V3 Sepolia
- Monitor: `ReserveDataUpdated` with topic_1 = DAI address

**Rebalancing Logic:**
- Compare USDC supply rate vs DAI supply rate
- When delta > threshold, convert vault assets and rebalance
- More complex due to asset conversion

---

### Setup 2: Cross-Protocol Strategy (Advanced)

**Pool A: Aave V3 USDC**
- Protocol: Aave V3
- Asset: USDC
- Pool Address: `0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951`
- Monitor: `ReserveDataUpdated` event

**Pool B: Compound V3 USDC**
- Protocol: Compound V3
- Asset: USDC
- Pool Address: `0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e`
- Monitor: `AccrueInterest` or periodic rate queries

**Rebalancing Logic:**
- Compare Aave USDC rate vs Compound USDC rate
- Same asset, simpler rebalancing (no conversion needed)
- Demonstrates real cross-protocol optimization

---

### Setup 3: Simplified Mock Strategy (For Development)

**For faster iteration and testing:**

**Pool A: Mock Lending Pool A**
- Custom contract with configurable rates
- Emits custom `RateUpdated` events
- Easy to manipulate for testing

**Pool B: Mock Lending Pool B**
- Same interface as Pool A
- Independently configurable rates
- Allows controlled testing scenarios

**Advantages:**
- Full control over rates and events
- No need for testnet tokens
- Faster development cycles
- Can test edge cases easily

---

## Implementation Roadmap

### Phase 1: Development (Mock Pools) ⭐ START HERE

**Contracts:**
```
MockLendingPool.sol
├── function deposit(uint256 amount)
├── function withdraw(uint256 amount)
├── function setSupplyRate(uint256 rate)  // Owner only
├── function getSupplyRate() → uint256
└── event RateUpdated(uint256 newRate, uint256 timestamp)

AutoLendVault.sol (with mock pool adapters)
ReactiveLendingMonitor.sol (subscribes to RateUpdated)
```

**Benefits:**
- Rapid development and testing
- No testnet dependencies
- Full control over scenarios

---

### Phase 2: Testnet Integration (Aave V3)

**Contracts:**
```
AaveV3Adapter.sol
├── Wraps Aave V3 Pool interface
├── Maps deposit/withdraw to Aave's supply/withdraw
├── Extracts rates from ReserveDataUpdated events
└── Handles aToken conversions

AutoLendVault.sol (with Aave adapters)
ReactiveLendingMonitor.sol (subscribes to Aave events)
```

**Setup:**
1. Deploy vault on Sepolia
2. Configure for USDC reserve (Pool A) and DAI reserve (Pool B)
3. Deploy reactive monitor on Reactive Network
4. Subscribe to `ReserveDataUpdated` events for both reserves
5. Test rebalancing between reserves

---

### Phase 3: Production-Ready (Optional)

**Add:**
- Compound V3 integration
- More sophisticated yield strategies
- Multi-chain support
- Advanced risk management

---

## Event Monitoring Code Examples

### Aave V3 Reactive Monitor

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "reactive-lib/interfaces/IReactive.sol";
import "reactive-lib/abstract-base/AbstractReactive.sol";

contract AaveLendingMonitor is IReactive, AbstractReactive {
    // Aave V3 ReserveDataUpdated event signature
    uint256 private constant RESERVE_DATA_UPDATED_TOPIC_0 =
        0x804c9b842b2748a22bb64b345453a3de7ca54a6ca45ce00d415894979e22897a;

    uint64 private constant CALLBACK_GAS_LIMIT = 1000000;
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;

    // Pool addresses
    address private constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;

    // Reserve addresses (assets)
    address private immutable reserveA;  // e.g., USDC
    address private immutable reserveB;  // e.g., DAI

    // Vault callback address
    address private immutable vault;

    // State
    struct PoolState {
        uint256 currentRate;
        uint256 lastUpdate;
    }

    PoolState public poolA;
    PoolState public poolB;

    uint256 public rebalanceThreshold;  // In basis points (e.g., 50 = 0.5%)
    uint256 public cooldownPeriod;      // Blocks between rebalances
    uint256 public lastRebalanceBlock;
    bool public rebalancing;

    constructor(
        address _service,
        address _vault,
        address _reserveA,
        address _reserveB,
        uint256 _threshold,
        uint256 _cooldown
    ) payable {
        service = ISystemContract(payable(_service));
        vault = _vault;
        reserveA = _reserveA;
        reserveB = _reserveB;
        rebalanceThreshold = _threshold;
        cooldownPeriod = _cooldown;

        if (!vm) {
            // Subscribe to Reserve A updates
            service.subscribe(
                SEPOLIA_CHAIN_ID,
                AAVE_POOL,
                RESERVE_DATA_UPDATED_TOPIC_0,
                uint256(uint160(_reserveA)),  // Filter for reserve A
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );

            // Subscribe to Reserve B updates
            service.subscribe(
                SEPOLIA_CHAIN_ID,
                AAVE_POOL,
                RESERVE_DATA_UPDATED_TOPIC_0,
                uint256(uint160(_reserveB)),  // Filter for reserve B
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }

    function react(LogRecord calldata log) external vmOnly {
        // Decode the ReserveDataUpdated event
        (
            uint256 liquidityRate,
            , // stableBorrowRate
            , // variableBorrowRate
            , // liquidityIndex
              // variableBorrowIndex
        ) = abi.decode(log.data, (uint256, uint256, uint256, uint256, uint256));

        // Update state based on which reserve emitted the event
        if (log.topic_1 == uint256(uint160(reserveA))) {
            poolA.currentRate = liquidityRate;
            poolA.lastUpdate = block.number;
        } else if (log.topic_1 == uint256(uint160(reserveB))) {
            poolB.currentRate = liquidityRate;
            poolB.lastUpdate = block.number;
        }

        // Evaluate rebalancing
        evaluateRebalancing();
    }

    function evaluateRebalancing() internal {
        // Check if we have data from both pools
        if (poolA.lastUpdate == 0 || poolB.lastUpdate == 0) {
            return;
        }

        // Check cooldown
        if (block.number < lastRebalanceBlock + cooldownPeriod) {
            return;
        }

        // Check if already rebalancing
        if (rebalancing) {
            return;
        }

        // Calculate yield delta
        uint256 rateA = poolA.currentRate;
        uint256 rateB = poolB.currentRate;

        if (shouldRebalance(rateA, rateB)) {
            triggerRebalance(rateA > rateB);
        }
    }

    function shouldRebalance(uint256 rateA, uint256 rateB) internal view returns (bool) {
        uint256 delta = rateA > rateB ? rateA - rateB : rateB - rateA;
        uint256 higherRate = rateA > rateB ? rateA : rateB;

        // Calculate percentage difference (in basis points)
        // rates are in Ray (27 decimals), threshold is in basis points
        uint256 percentDelta = (delta * 10000) / higherRate;

        return percentDelta >= rebalanceThreshold;
    }

    function triggerRebalance(bool fromAtoB) internal {
        rebalancing = true;
        lastRebalanceBlock = block.number;

        // Encode callback to vault
        bytes memory payload = abi.encodeWithSignature(
            "rebalance(bool)",
            fromAtoB  // true = move from A to B, false = move from B to A
        );

        emit Callback(
            SEPOLIA_CHAIN_ID,
            vault,
            CALLBACK_GAS_LIMIT,
            payload
        );
    }
}
```

---

## Testnet Token Faucets

### Getting Testnet Assets

**Sepolia ETH:**
- [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
- [Chainlink Sepolia Faucet](https://faucets.chain.link/sepolia)

**Aave V3 Testnet Tokens:**
1. Visit [app.aave.com](https://app.aave.com)
2. Enable testnet mode
3. Connect wallet to Sepolia
4. Use built-in faucet for testnet tokens (USDC, DAI, etc.)

**Reactive Network Tokens:**
- Send SepETH to faucet: `0x9b9BB25f1A81078C544C829c5EB7822d747Cf434`
- Exchange rate: 1 SepETH = 100 REACT
- Max 5 SepETH per request = 500 REACT

---

## Final Recommendation

### 🎯 For AutoLend Project

**Phase 1 (Development):** Two Mock Lending Pools
- Fast iteration
- Full control
- Easy testing

**Phase 2 (Demo/Testnet):** Aave V3 USDC + DAI Reserves
- Real protocol integration
- Single protocol (simpler)
- Well-documented events
- Easy to demonstrate

**Phase 3 (Advanced):** Aave V3 USDC + Compound V3 USDC
- Cross-protocol optimization
- Real-world use case
- More impressive demo

**Start with Phase 1, move to Phase 2 for the hackathon submission.**

---

## Next Steps

1. ✅ Choose integration strategy (Recommended: Mock → Aave V3)
2. ⏭️ Set up Foundry project with Aave V3 interfaces
3. ⏭️ Implement mock lending pools for testing
4. ⏭️ Build vault with pool adapters
5. ⏭️ Implement reactive monitor with Aave event subscriptions
6. ⏭️ Test locally with mocks
7. ⏭️ Deploy to Sepolia and test with real Aave pools

---

## Resources

### Aave V3
- [V3 Testnet Addresses](https://docs.aave.com/developers/deployed-contracts/v3-testnet-addresses)
- [Addresses Dashboard](https://aave.com/docs/resources/addresses)
- [Testing & Debugging](https://aave.com/docs/developers/testing-and-debugging)

### Compound V3
- [Compound III Documentation](https://docs.compound.finance/)
- [Comet GitHub](https://github.com/compound-finance/comet)
- [Architecture Guide](https://rareskills.io/post/compound-v3-contracts-tutorial)

### Morpho
- [Morpho Sepolia Testnet](https://docs.ltv.finance/morpho_testnet.html)
- [Morpho Protocol](https://morpho.org/)
- [Morpho Addresses](https://docs.morpho.org/addresses/)
