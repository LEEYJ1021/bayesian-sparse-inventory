"""
Posterior Predictive Check (PPC) for the Hierarchical Bayesian Model
=====================================================================
Addresses Referee 2's comment:
  "Posterior distributions of the model parameters (and their credible intervals),
   prior sensitivity analyses..., and posterior predictive checks (e.g., predictive
   intervals) are not shown. Therefore, the Bayesian component often appears more
   as a computational tool for shrinkage estimation than as a fully developed
   framework for uncertainty quantification."

This script uses the ACTUAL stored MCMC posterior draws (mu, sigma; 1000 draws x
255 item-market pairs, the "moderate sparsity" 10<=n<20 tier estimated via Gibbs
sampling) to generate posterior predictive replicate datasets and compare them
against the observed log-price data for each item-market pair, following the
standard Bayesian PPC framework (Gelman et al. 1996; Gelman & Hill 2007).

Method
------
For item-market pair (i,j) with n_ij observed log-prices y_ij and posterior draws
{(mu^(s), sigma^(s))}_{s=1..S}:
  1. For each posterior draw s, simulate a replicate dataset y_rep^(s) of size n_ij
     from N(mu^(s), sigma^(s)).
  2. Compute a discrepancy/test statistic T(.) on both observed and replicated data:
       - mean, sd, skewness, min, max
  3. Bayesian posterior predictive p-value:
       p_B = (1/S) * sum_s [ T(y_rep^(s)) >= T(y_obs) ]
     A well-calibrated model has p_B away from the extremes (0 or 1) for most items;
     systematic clustering near 0 or 1 indicates model misfit for that statistic.
"""

import pandas as pd
import numpy as np
from scipy import stats as sstats

np.random.seed(42)

DATA_DIR = "/home/claude/bayesian-sparse-inventory/data/processed"

# ---------- Load posterior draws (MCMC tier only, 10<=n<20) ----------
post = pd.read_csv("/home/claude/bayesian_posterior_samples_202601291929.csv")
post['market_group'] = post['market_group'].astype(str)

mu_df = post[post.parameter_name == 'mu'][['item_cd', 'market_group', 'iteration', 'sample_value']]
mu_df = mu_df.rename(columns={'sample_value': 'mu'})
sig_df = post[post.parameter_name == 'sigma'][['item_cd', 'market_group', 'iteration', 'sample_value']]
sig_df = sig_df.rename(columns={'sample_value': 'sigma'})

draws = mu_df.merge(sig_df, on=['item_cd', 'market_group', 'iteration'])
print(f"Loaded posterior draws: {draws.shape[0]} rows, "
      f"{draws[['item_cd','market_group']].drop_duplicates().shape[0]} item-market pairs, "
      f"{draws['iteration'].nunique()} draws/pair")

# ---------- Load observed data, log-transform (Eq. 1 in paper: y' = ln(price+1)) ----------
fact = pd.read_csv(f"{DATA_DIR}/fact_price_daily_202601291929.csv")
fact['market_group'] = fact['mrkt_cd'].astype(str).str[:2]
fact['log_price'] = np.log(fact['price'] + 1)

# ---------- Run PPC per item-market pair ----------
def test_stats(x):
    return {
        'mean': np.mean(x),
        'sd': np.std(x, ddof=1) if len(x) > 1 else np.nan,
        'skew': sstats.skew(x) if len(x) > 2 else np.nan,
        'min': np.min(x),
        'max': np.max(x),
    }

pairs = draws[['item_cd', 'market_group']].drop_duplicates()
results = []

for _, row in pairs.iterrows():
    item, mg = row['item_cd'], row['market_group']
    obs = fact[(fact.item_cd == item) & (fact.market_group == mg)]['log_price'].values
    n_obs = len(obs)
    if n_obs < 3:
        continue
    obs_stats = test_stats(obs)

    pd_draws = draws[(draws.item_cd == item) & (draws.market_group == mg)]
    mus = pd_draws['mu'].values
    sigmas = pd_draws['sigma'].values
    S = len(mus)

    rep_stats = {'mean': [], 'sd': [], 'skew': [], 'min': [], 'max': []}
    for s in range(S):
        y_rep = np.random.normal(mus[s], sigmas[s], size=n_obs)
        rs = test_stats(y_rep)
        for k in rep_stats:
            rep_stats[k].append(rs[k])

    row_result = {'item_cd': item, 'market_group': mg, 'n_obs': n_obs}
    for k in rep_stats:
        rep_arr = np.array(rep_stats[k])
        p_bayes = np.mean(rep_arr >= obs_stats[k])
        row_result[f'p_{k}'] = p_bayes
        row_result[f'obs_{k}'] = obs_stats[k]
    results.append(row_result)

ppc_df = pd.DataFrame(results)
print(f"\nPPC computed for {len(ppc_df)} item-market pairs")

# ---------- Summarize calibration ----------
print("\n" + "=" * 70)
print("POSTERIOR PREDICTIVE CHECK SUMMARY")
print("=" * 70)

for stat in ['mean', 'sd', 'skew', 'min', 'max']:
    col = f'p_{stat}'
    p = ppc_df[col].dropna()
    extreme = ((p < 0.05) | (p > 0.95)).mean() * 100
    well_calibrated = ((p >= 0.10) & (p <= 0.90)).mean() * 100
    print(f"T = {stat:5s} | median p_B = {p.median():.3f} | "
          f"% extreme (p<.05 or p>.95) = {extreme:5.1f}% | "
          f"% well-calibrated (.10-.90) = {well_calibrated:5.1f}%")

# ---------- Overall verdict table (for paper) ----------
summary_table = []
for stat in ['mean', 'sd', 'skew', 'min', 'max']:
    col = f'p_{stat}'
    p = ppc_df[col].dropna()
    summary_table.append({
        'Test statistic T(y)': stat,
        'N items': len(p),
        'Median p_B': round(p.median(), 3),
        'Mean p_B': round(p.mean(), 3),
        '% extreme (p<0.05 or >0.95)': round(((p < 0.05) | (p > 0.95)).mean() * 100, 1),
        '% adequate (0.10-0.90)': round(((p >= 0.10) & (p <= 0.90)).mean() * 100, 1),
    })
summary_df = pd.DataFrame(summary_table)
print("\n" + summary_df.to_string(index=False))

# ---------- Save outputs ----------
ppc_df.to_csv("/home/claude/ppc_item_level_results.csv", index=False)
summary_df.to_csv("/home/claude/ppc_summary_table.csv", index=False)

# ---------- Distribution of p_B for mean and sd (should be ~Uniform(0,1) if well calibrated) ----------
print("\n" + "=" * 70)
print("Distribution of p_B(mean) across deciles (diagnostic for uniformity):")
print(pd.cut(ppc_df['p_mean'], bins=np.arange(0, 1.1, 0.1)).value_counts().sort_index())
