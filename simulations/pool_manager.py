import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # non-interactive backend for saving plots

# --- Parametric building blocks ---
def H0(f, L, h0=1.0, b=5.0, alpha=0.5):
    return h0 * L**alpha * np.exp(-b * f)

def AP0_zero(L, a0=0.05, beta=0.5, shock=0.0):
    return a0 * L**beta + shock

def AE0(f, L, a0=0.05, d=8.0, beta=0.5):
    return a0 * L**beta * np.exp(-d * f)

def manager_profit_rate(f, L, R, shock=0.0, params=None):
    if params is None: params = {}
    return f*H0(f,L,params.get('h0',1.0),params.get('b',5.0),params.get('alpha',0.5)) \
           + AP0_zero(L,params.get('a0',0.05),params.get('beta',0.5),shock) \
           - AE0(f,L,params.get('a0',0.05),params.get('d',8.0),params.get('beta',0.5)) \
           - R

def lp_profit_rate_auction(f, L, R, r=0.0, shock=0.0, params=None):
    """LP in auction AMM: rent minus remaining arbitrage minus cost of capital"""
    if params is None: params = {}
    return R - (AP0_zero(L,params.get('a0',0.05),params.get('beta',0.5),shock) -
                AE0(f,L,params.get('a0',0.05),params.get('d',8.0),params.get('beta',0.5))) - r

def lp_profit_rate_normal(f, L, r=0.0, shock=0.0, params=None):
    """LP in normal AMM: fee revenue minus full arbitrage minus cost of capital"""
    if params is None: params = {}
    return f*H0(f,L,params.get('h0',1.0),params.get('b',5.0),params.get('alpha',0.5)) \
           - AP0_zero(L,params.get('a0',0.05),params.get('beta',0.5),shock) - r

# --- Simulation parameters ---
T = 200
L = 1.0
f = 0.01
R = 0.02      # rent manager pays per block to LPs
r = 0.001
params = {'h0':1.0,'b':5.0,'alpha':0.5,'a0':0.05,'d':8.0,'beta':0.5}

# Price shock scenario
rng = np.random.default_rng(42)
shocks = np.zeros(T)
shock_times = rng.choice(np.arange(20, T-10), size=5, replace=False)
for st in shock_times:
    shocks[st:st+3] += rng.uniform(0.02, 0.08)

# Manager and LP profit rates
mgr_rates = np.array([manager_profit_rate(f,L,R,shock=shocks[t],params=params) for t in range(T)])
lp_rates_auction = np.array([lp_profit_rate_auction(f,L,R,r,shock=shocks[t],params=params) for t in range(T)])
lp_rates_normal  = np.array([lp_profit_rate_normal(f,L,r,shock=shocks[t],params=params) for t in range(T)])

# Competitive rent scenario for auction LPs
epoch_len = 20
epochs = T // epoch_len
cum_lp_comp = np.zeros(T)
total_lp = 0.0
R_epoch = R
for e in range(epochs):
    start = e*epoch_len
    end = start + epoch_len
    # gross revenue manager can capture if fee f is constant
    gross = np.array([ f*H0(f,L,params['h0'],params['b'],params['alpha']) +
                       AP0_zero(L,params['a0'],params['beta']) -
                       AE0(f,L,params['a0'],params['d'],params['beta'])
                      for _ in range(epoch_len) ])
    # LP profit = R_epoch minus leftover arbitrage (approx) each block
    net_lp = np.array([lp_profit_rate_auction(f,L,R_epoch,r,params=params) for _ in range(epoch_len)])
    cum_lp_comp[start:end] = net_lp + (total_lp if start==0 else cum_lp_comp[start-1])
    total_lp = cum_lp_comp[end-1]
    # new rent ~95% of observed gross (simulate competitive rent)
    avg_gross = np.mean(gross)
    R_epoch = 0.95 * avg_gross

cum_mgr = np.cumsum(mgr_rates)
cum_lp_auction = np.cumsum(lp_rates_auction)
cum_lp_normal = np.cumsum(lp_rates_normal)

# --- Plot ---
plt.figure(figsize=(10,6))
# plt.plot(cum_mgr, label="Manager cumulative (auction)")
plt.plot(cum_lp_auction, label="LP cumulative (auction, fixed R)")
plt.plot(cum_lp_comp, label="LP cumulative (auction, competitive R)")
plt.plot(cum_lp_normal, label="LP cumulative (normal AMM)")
plt.xlabel("Block")
plt.ylabel("Cumulative profit per unit value")
plt.title("Manager vs LP profit: Auction vs Normal AMM")
plt.legend()
plt.grid(True)
plt.savefig('lp_manager_comparison.png', dpi=300, bbox_inches='tight')
print("Graph saved as 'lp_manager_comparison.png'")

print("Manager final:", cum_mgr[-1])
print("LP auction (fixed R) final:", cum_lp_auction[-1])
print("LP auction (competitive R) final:", cum_lp_comp[-1])
print("LP normal final:", cum_lp_normal[-1])

import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend for saving plots

# Use the same H0, AP0, AE0 from before
def H0(f, L, h0=1.0, b=5.0, alpha=0.5):
    return h0 * L**alpha * np.exp(-b * f)

def AP0(f, L, a0=0.05, c=2.0, beta=0.5):
    return a0 * L**beta * np.exp(-c * f)

def AE0(f, L, a0=0.05, d=8.0, beta=0.5):
    return a0 * L**beta * np.exp(-d * f)

def manager_profit_rate(f, L, R,
                       h0=1.0,b=5.0,a0=0.05,c=2.0,d=8.0,
                       alpha=0.5,beta=0.5):
    """Manager's instantaneous profit rate per unit value at fee f and rent R."""
    return f*H0(f,L,h0,b,alpha) + AP0(0,L,a0,c,beta) - AE0(f,L,a0,d,beta) - R

# Example parameters
L = 1.0                 # pool liquidity
f = 0.02                # manager-set fee (2%)
R = 0.03                # rent per unit time paid to LPs

# Simulate profit over an epoch of T time units
T = 100
times = np.arange(T)
profit_rate = manager_profit_rate(f,L,R)  # constant per unit time here
cum_profit = profit_rate * times          # cumulative profit grows linearly if rate constant

plt.figure(figsize=(8,5))
plt.plot(times, cum_profit, label='Manager cumulative profit')
plt.xlabel('Time (blocks or seconds)')
plt.ylabel('Cumulative Profit per unit value')
plt.title('Manager profit over epoch')
plt.grid(True)
plt.legend()
plt.show()

print("Manager instantaneous profit rate per unit value:", profit_rate)



import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend for saving plots

# --- Parametric building blocks (simple) ---
def H0(f, L, h0=1.0, b=5.0, alpha=0.5):
    return h0 * L**alpha * np.exp(-b * f)

def AP0_zero(L, a0=0.05, beta=0.5, shock=0.0):
    # baseline arbitrage available at zero fee plus an additive shock
    return a0 * L**beta + shock

def AE0(f, L, a0=0.05, d=8.0, beta=0.5):
    return a0 * L**beta * np.exp(-d * f)

def manager_profit_rate(f, L, R, shock=0.0, params=None):
    if params is None:
        params = {}
    h0 = params.get('h0',1.0); b = params.get('b',5.0); alpha = params.get('alpha',0.5)
    a0 = params.get('a0',0.05); d = params.get('d',8.0); beta = params.get('beta',0.5)
    # instantaneous rate
    return f*H0(f,L,h0,b,alpha) + AP0_zero(L,a0,beta,shock) - AE0(f,L,a0,d,beta) - R

# --- Simulation parameters ---
T = 200                     # blocks in epoch
L = 1.0                     # liquidity scale
f = 0.01                    # manager fee
R_fixed = 0.02              # rent paid (per unit time)
params = {'h0':1.0,'b':5.0,'alpha':0.5,'a0':0.05,'d':8.0,'beta':0.5}

# Scenario A: fixed environment
rates = np.array([manager_profit_rate(f,L,R_fixed,shock=0.0,params=params) for t in range(T)])
cumA = np.cumsum(rates)

# Scenario B: random price shocks occasionally
rng = np.random.default_rng(123)
shocks = np.zeros(T)
shock_times = rng.choice(np.arange(20, T-10), size=5, replace=False)
for st in shock_times:
    shocks[st:st+3] += rng.uniform(0.02, 0.08)   # short shock lasting 3 blocks
ratesB = np.array([manager_profit_rate(f,L,R_fixed,shock=shocks[t],params=params) for t in range(T)])
cumB = np.cumsum(ratesB)

# Scenario C: competitive rent updated each epoch (approx)
# we'll simulate repeated short epochs: manager obtains observed avg gross revenue and next epoch rent = (1 - eps)*observed_gross
epoch_len = 20
epochs = T // epoch_len
cumC = np.zeros(T)
total = 0.0
R = 0.01  # initial low rent
for e in range(epochs):
    start = e*epoch_len
    end = start + epoch_len
    # simulate per-block gross revenue (without rent)
    gross = np.array([ f*H0(f,L,params['h0'],params['b'],params['alpha']) +
                       AP0_zero(L,params['a0'],params['beta'],shock=0.0) - AE0(f,L,params['a0'],params['d'],params['beta'])
                      for _ in range(epoch_len) ])
    # manager gets gross - rent each block
    net = gross - R
    cumC[start:end] = net + (total if start==0 else cumC[start-1])
    total = cumC[end-1]
    # update rent for next epoch as (1 - take) * avg_gross (competitive)
    avg_gross = np.mean(gross)
    R = 0.95 * avg_gross   # auction extracts 95% of expected gross next epoch

# Plot results
plt.figure(figsize=(10,6))
plt.plot(cumA, label='Fixed env: cumulative profit')
plt.plot(cumB, label='With shocks: cumulative profit')
plt.plot(cumC, label='Competitive rent adjustment')
plt.xlabel('Block')
plt.ylabel('Cumulative profit per unit value')
plt.legend()
plt.grid(True)
plt.savefig('manager_profit_scenarios.png', dpi=300, bbox_inches='tight')
print("Graph saved as 'manager_profit_scenarios.png'")

print("Final cumulative profits:", cumA[-1], cumB[-1], cumC[-1])
