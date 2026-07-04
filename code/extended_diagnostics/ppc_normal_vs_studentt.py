"""
PPC comparison: Normal vs Student-t hierarchical observation model
=====================================================================
Fits both models via the custom Gibbs sampler (gibbs_sampler.py) on the full
554 item-market panel (n>=3), then runs the same posterior-predictive-check
protocol as before (mean, sd, skew, min, max Bayesian p-values) for each,
to see whether the Student-t model resolves the skewness miscalibration
found in the original normal-model PPC.
"""
import numpy as np
import pandas as pd
from scipy import stats as sstats
from gibbs_sampler import prepare_data, run_gibbs

RNG = np.random.default_rng(99)


def test_stats(x):
    return {
        'mean': np.mean(x), 'sd': np.std(x, ddof=1) if len(x) > 1 else np.nan,
        'skew': sstats.skew(x) if len(x) > 2 else np.nan,
        'min': np.min(x), 'max': np.max(x),
    }


def run_ppc(fact, item_to_cat, gibbs_result, n_sim_draws=300):
    """For each item, simulate replicate datasets from posterior draws and compute p_B."""
    item_id = fact['item_id'].values
    y = fact['y'].values
    n_items = len(item_to_cat)
    item_groups = [np.where(item_id == i)[0] for i in range(n_items)]

    mu_i_draws = gibbs_result['mu_i']       # (n_iter, n_items)
    sigma2_draws = gibbs_result['sigma2']   # (n_iter,)
    student_t = gibbs_result['student_t']
    nu = gibbs_result['nu']
    n_avail = mu_i_draws.shape[0]

    draw_idx = RNG.choice(n_avail, size=min(n_sim_draws, n_avail), replace=False)

    results = []
    for i, g in enumerate(item_groups):
        n_obs = len(g)
        if n_obs < 3:
            continue
        obs = y[g]
        obs_stats = test_stats(obs)

        rep_stats = {k: [] for k in obs_stats}
        for s in draw_idx:
            mu = mu_i_draws[s, i]
            sigma = np.sqrt(sigma2_draws[s])
            if student_t:
                y_rep = mu + sigma * RNG.standard_t(nu, size=n_obs)
            else:
                y_rep = RNG.normal(mu, sigma, size=n_obs)
            rs = test_stats(y_rep)
            for k in rep_stats:
                rep_stats[k].append(rs[k])

        row = {'item_id': i, 'n_obs': n_obs}
        for k in rep_stats:
            arr = np.array(rep_stats[k])
            row[f'p_{k}'] = np.mean(arr >= obs_stats[k])
        results.append(row)

    return pd.DataFrame(results)


def summarize(ppc_df, label):
    print(f"\n=== {label} ===")
    rows = []
    for stat in ['mean', 'sd', 'skew', 'min', 'max']:
        col = f'p_{stat}'
        p = ppc_df[col].dropna()
        extreme = ((p < 0.05) | (p > 0.95)).mean() * 100
        adequate = ((p >= 0.10) & (p <= 0.90)).mean() * 100
        rows.append({'stat': stat, 'median_pB': round(p.median(), 3),
                      'pct_extreme': round(extreme, 1), 'pct_adequate': round(adequate, 1)})
        print(f"  T={stat:5s} median p_B={p.median():.3f}  extreme={extreme:5.1f}%  adequate={adequate:5.1f}%")
    return pd.DataFrame(rows)


if __name__ == "__main__":
    fact, item_to_cat, item_lookup, cat_lookup = prepare_data(min_n=3)

    print("Fitting Normal hierarchical model...")
    res_normal = run_gibbs(fact, item_to_cat, n_iter=800, burn=200, student_t=False, seed=1)
    print("Fitting Student-t hierarchical model (nu=4)...")
    res_t = run_gibbs(fact, item_to_cat, n_iter=800, burn=200, student_t=True, nu=4.0, seed=1)

    ppc_normal = run_ppc(fact, item_to_cat, res_normal)
    ppc_t = run_ppc(fact, item_to_cat, res_t)

    summary_normal = summarize(ppc_normal, "NORMAL model (refit on all 554 pairs)")
    summary_t = summarize(ppc_t, "STUDENT-T model (nu=4, refit on all 554 pairs)")

    comparison = summary_normal.merge(summary_t, on='stat', suffixes=('_normal', '_studentt'))
    print("\n=== COMPARISON ===")
    print(comparison.to_string(index=False))

    comparison.to_csv("/home/claude/ppc_normal_vs_studentt.csv", index=False)
    ppc_normal.to_csv("/home/claude/ppc_normal_full554.csv", index=False)
    ppc_t.to_csv("/home/claude/ppc_studentt_full554.csv", index=False)
