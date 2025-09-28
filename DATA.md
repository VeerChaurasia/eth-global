## 📊 Data

This data comes from running:
```bash
python real_world_simulate.py
```

Let's take a scenario where the price of 1 WETH is 3 USDC and the pool has a small price difference of 1_000_000 / 333_333 = 3.000003 USDC.

If we deploy the pool with parameters such that the Manager has a tenure of 30 days, we can get the following profits for LPs and Manager:

### Scenario 1

```python
Manager total over 30.0 days:
2,537.7228 per $1M TVL

LP total Auction over 30.0 days:
367.9983 per $1M TVL

LP total Normal over 30.0 days:
-27,036.4131 per $1M TVL

LP gain (Auction - Normal):
27,404.4113 per $1M TVL
```

The parameters used were:
```python
WETH_amt = 333,333       # e.g. 500 WETH in pool
USDC_amt = 1,000,000 # e.g. 1M USDC in pool
eth_price = 3     # market price of WETH in USDC
pool_value = WETH_amt * eth_price + USDC_amt
L = pool_value / 1e6   # scale L by millions if you like

h0 = 1.0             # base noise trader $ flow per block per 1M TVL
a0 = 0.10            # arbitrage intensity (0.05 = 5% per time if f=0)
b = 5.0              # noise fee elasticity
c = 2.0              # arbitrage fee elasticity
d = 18.0              # arbitrage excess decays faster
r = 0.000           # LP capital cost per block

fmax = 0.01          # max fee (1%)
R = 0.025            # rent per block (per 1M TVL) manager pays LPs
T = 30 * 7200        # blocks the manager slot lasts; 7200 blocks ~ 1 day

```

### Scenario 2

If the Manager pays lesser Rent per block, other parameters staying the same, the data is:
```python
Manager total over 30.0 days: 5777.7228 per $1M TVL
LP total Auction over 30.0 days: -2872.0017 per $1M TVL
LP total Normal over 30.0 days: -27036.4131 per $1M TVL
LP gain (Auction - Normal): 24164.4113 per $1M TVL
```

The Manager's profit increases drastically.

Here `R = 0.010`, other parameters staying the same.

The Manager in this idea is assumed to be a economically rational, specialized entity, seeking to maximise it's own profit's, while outbidding competitors. This ensures a fair, constant gain for other LPs as well.