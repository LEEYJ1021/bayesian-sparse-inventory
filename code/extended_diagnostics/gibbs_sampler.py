"""
Hierarchical Bayesian Gibbs Sampler — Normal / Student-t Observation Model
============================================================================
Re-implements the paper's Algorithm 4 (Gibbs sampler for the hierarchical
normal model) from scratch, using the actual fact_price_daily data, with an
added Student-t observation-model option (scale-mixture-of-normals
representation) so we can:
  (a) refit with Student-t likelihood and re-run posterior predictive checks,
  (b) run prior sensitivity analysis by varying hyperparameters,
  (c) run leave-some-items-out cross-sectional validation.

Model (Student-t is the Normal model with an extra latent weight w_ijt):
  Level 1: y_ijt | mu_i, sigma2, w_ijt ~ N(mu_i, sigma2 / w_ijt)
           w_ijt ~ Gamma(nu/2, nu/2)      [w=1 fixed recovers the Normal model]
  Level 2: mu_i | mu_c(i), tau2_c(i) ~ N(mu_c(i), tau2_c(i))
  Level 3: mu_c ~ N(mu0, tau0_sq); tau2_c ~ InvGamma(a_tau, b_tau); sigma2 ~ InvGamma(a_sig, b_sig)

Gibbs conditional updates (vectorized with pandas groupby):
  w_ijt        | rest ~ Gamma((nu+1)/2, (nu + (y-mu_i)^2/sigma2)/2)      [Student-t only]
  mu_i         | rest ~ N(mu_tilde_i, sigma2_tilde_i)   [precision-weighted combo of data + mu_c]
  mu_c         | rest ~ N(mu_tilde_c, tau0_tilde_c)     [as in paper Algorithm 4 step 2]
  tau2_c       | rest ~ InvGamma(a_tau + n_c/2, b_tau + 0.5 * sum (mu_i - mu_c)^2)
  sigma2       | rest ~ InvGamma(a_sig + N_w/2, b_sig + 0.5 * sum w_ijt*(y_ijt-mu_i)^2)
"""

import numpy as np
import pandas as pd

RNG = np.random.default_rng(2026)


def prepare_data(min_n=3, exclude_keys=None):
    """Load fact_price_daily, build item-market keys, log-transform, filter n>=min_n."""
    fact = pd.read_csv(
        "/home/claude/bayesian-sparse-inventory/data/processed/fact_price_daily_202601291929.csv"
    )
    fact['market_group'] = fact['mrkt_cd'].astype(str).str[:2]
    fact['item_key'] = fact['item_cd'].astype(str) + "_" + fact['market_group']
    fact['y'] = np.log(fact['price'] + 1)

    counts = fact.groupby('item_key').size()
    keep_keys = counts[counts >= min_n].index
    fact = fact[fact['item_key'].isin(keep_keys)].copy()

    if exclude_keys:
        fact = fact[~fact['item_key'].isin(exclude_keys)].copy()

    # integer ids
    item_map = {k: i for i, k in enumerate(sorted(fact['item_key'].unique()))}
    fact['item_id'] = fact['item_key'].map(item_map)

    cat_map = {k: i for i, k in enumerate(sorted(fact['ctgry_nm'].unique()))}
    fact['cat_id'] = fact['ctgry_nm'].map(cat_map)

    item_to_cat = fact.groupby('item_id')['cat_id'].first().values  # length n_items
    item_key_lookup = {v: k for k, v in item_map.items()}
    cat_key_lookup = {v: k for k, v in cat_map.items()}

    return fact, item_to_cat, item_key_lookup, cat_key_lookup


def run_gibbs(fact, item_to_cat, n_iter=800, burn=200,
              student_t=False, nu=4.0,
              mu0=9.147, tau0_sq=100.0,
              a_tau=0.01, b_tau=0.01,
              a_sig=0.01, b_sig=0.01,
              seed=2026):
    """
    Vectorized Gibbs sampler. Returns dict of posterior samples (post-burn-in):
      mu_i: array (n_kept_iter, n_items)
      mu_c: array (n_kept_iter, n_cats)
      tau2_c: array (n_kept_iter, n_cats)
      sigma2: array (n_kept_iter,)
    """
    rng = np.random.default_rng(seed)

    n_items = len(item_to_cat)
    n_cats = item_to_cat.max() + 1
    y = fact['y'].values
    item_id = fact['item_id'].values
    N = len(y)

    # per-item observation indices (for fast per-item aggregation)
    item_groups = [np.where(item_id == i)[0] for i in range(n_items)]
    n_ij = np.array([len(g) for g in item_groups])

    # init
    mu_i = np.array([y[g].mean() for g in item_groups])
    mu_c = np.array([mu_i[item_to_cat == c].mean() if np.any(item_to_cat == c) else mu0
                      for c in range(n_cats)])
    tau2_c = np.full(n_cats, 0.3)
    sigma2 = 0.15
    w = np.ones(N)

    keep_mu_i, keep_mu_c, keep_tau2_c, keep_sigma2 = [], [], [], []

    for it in range(n_iter):
        # --- Step 0 (Student-t only): sample weights ---
        if student_t:
            resid2 = (y - mu_i[item_id]) ** 2
            shape = (nu + 1) / 2
            rate = (nu + resid2 / sigma2) / 2
            w = rng.gamma(shape, 1.0 / rate)
        else:
            w = np.ones(N)

        # --- Step 1: sample mu_i for each item ---
        wy_sum = np.array([np.sum(w[g] * y[g]) for g in item_groups])
        w_sum = np.array([np.sum(w[g]) for g in item_groups])
        tau2_of_item = tau2_c[item_to_cat]
        mu_c_of_item = mu_c[item_to_cat]

        precision = w_sum / sigma2 + 1.0 / tau2_of_item
        mean_i = (wy_sum / sigma2 + mu_c_of_item / tau2_of_item) / precision
        var_i = 1.0 / precision
        mu_i = rng.normal(mean_i, np.sqrt(var_i))

        # --- Step 2: sample mu_c per category ---
        new_mu_c = mu_c.copy()
        for c in range(n_cats):
            idx = np.where(item_to_cat == c)[0]
            if len(idx) == 0:
                continue
            nc = len(idx)
            mu_bar_c = mu_i[idx].mean()
            denom = nc * tau0_sq + tau2_c[c]
            mu_tilde = (nc * tau0_sq * mu_bar_c + tau2_c[c] * mu0) / denom
            tau_tilde2 = (tau0_sq * tau2_c[c]) / denom
            new_mu_c[c] = rng.normal(mu_tilde, np.sqrt(tau_tilde2))
        mu_c = new_mu_c

        # --- Step 3: sample tau2_c per category ---
        new_tau2_c = tau2_c.copy()
        for c in range(n_cats):
            idx = np.where(item_to_cat == c)[0]
            if len(idx) == 0:
                continue
            nc = len(idx)
            ss = np.sum((mu_i[idx] - mu_c[c]) ** 2)
            a_t = a_tau + nc / 2
            b_t = b_tau + 0.5 * ss
            new_tau2_c[c] = 1.0 / rng.gamma(a_t, 1.0 / b_t)
        tau2_c = new_tau2_c
        tau2_c = np.clip(tau2_c, 1e-4, None)

        # --- Step 4: sample sigma2 (global) ---
        resid2 = (y - mu_i[item_id]) ** 2
        ss_sigma = np.sum(w * resid2)
        a_s = a_sig + N / 2
        b_s = b_sig + 0.5 * ss_sigma
        sigma2 = 1.0 / rng.gamma(a_s, 1.0 / b_s)

        if it >= burn:
            keep_mu_i.append(mu_i.copy())
            keep_mu_c.append(mu_c.copy())
            keep_tau2_c.append(tau2_c.copy())
            keep_sigma2.append(sigma2)

    return {
        'mu_i': np.array(keep_mu_i),
        'mu_c': np.array(keep_mu_c),
        'tau2_c': np.array(keep_tau2_c),
        'sigma2': np.array(keep_sigma2),
        'nu': nu,
        'student_t': student_t,
    }
