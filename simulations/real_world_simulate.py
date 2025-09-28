import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')

# --- Building blocks ---
def H0(f, L, h0, b):
    """Noise-trader volume per unit pool value"""
    return h0 * np.exp(-b * f) * L**0.5

def AP0(f, L, a0, c):
    """Total arbitrage per unit pool value"""
    return a0 * np.exp(-c * f) * L**0.5

def AE0(f, L, a0, d):
    """Arbitrage excess per unit pool value (left for outsiders after fee f)"""
    return a0 * np.exp(-d * f) * L**0.5

def gross_manager_revenue(f, L, h0, b, a0, c, d):
    # f*H0 + AP0(0) - AE0(f)
    return f * H0(f, L, h0, b) + AP0(0, L, a0, c) - AE0(f, L, a0, d)

def lp_profit_normal(f, L, h0, b, a0, c, r):
    return f*H0(f,L,h0,b) - AP0(f,L,a0,c) - r

def lp_profit_auction(f, L, h0, b, a0, c, d, r, R):
    # rent minus leftover arb minus cost
    return R - (AP0(0,L,a0,c) - AE0(f,L,a0,d)) - r

def manager_profit(f, L, h0, b, a0, c, d, R):
    return gross_manager_revenue(f,L,h0,b,a0,c,d) - R

# --- USER INPUTS ---
WETH_amt = 333_333       # e.g. 500 WETH in pool
USDC_amt = 1_000_000 # e.g. 1M USDC in pool
eth_price = 3     # market price of WETH in USDC
pool_value = WETH_amt*eth_price + USDC_amt
L = pool_value/1e6   # scale L by millions if you like

h0 = 1.0             # base noise trader $ flow per block per 1M TVL
a0 = 0.10            # arbitrage intensity (0.05 = 5% per time if f=0)
b = 5.0              # noise fee elasticity
c = 2.0              # arbitrage fee elasticity
d = 18.0              # arbitrage excess decays faster
r = 0.000           # LP capital cost per block

fmax = 0.01          # max fee (1%)
R = 0.010            # rent per block (per 1M TVL) manager pays LPs
T = 30 * 7200        # blocks the manager slot lasts; 7200 blocks ~ 1 day

# --- OPTIMIZE MANAGER FEE ---
fs = np.linspace(0.0001, fmax, 500)
mgr_revenues = [gross_manager_revenue(f, L, h0, b, a0, c, d) for f in fs]
best_f = fs[np.argmax(mgr_revenues)]
best_mgr_rev = np.max(mgr_revenues)
print(f"Manager optimal fee: {best_f:.4%}")

# --- SIMULATE PROFITS OVER T BLOCKS ---
mgr_rate = manager_profit(best_f, L, h0, b, a0, c, d, R)
lp_rate_auction = lp_profit_auction(best_f, L, h0, b, a0, c, d, r, R)
lp_rate_normal = lp_profit_normal(best_f, L, h0, b, a0, c, r)  # compare to normal AMM using same f

cum_mgr = np.cumsum([mgr_rate]*T)
cum_lp_auction = np.cumsum([lp_rate_auction]*T)
cum_lp_normal = np.cumsum([lp_rate_normal]*T)

# --- Plot ---
plt.figure(figsize=(9,5))
plt.plot(cum_mgr, label="Manager cumulative (Auction AMM)")
plt.plot(cum_lp_auction, label="LP cumulative (Auction AMM)")
plt.plot(cum_lp_normal, label="LP cumulative (Normal AMM)")
plt.xlabel("Block")
plt.ylabel("Cumulative profit per $1M TVL")
plt.title("Manager vs LP Cumulative Profit — Auction vs Normal AMM")
plt.legend()
plt.grid(True)
plt.savefig('profit_comparison.png', dpi=300, bbox_inches='tight')
# print("Graph saved as 'profit_comparison.png'")

# --- Report totals vs normal AMM ---
print(f"Manager total over {T / 7200} days: {cum_mgr[-1]:.4f} per $1M TVL")
print(f"LP total Auction over {T / 7200} days: {cum_lp_auction[-1]:.4f} per $1M TVL")
print(f"LP total Normal over {T / 7200} days: {cum_lp_normal[-1]:.4f} per $1M TVL")
print(f"LP gain (Auction - Normal): {(cum_lp_auction[-1] - cum_lp_normal[-1]):.4f} per $1M TVL")

# Example: compute per-LP outcome
D = 100_000  # your LP deposit in USD
V = pool_value

lp_share = D / V
lp_auc_abs = cum_lp_auction[-1] * (V/1e6) * lp_share
lp_norm_abs = cum_lp_normal[-1]  * (V/1e6) * lp_share

print(f"Your profit in Auction AMM: ${lp_auc_abs:.2f}")
print(f"Your profit in Normal AMM : ${lp_norm_abs:.2f}")
print(f"Your profit in Auction vs Normal AMM: ${(lp_auc_abs - lp_norm_abs):.2f}")
