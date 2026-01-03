Design and implement a cross-chain lending automation vault using Reactive Smart Contracts. The vault should monitor at least two lending markets (e.g. two lending pools on Ethereum Sepolia) and automatically rebalance provided liquidity between them based on a configurable yield signal.

The deadline is December, 28, 11:59 PM UTC. it was extended by a week as they were on holidays. 

Core requirements:

Integrate with at least two lending pools (e.g. A and B) that expose deposit/withdraw and rate information on-chain.
Use Reactive Smart Contracts to:
Listen to on-chain events or periodically check state (supply/borrow rates, utilization, or another yield proxy).
Trigger rebalancing transactions that move funds from pool A → B or B → A when a configurable condition is met (e.g. yield difference above a threshold).
Provide a single “vault” interface for users:
Users deposit into the vault once.
The vault allocates and reallocates funds between pools automatically according to the strategy.