# Auction AMM

**Auction AMM** is an **automated market maker (AMM) with an on-chain manager auction** that helps **capture value lost to arbitrage** in traditional constant-product pools.
It’s designed to make liquidity provision more capital-efficient and transparent, while keeping the user experience familiar for traders.

---

## 🚀 Overview

In a normal AMM, arbitrageurs rebalance prices and extract profit at LPs’ expense (impermanent loss).
Auction AMM changes that dynamic by introducing a **Manager** role:

* **Manager Auction** — anyone can bid to become the pool’s manager for a fixed epoch.
* **Dynamic Fee Control** — the manager can set swap fees within a safe range to balance trader flow and arbitrage resistance.
* **Arbitrage Internalisation** — the manager gets first shot at price discrepancies and pays rent back to LPs.

This means LPs can recover much of the value normally taken by arbitrage bots.

---

## ✨ Features

* **Transparent Value Capture** — arbitrage profit that would go to outside bots is redirected back to liquidity providers through rent payments.
* **On-chain Manager Competition** — fair, continuous auction ensures the most efficient manager runs the pool.
* **Dynamic Fees** — fees adapt to market conditions to optimise returns and protect against toxic flow.
* **Composability** — remains fully compatible with existing DeFi tools and smart contract integrations.

---

## 🛠 How to Use

### Try the Web App

We’ve deployed a simple front-end where you can:

* Inspect and interact with an Auction AMM pool
* Visualise LP vs. Manager returns
* Experiment with fees, rent, and price moves

Clone the repo:
```bash
   git clone https://github.com/akronim26/eth-global
   npm run dev
   ```

### Run Locally

1. **Clone the repo**

   ```bash
   git clone https://github.com/akronim26/eth-global
   cd auction-amm
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Compile & deploy contracts**

   ```bash
   forge install
   forge test
   ```

### Smart Contracts

Core contracts live under `contracts/` and can be deployed to any EVM chain.

---

## ⚡️ Parameters You Can Experiment With

* **Liquidity (TVL)** — size of WBTC/USDC or other pair.
* **Max Fee Cap** — maximum swap fee manager can set.
* **Rent per Epoch** — amount manager must pay to hold the slot.
* **Epoch Length** — number of blocks a manager controls the pool.
* **Noise vs Arbitrage Intensity** — control simulated user flow and price volatility.

Graphs and scripts in `simulations/` help you simulate LP and manager returns under different conditions.

---

## 📊 Data

The simulated data is stored in [DATA.md](./DATA.md).

---

## 📊 Visuals

* LP profit in normal vs auction AMM
* Manager profit vs rent and fees
* Cumulative returns over time


![Profit Graph](./graphs/lp_manager_comparison.png?raw=true&width=200)

![Profit Graph](./graphs/manager_profit_scenarios.png?raw=true&width=250)

![Profit Graph](./graphs/lp_profit_comparison.png?raw=true&width=250)

![Profit Graph](./graphs/lp_profit_vs_arbitrage_intensity.png?raw=true&width=300)

---

## 🤝 Contributing

Pull requests and issues are welcome!
If you’d like to experiment with new fee models, manager strategies, or data analysis, open an issue to discuss.

---

## 📄 License

MIT — feel free to use and modify for research or production.
