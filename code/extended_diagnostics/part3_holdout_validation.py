"""
Leave-some-items-out cross-sectional validation (Referee 2, point 4).

Design
------
For each category, randomly hold out ~20% of item-market pairs. Refit the
hierarchical Gibbs sampler using ONLY the remaining (~80%) items, so held-out
items contribute zero information to mu_c, tau2_c, or sigma2. Held-out items
are then treated as brand-new, never-seen items: for each posterior draw
(mu_c^(s), tau2_c^(s), sigma2^(s)), simulate what a new item in that category
would look like:
    mu_new^(s) ~ N(mu_c^(s), tau2_c^(s))          [category-level prediction]
    y_new^(s)  ~ N(mu_new^(s), sigma2^(s))
This is compared against:
  (a) the ACTUAL observed data of the held-out item (coverage / calibration)
  (b) a "complete pooling" benchmark that ignores category structure
      (draws mu_new from a single global N(mu_grand, tau2_grand))

Metrics
-------
- 90% posterior predictive interval coverage for the held-out item's sample mean
- Posterior predictive p-value calibration (same p_B logic as PPC)
- RMSE of category-mean prediction (mu_c posterior mean) vs held-out item's
  actual sample mean, compared between Hierarchical vs Complete Pooling
"""
import numpy as np
import pandas as pd
from gibbs_sampler import prepare_data, run_gibbs

RNG = np.random.default_rng(2026)


def make_holdout_split(fact, item_to_cat, frac=0.2, seed=42):
    rng = np.random.default_rng(seed)
    n_items = len(item_to_cat)
    held_out = np.zeros(n_items, dtype=bool)
    for c in np.unique(item_to_cat):
        idx = np.where(item_to_cat == c)[0]
        n_hold = max(1, int(round(len(idx) * frac)))
        chosen = rng.choice(idx, size=n_hold, replace=False)
        held_out[chosen] = True
    return held_out


def refit_excluding(fact, item_to_cat, held_out_item_ids, **kwargs):
    """Refit gibbs sampler using only observations from non-held-out items."""
    mask = ~fact['item_id'].isin(held_out_item_ids)
    fact_train = fact[mask].copy()
    # item_to_cat indexed by original item_id; keep same indexing, just don't
    # feed held-out items' rows into the sampler. Held-out items will simply
    # have zero observations -> item_groups for them will be empty; need to
    # handle that in run_gibbs by skipping mu_i update reliance on data (fine,
    # since precision will just be 1/tau2_of_item with wy_sum=0/w_sum=0->nan).
    # To avoid this, we restrict n_items to only trained items for mu_i level,
    # but still need per-category tau2_c/mu_c estimated from trained items only.
    return fact_train


if __name__ == "__main__":
    fact, item_to_cat, item_lookup, cat_lookup = prepare_data(min_n=3)
    n_items_all = len(item_to_cat)
    n_cats = item_to_cat.max() + 1

    held_out_mask = make_holdout_split(fact, item_to_cat, frac=0.2, seed=42)
    held_out_ids = np.where(held_out_mask)[0]
    train_ids = np.where(~held_out_mask)[0]
    print(f"Total items: {n_items_all}, held out: {len(held_out_ids)}, train: {len(train_ids)}")

    # --- Build a TRAIN-ONLY dataset with re-indexed item ids (0..n_train-1) ---
    fact_train_raw = fact[fact['item_id'].isin(train_ids)].copy()
    old_to_new = {old: new for new, old in enumerate(sorted(train_ids))}
    fact_train_raw['item_id_train'] = fact_train_raw['item_id'].map(old_to_new)
    item_to_cat_train = np.array([item_to_cat[old] for old in sorted(train_ids)])

    fact_train = fact_train_raw.rename(columns={'item_id': 'item_id_orig'})
    fact_train['item_id'] = fact_train['item_id_train']

    print("Fitting hierarchical model on TRAIN items only (held-out items excluded entirely)...")
    res_train = run_gibbs(fact_train, item_to_cat_train, n_iter=1000, burn=300, student_t=False, seed=11)

    mu_c_draws = res_train['mu_c']       # (n_iter, n_cats)
    tau2_c_draws = res_train['tau2_c']   # (n_iter, n_cats)
    sigma2_draws = res_train['sigma2']   # (n_iter,)
    n_draws = mu_c_draws.shape[0]

    # --- Complete-pooling benchmark: single global mu_grand / tau2_grand from TRAIN data ---
    # refit with a single-category assignment (all items forced into cat 0)
    item_to_cat_pooled = np.zeros(len(train_ids), dtype=int)
    print("Fitting COMPLETE POOLING benchmark (single global category) on TRAIN items...")
    res_pooled = run_gibbs(fact_train, item_to_cat_pooled, n_iter=1000, burn=300, student_t=False, seed=11)
    mu_grand_draws = res_pooled['mu_c'][:, 0]
    tau2_grand_draws = res_pooled['tau2_c'][:, 0]
    sigma2_pooled_draws = res_pooled['sigma2']

    # --- Evaluate on HELD-OUT items ---
    y = fact['y'].values
    item_id_full = fact['item_id'].values
    n_sim = 500
    draw_idx = RNG.choice(n_draws, size=n_sim, replace=False)

    results = []
    for i in held_out_ids:
        c = item_to_cat[i]
        obs = y[item_id_full == i]
        n_obs = len(obs)
        obs_mean = obs.mean()

        # Hierarchical: simulate a "new item" in category c
        hier_new_item_means = []
        hier_pB_samples = []
        for s in draw_idx:
            mu_new = RNG.normal(mu_c_draws[s, c], np.sqrt(tau2_c_draws[s, c]))
            hier_new_item_means.append(mu_new)
            y_rep = RNG.normal(mu_new, np.sqrt(sigma2_draws[s]), size=n_obs)
            hier_pB_samples.append(y_rep.mean())
        hier_new_item_means = np.array(hier_new_item_means)
        hier_pB_samples = np.array(hier_pB_samples)

        # Complete pooling: simulate a "new item" globally (no category info)
        pooled_new_item_means = []
        pooled_pB_samples = []
        for s in draw_idx:
            mu_new = RNG.normal(mu_grand_draws[s], np.sqrt(tau2_grand_draws[s]))
            pooled_new_item_means.append(mu_new)
            y_rep = RNG.normal(mu_new, np.sqrt(sigma2_pooled_draws[s]), size=n_obs)
            pooled_pB_samples.append(y_rep.mean())
        pooled_new_item_means = np.array(pooled_new_item_means)
        pooled_pB_samples = np.array(pooled_pB_samples)

        # 90% predictive interval coverage (of the item's own sample mean) for each method
        hier_lo, hier_hi = np.percentile(hier_pB_samples, [5, 95])
        pooled_lo, pooled_hi = np.percentile(pooled_pB_samples, [5, 95])

        hier_covered = hier_lo <= obs_mean <= hier_hi
        pooled_covered = pooled_lo <= obs_mean <= pooled_hi

        # posterior predictive p-value (calibration): fraction of replicate means >= obs mean
        hier_pB = np.mean(hier_pB_samples >= obs_mean)
        pooled_pB = np.mean(pooled_pB_samples >= obs_mean)

        # point prediction error: category mean (hier) vs global mean (pooled) vs actual
        hier_point_pred = mu_c_draws[:, c].mean()
        pooled_point_pred = mu_grand_draws.mean()

        results.append({
            'item_id': i, 'category': cat_lookup[c], 'n_obs': n_obs,
            'obs_mean': obs_mean,
            'hier_point_pred': hier_point_pred, 'pooled_point_pred': pooled_point_pred,
            'hier_abs_err': abs(hier_point_pred - obs_mean),
            'pooled_abs_err': abs(pooled_point_pred - obs_mean),
            'hier_ci90_lo': hier_lo, 'hier_ci90_hi': hier_hi, 'hier_covered_90': hier_covered,
            'pooled_ci90_lo': pooled_lo, 'pooled_ci90_hi': pooled_hi, 'pooled_covered_90': pooled_covered,
            'hier_pB': hier_pB, 'pooled_pB': pooled_pB,
        })

    res_df = pd.DataFrame(results)

    print("\n" + "=" * 70)
    print("LEAVE-SOME-ITEMS-OUT VALIDATION RESULTS")
    print("=" * 70)
    print(f"N held-out items: {len(res_df)}")
    print(f"\n90% CI coverage -- Hierarchical (category-pooled): {res_df['hier_covered_90'].mean()*100:.1f}%")
    print(f"90% CI coverage -- Complete pooling (global):        {res_df['pooled_covered_90'].mean()*100:.1f}%")
    print(f"(Nominal target: 90%)")

    print(f"\nMean abs error (log-price units) -- Hierarchical: {res_df['hier_abs_err'].mean():.4f}")
    print(f"Mean abs error (log-price units) -- Complete pooling: {res_df['pooled_abs_err'].mean():.4f}")
    rmse_hier = np.sqrt((res_df['hier_abs_err']**2).mean())
    rmse_pooled = np.sqrt((res_df['pooled_abs_err']**2).mean())
    print(f"RMSE -- Hierarchical: {rmse_hier:.4f}   Complete pooling: {rmse_pooled:.4f}")
    improvement = (rmse_pooled - rmse_hier) / rmse_pooled * 100
    print(f"RMSE improvement of Hierarchical over Complete Pooling: {improvement:.1f}%")

    print(f"\nCalibration (pB median, should be near 0.5) -- Hierarchical: {res_df['hier_pB'].median():.3f}")
    print(f"Calibration (pB median, should be near 0.5) -- Complete pooling: {res_df['pooled_pB'].median():.3f}")

    print("\n--- By category ---")
    by_cat = res_df.groupby('category').agg(
        n=('item_id', 'count'),
        hier_coverage=('hier_covered_90', 'mean'),
        pooled_coverage=('pooled_covered_90', 'mean'),
        hier_rmse=('hier_abs_err', lambda x: np.sqrt((x**2).mean())),
        pooled_rmse=('pooled_abs_err', lambda x: np.sqrt((x**2).mean())),
    ).round(3)
    print(by_cat.to_string())

    res_df.to_csv("/home/claude/holdout_validation_item_level.csv", index=False)
    by_cat.to_csv("/home/claude/holdout_validation_by_category.csv")

    summary = pd.DataFrame({
        'Metric': ['N held-out items', '90% CI coverage (%)', 'RMSE (log-price)', 'Median p_B'],
        'Hierarchical': [len(res_df), round(res_df['hier_covered_90'].mean()*100, 1),
                          round(rmse_hier, 4), round(res_df['hier_pB'].median(), 3)],
        'Complete Pooling': [len(res_df), round(res_df['pooled_covered_90'].mean()*100, 1),
                             round(rmse_pooled, 4), round(res_df['pooled_pB'].median(), 3)],
    })
    summary.to_csv("/home/claude/holdout_validation_summary.csv", index=False)
    print("\n" + summary.to_string(index=False))
