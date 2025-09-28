import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend for saving plots

# --- Parameterizable model ---
def H0(f, L, h0=1.0, b=5.0, alpha=0.5):
    """Noise-trader volume per unit pool value, depends on liquidity L."""
    return h0 * L**alpha * np.exp(-b * f)

def AP0(f, L, a0=0.05, c=2.0, beta=0.5):
    """Arbitrage profit per unit pool value, depends on liquidity L."""
    return a0 * L**beta * np.exp(-c * f)

def AE0(f, L, a0=0.05, d=8.0, beta=0.5):
    """Arbitrage excess per unit pool value, depends on liquidity L."""
    return a0 * L**beta * np.exp(-d * f)

def lp_profit_fixed_fee(f,L, h0=1.0,b=5.0,a0=0.05,c=2.0,alpha=0.5,beta=0.5,r=0.001):
    return f * H0(f,L,h0,b,alpha) - AP0(f,L,a0,c,beta) - r

def lp_profit_am_amm(f,L,h0=1.0,b=5.0,a0=0.05,d=8.0,alpha=0.5,beta=0.5,r=0.001):
    return f * H0(f,L,h0,b,alpha) - AE0(f,L,a0,d,beta) - r

def find_optimal_lp_profits(L_values, fmax=0.2,
                            h0=1.0,b=5.0,a0=0.05,c=2.0,d=8.0,alpha=0.5,beta=0.5,r=0.001):
    fs = np.linspace(0.0001, fmax, 500)
    fixed_best=[]
    am_best=[]
    for L in L_values:
        fixed_vals = lp_profit_fixed_fee(fs,L,h0,b,a0,c,alpha,beta,r)
        am_vals = lp_profit_am_amm(fs,L,h0,b,a0,d,alpha,beta,r)
        fixed_best.append(np.max(fixed_vals))
        am_best.append(np.max(am_vals))
    return max(np.array(fixed_best)), max(np.array(am_best))

# --- Graph 1: LP profit vs liquidity ---
L_vals = np.linspace(0.1,10,50)
fixed_best,am_best = find_optimal_lp_profits(L_vals)

# plt.figure(figsize=(8,5))
# plt.plot(L_vals,fixed_best,label='Fixed-Fee AMM (optimal fee)')
# plt.plot(L_vals,am_best,label='Auction AMM (optimal fee)')
# plt.xlabel('Relative Liquidity L')
# plt.ylabel('LP Profit per unit value')
# plt.title('LP Profit vs Liquidity')
# plt.legend()
# plt.grid(True)
# plt.savefig('lp_profit_vs_liquidity.png', dpi=300, bbox_inches='tight')
# print("Graph 1 saved as 'lp_profit_vs_liquidity.png'")

# # --- Graph 2: LP profit vs price difference (arbitrage intensity) ---
# a0_vals = np.linspace(0.01,0.2,50)
# fixed_best_a=[]
# am_best_a=[]
# for a0_val in a0_vals:
#     fixed_best_i,am_best_i = find_optimal_lp_profits([1.0],a0=a0_val)
#     fixed_best_a.append(fixed_best_i[0])
#     am_best_a.append(am_best_i[0])

# plt.figure(figsize=(8,5))
# plt.plot(a0_vals,fixed_best_a,label='Fixed-Fee AMM (optimal fee)')
# plt.plot(a0_vals,am_best_a,label='Auction AMM (optimal fee)')
# plt.xlabel('Arbitrage Intensity (a0) ~ Price Difference vs CEX')
# plt.ylabel('LP Profit per unit value')
# plt.title('LP Profit vs Price Difference (Arbitrage Intensity)')
# plt.legend()
# plt.grid(True)
# plt.savefig('lp_profit_vs_arbitrage_intensity.png', dpi=300, bbox_inches='tight')
fixed_best_a,am_best_a = find_optimal_lp_profits([1.0],a0=0.05)
print("Difference in LP profit between fixed-fee and auction AMMs:", am_best_a - fixed_best_a)