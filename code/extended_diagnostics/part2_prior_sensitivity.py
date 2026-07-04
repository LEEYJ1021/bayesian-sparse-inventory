"""
Prior sensitivity analysis (Referee 2, point 1).
Refit the hierarchical Normal model under several alternative hyperparameter
sets and compare posterior mu_c / tau2_c estimates to the paper's baseline
(mu0=9.147, tau0_sq=100, a_tau=b_tau=0.01, a_sig=b_sig=0.01).
"""
import numpy as np
import pandas as pd
from gibbs_sampler import prepare_data, run_gibbs

fact, item_to_cat, item_lookup, cat_lookup = prepare_data(min_n=3)
n_cats = item_to_cat.max() + 1
cat_names = [cat_lookup[c] for c in range(n_cats)]

specs = {
    'Baseline (paper)':        dict(mu0=9.147, tau0_sq=100.0, a_tau=0.01, b_tau=0.01, a_sig=0.01, b_sig=0.01),
    'Tight category prior':    dict(mu0=9.147, tau0_sq=1.0,   a_tau=0.01, b_tau=0.01, a_sig=0.01, b_sig=0.01),
    'Very diffuse (tau0=1000)':dict(mu0=9.147, tau0_sq=1000.0,a_tau=0.01, b_tau=0.01, a_sig=0.01, b_sig=0.01),
    'Informative tau2_c (IG(2,1))': dict(mu0=9.147, tau0_sq=100.0, a_tau=2.0, b_tau=1.0, a_sig=0.01, b_sig=0.01),
    'Informative sigma2 (IG(2,1))': dict(mu0=9.147, tau0_sq=100.0, a_tau=0.01, b_tau=0.01, a_sig=2.0, b_sig=1.0),
    'Shifted mu0 (=8.0)':      dict(mu0=8.0,   tau0_sq=100.0, a_tau=0.01, b_tau=0.01, a_sig=0.01, b_sig=0.01),
}

results_mu_c = {}
results_tau2_c = {}
results_sigma2 = {}

for label, hp in specs.items():
    res = run_gibbs(fact, item_to_cat, n_iter=800, burn=200, student_t=False, seed=7, **hp)
    results_mu_c[label] = res['mu_c'].mean(axis=0)
    results_tau2_c[label] = res['tau2_c'].mean(axis=0)
    results_sigma2[label] = res['sigma2'].mean()
    print(f"{label:35s} sigma2={res['sigma2'].mean():.4f}")

mu_c_df = pd.DataFrame(results_mu_c, index=cat_names).T
tau2_c_df = pd.DataFrame(results_tau2_c, index=cat_names).T
sigma2_series = pd.Series(results_sigma2, name='sigma2')

print("\n=== Posterior mean mu_c by category, across prior specifications ===")
print(mu_c_df.round(3).to_string())

print("\n=== Posterior mean tau2_c by category, across prior specifications ===")
print(tau2_c_df.round(3).to_string())

print("\n=== sigma2 across prior specifications ===")
print(sigma2_series.round(4).to_string())

# Compute max % deviation from baseline for each category (mu_c and tau2_c)
baseline_mu = mu_c_df.loc['Baseline (paper)']
baseline_tau2 = tau2_c_df.loc['Baseline (paper)']

pct_dev_mu = (mu_c_df.subtract(baseline_mu, axis=1)).abs().div(baseline_mu.abs(), axis=1) * 100
pct_dev_tau2 = (tau2_c_df.subtract(baseline_tau2, axis=1)).abs().div(baseline_tau2.abs(), axis=1) * 100

print("\n=== % deviation from baseline: mu_c ===")
print(pct_dev_mu.round(2).to_string())
print("\n=== % deviation from baseline: tau2_c ===")
print(pct_dev_tau2.round(2).to_string())

mu_c_df.to_csv("/home/claude/prior_sensitivity_mu_c.csv")
tau2_c_df.to_csv("/home/claude/prior_sensitivity_tau2_c.csv")
pct_dev_mu.to_csv("/home/claude/prior_sensitivity_pct_dev_mu.csv")
pct_dev_tau2.to_csv("/home/claude/prior_sensitivity_pct_dev_tau2.csv")
sigma2_series.to_csv("/home/claude/prior_sensitivity_sigma2.csv")

print("\nMax abs % deviation in mu_c across all non-baseline specs/categories:",
      round(pct_dev_mu.drop('Baseline (paper)').values.max(), 2), "%")
print("Max abs % deviation in tau2_c across all non-baseline specs/categories:",
      round(pct_dev_tau2.drop('Baseline (paper)').values.max(), 2), "%")
