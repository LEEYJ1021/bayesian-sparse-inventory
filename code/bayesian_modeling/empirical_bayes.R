# empirical_bayes.R
# James-Stein Shrinkage Estimators for Extreme Sparsity (n < 10)

library(data.table)

# ========== Empirical Bayes Estimation ==========
empirical_bayes_shrinkage <- function(df) {
  cat("🔄 Running Empirical Bayes estimation...\n")
  
  # Calculate item-level means
  item_stats <- df[, .(
    y_bar = mean(log_price, na.rm = TRUE),
    n = .N,
    s2 = var(log_price, na.rm = TRUE)
  ), by = item_cd]
  
  # Calculate category-level hyperparameters
  category_means <- df[, .(
    mu_c = mean(log_price, na.rm = TRUE),
    n_items = uniqueN(item_cd)
  ), by = ctgry_cd]
  
  # Estimate global variance
  sigma2_hat <- mean(item_stats$s2, na.rm = TRUE)
  
  # Estimate between-item variance
  grand_mean <- mean(df$log_price, na.rm = TRUE)
  tau2_hat <- var(item_stats$y_bar, na.rm = TRUE) - sigma2_hat / mean(item_stats$n)
  tau2_hat <- max(tau2_hat, 0)  # Ensure non-negative
  
  # Calculate shrinkage weights
  item_stats[, lambda := sigma2_hat / (n * tau2_hat + sigma2_hat)]
  
  # Merge category means
  item_stats <- merge(item_stats, category_means, by.x = "item_cd", by.y = "ctgry_cd", all.x = TRUE)
  
  # Empirical Bayes estimator
  item_stats[, mu_eb := (1 - lambda) * y_bar + lambda * mu_c]
  
  # Posterior variance approximation
  item_stats[, post_var := lambda * sigma2_hat / n]
  
  cat("✅ Empirical Bayes estimation completed\n")
  cat(sprintf("  - Global variance (σ²): %.4f\n", sigma2_hat))
  cat(sprintf("  - Between-item variance (τ²): %.4f\n", tau2_hat))
  cat(sprintf("  - Average shrinkage weight (λ): %.4f\n", mean(item_stats$lambda, na.rm = TRUE)))
  
  return(item_stats)
}

# ========== Example Usage ==========
if (!interactive()) {
  fact_price <- fread("data/processed/fact_price_daily_202601291929.csv")
  fact_price[, log_price := log(price + 1)]
  
  # Filter sparse items (3 <= n < 10)
  sparse_items <- fact_price[, .N, by = item_cd][N >= 3 & N < 10, item_cd]
  sparse_data <- fact_price[item_cd %in% sparse_items]
  
  eb_results <- empirical_bayes_shrinkage(sparse_data)
  fwrite(eb_results, "results/empirical_bayes_estimates.csv")
  
  cat("\n💾 Results saved to results/empirical_bayes_estimates.csv\n")
}