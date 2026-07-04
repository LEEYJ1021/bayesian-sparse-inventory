# h1_volatility_heterogeneity_FIXED.R
# H1 (paper's H2): Category-Specific Price Volatility Heterogeneity
# Kruskal-Wallis + Quantile Regression
#
# FIX LOG (vs original h1_volatility_heterogeneity.R):
#   1. Original grouped volatility_data by (item_cd, ctgry_cd, ctgry_nm) only,
#      completely ignoring market_cd. This computed CV at the ITEM level (86 items
#      survive), not the ITEM-MARKET level (554 pairs) that Table 2/3 and the rest
#      of the paper use as the unit of analysis.
#   2. Original filtered on n_obs >= 5. Paper text (Section 4, Table 3, Table 6)
#      states the sparsity threshold is n >= 3. This mismatch further explains why
#      Table 11 numbers don't reconcile with Table 2/3.
#   3. Consequence: Livestock (축산물, 7 items in Table 2) silently drops out of
#      Table 11 / Figure 4 because none of its items individually clear n>=5 when
#      aggregated across ALL markets combined. This must now be reported explicitly.
#
# This corrected version groups by (item_cd, market_group, ctgry_cd, ctgry_nm),
# where market_group = first 2 digits of mrkt_cd (regional market code) -- the
# SAME definition used in metadata_hierarchical_structure_*.csv -- and filters
# n_obs >= 3, reproducing the 554 item-market pairs reported in Table 3.

library(data.table)
library(ggplot2)
library(quantreg)
library(e1071)

# ========== Load and Prepare Data (CORRECTED) ==========
prepare_volatility_data <- function() {
  cat("Loading and preparing data (CORRECTED item-market unit, n>=3)...\n")

  fact_price <- fread("data/processed/fact_price_daily_202601291929.csv")

  # CORRECTED: derive market_group exactly as in metadata_hierarchical_structure
  fact_price[, market_group := substr(as.character(mrkt_cd), 1, 2)]

  # NOTE: If Algorithm 11 (IQR-based outlier removal, +/-3*IQR per item-market pair)
  # has already been applied upstream to produce fact_price_daily, no further action
  # needed here. If not, apply it BEFORE this aggregation step so all downstream
  # tables (Table 3, 10, 11) are computed on the identical filtered dataset:
  #
  # fact_price[, `:=`(Q1 = quantile(price, 0.25), Q3 = quantile(price, 0.75)),
  #            by = .(item_cd, market_group)]
  # fact_price[, IQR := Q3 - Q1]
  # fact_price <- fact_price[price >= (Q1 - 3*IQR) & price <= (Q3 + 3*IQR)]

  # CORRECTED: group by item_cd AND market_group (item-market pair), not item alone
  volatility_data <- fact_price[, .(
    mean_price = mean(price, na.rm = TRUE),
    sd_price = sd(price, na.rm = TRUE),
    n_obs = .N
  ), by = .(item_cd, market_group, ctgry_cd, ctgry_nm)]

  volatility_data[, cv_price := sd_price / mean_price]
  volatility_data[, log_cv := log(cv_price + 0.01)]

  # CORRECTED: n_obs >= 3 (matches Table 3 / Table 6 threshold stated in the paper)
  volatility_data <- volatility_data[is.finite(cv_price) & cv_price > 0 & n_obs >= 3]

  cat(sprintf("Data prepared: %d item-market pairs (target: 554 per Table 3)\n",
              nrow(volatility_data)))
  cat(sprintf("Categories represented: %d (check whether all 7 from Table 2 appear)\n",
              uniqueN(volatility_data$ctgry_nm)))

  return(volatility_data)
}

# ========== H2: Kruskal-Wallis Test ==========
test_kruskal_wallis <- function(volatility_data) {
  cat("\nH2 (CORRECTED): Kruskal-Wallis Test for Volatility Heterogeneity\n")
  cat(strrep("=", 70), "\n")

  kw_test <- kruskal.test(cv_price ~ ctgry_nm, data = volatility_data)

  # Standard eta-squared for Kruskal-Wallis: (H - k + 1) / (n - k)
  k <- uniqueN(volatility_data$ctgry_nm)
  n <- nrow(volatility_data)
  eta_squared <- (kw_test$statistic - k + 1) / (n - k)

  cat(sprintf("Kruskal-Wallis H-statistic: %.2f\n", kw_test$statistic))
  cat(sprintf("Degrees of Freedom: %d\n", kw_test$parameter))
  cat(sprintf("p-value: %.3e\n", kw_test$p.value))
  cat(sprintf("Effect Size (eta^2): %.4f\n", eta_squared))

  effect_label <- if (eta_squared < 0.01) "small" else if (eta_squared < 0.06) "medium" else "large"
  cat(sprintf("Effect Size Interpretation: %s effect\n", effect_label))

  return(list(h_statistic = kw_test$statistic, df = kw_test$parameter,
              p_value = kw_test$p.value, eta_squared = eta_squared))
}

# ========== Category-Level Statistics (CORRECTED Table 11) ==========
calculate_category_stats <- function(volatility_data) {
  cat("\nCategory-Level Volatility Statistics (CORRECTED Table 11)\n")
  cat(strrep("=", 70), "\n")

  category_stats <- volatility_data[, .(
    n_items = .N,
    median_cv = median(cv_price, na.rm = TRUE),
    mean_cv = mean(cv_price, na.rm = TRUE),
    sd_cv = sd(cv_price, na.rm = TRUE),
    iqr_cv = IQR(cv_price, na.rm = TRUE),
    q10 = quantile(cv_price, 0.10, na.rm = TRUE),
    q90 = quantile(cv_price, 0.90, na.rm = TRUE),
    skewness = skewness(cv_price, na.rm = TRUE),
    kurtosis = kurtosis(cv_price, na.rm = TRUE)
  ), by = ctgry_nm]

  category_stats <- category_stats[order(-median_cv)]
  print(category_stats)

  cat(sprintf("\nSum of n_items across categories: %d (should equal item-market total, e.g. 554)\n",
              sum(category_stats$n_items)))

  # Explicit Livestock check
  all_cats <- fread("data/processed/metadata_item_catalog_202601291929.csv")[, unique(ctgry_nm)]
  missing_cats <- setdiff(all_cats, category_stats$ctgry_nm)
  if (length(missing_cats) > 0) {
    cat(sprintf("\nWARNING: category present in Table 2 but ABSENT here (0 pairs with n>=3): %s\n",
                paste(missing_cats, collapse = ", ")))
    cat("This must be reported explicitly in the paper (table footnote + Section 5.2.2 text),\n")
    cat("not silently omitted as in the original submission.\n")
  }

  max_cv <- max(category_stats$median_cv); min_cv <- min(category_stats$median_cv)
  cat(sprintf("\nVolatility ratio (corrected): %.1f-fold (%s vs %s)\n",
              max_cv / min_cv,
              category_stats$ctgry_nm[which.max(category_stats$median_cv)],
              category_stats$ctgry_nm[which.min(category_stats$median_cv)]))

  return(category_stats)
}

# ========== Quantile Regression (unchanged logic, corrected data) ==========
perform_quantile_regression <- function(volatility_data, quantiles = c(0.10, 0.25, 0.50, 0.75, 0.90)) {
  cat("\nQuantile Regression Analysis (CORRECTED data)\n")
  cat(strrep("=", 70), "\n")

  qr_results <- data.table()
  for (tau in quantiles) {
    qr_model <- rq(log_cv ~ ctgry_nm, tau = tau, data = volatility_data)
    qr_summary <- summary(qr_model, se = "boot")
    coefs <- qr_summary$coefficients
    category_names <- rownames(coefs)[-1]
    for (i in seq_along(category_names)) {
      cat_name <- gsub("ctgry_nm", "", category_names[i])
      qr_results <- rbind(qr_results, data.table(
        quantile = tau, category = cat_name,
        coefficient = coefs[i + 1, "Value"], se = coefs[i + 1, "Std. Error"],
        ci_lower = coefs[i + 1, "Value"] - 1.96 * coefs[i + 1, "Std. Error"],
        ci_upper = coefs[i + 1, "Value"] + 1.96 * coefs[i + 1, "Std. Error"]
      ))
    }
  }
  return(qr_results)
}

# ========== Pairwise Comparisons ==========
perform_pairwise_tests <- function(volatility_data) {
  cat("\nPairwise Comparisons (Wilcoxon with Bonferroni), CORRECTED data\n")
  cat(strrep("=", 70), "\n")

  pairwise_results <- pairwise.wilcox.test(
    volatility_data$cv_price, volatility_data$ctgry_nm, p.adjust.method = "bonferroni"
  )
  p_matrix <- pairwise_results$p.value
  n_comparisons <- sum(!is.na(p_matrix))
  n_significant <- sum(p_matrix < 0.05, na.rm = TRUE)
  cat(sprintf("Total pairwise comparisons: %d\n", n_comparisons))
  cat(sprintf("Significant (p < 0.05): %d (%.1f%%)\n",
              n_significant, n_significant / n_comparisons * 100))
  return(pairwise_results)
}

# ========== Main ==========
main_h1_analysis_fixed <- function() {
  cat("\n", strrep("=", 80), "\n")
  cat("H2 (CORRECTED): CATEGORY-SPECIFIC PRICE VOLATILITY HETEROGENEITY\n")
  cat(strrep("=", 80), "\n\n")

  volatility_data <- prepare_volatility_data()
  kw_results <- test_kruskal_wallis(volatility_data)
  category_stats <- calculate_category_stats(volatility_data)
  qr_results <- perform_quantile_regression(volatility_data)
  pairwise_results <- perform_pairwise_tests(volatility_data)

  dir.create("results", showWarnings = FALSE)
  fwrite(volatility_data, "results/h1_volatility_data_FIXED.csv")
  fwrite(category_stats, "results/h1_category_statistics_FIXED.csv")
  fwrite(qr_results, "results/h1_quantile_regression_FIXED.csv")

  cat("\nH2 (corrected) analysis completed. Compare results/h1_*_FIXED.csv against\n")
  cat("the original results/h1_*.csv to quantify the impact of the unit-of-analysis fix.\n")

  return(list(kw = kw_results, category_stats = category_stats, qr = qr_results))
}

if (!interactive()) {
  h1_results_fixed <- main_h1_analysis_fixed()
}
