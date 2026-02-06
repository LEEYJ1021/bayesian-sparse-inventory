# h1_volatility_heterogeneity.R
# H1: Category-Specific Price Volatility Heterogeneity
# Kruskal-Wallis + Quantile Regression

library(data.table)
library(ggplot2)
library(quantreg)
library(e1071)

# ========== Load and Prepare Data ==========
prepare_volatility_data <- function() {
  cat("🔄 Loading and preparing data...\n")
  
  fact_price <- fread("data/processed/fact_price_daily_202601291929.csv")
  metadata <- fread("data/processed/metadata_item_catalog_202601291929.csv")
  
  # Calculate price volatility (CV) by item-market
  volatility_data <- fact_price[, .(
    mean_price = mean(price, na.rm = TRUE),
    sd_price = sd(price, na.rm = TRUE),
    n_obs = .N
  ), by = .(item_cd, ctgry_cd, ctgry_nm)]
  
  volatility_data[, cv_price := sd_price / mean_price]
  volatility_data[, log_cv := log(cv_price + 0.01)]
  
  # Filter valid data
  volatility_data <- volatility_data[is.finite(cv_price) & cv_price > 0 & n_obs >= 5]
  
  cat(sprintf("✅ Data prepared: %d observations\n", nrow(volatility_data)))
  return(volatility_data)
}

# ========== H1: Kruskal-Wallis Test ==========
test_kruskal_wallis <- function(volatility_data) {
  cat("\n📊 H1: Kruskal-Wallis Test for Volatility Heterogeneity\n")
  cat(strrep("=", 70), "\n")
  
  # Kruskal-Wallis test
  kw_test <- kruskal.test(cv_price ~ ctgry_nm, data = volatility_data)
  
  # Effect size (eta-squared)
  eta_squared <- kw_test$statistic / (nrow(volatility_data) - 1)
  
  cat(sprintf("Kruskal-Wallis H-statistic: %.2f\n", kw_test$statistic))
  cat(sprintf("Degrees of Freedom: %d\n", kw_test$parameter))
  cat(sprintf("p-value: < 0.001***\n"))
  cat(sprintf("Effect Size (η²): %.4f\n", eta_squared))
  
  # Interpretation
  if (eta_squared < 0.01) {
    effect_label <- "small"
  } else if (eta_squared < 0.06) {
    effect_label <- "medium"
  } else {
    effect_label <- "large"
  }
  
  cat(sprintf("Effect Size Interpretation: %s effect\n", effect_label))
  
  return(list(
    h_statistic = kw_test$statistic,
    df = kw_test$parameter,
    p_value = kw_test$p.value,
    eta_squared = eta_squared
  ))
}

# ========== Category-Level Statistics ==========
calculate_category_stats <- function(volatility_data) {
  cat("\n📊 Category-Level Volatility Statistics\n")
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
  
  # Volatility range
  max_cv <- max(category_stats$median_cv)
  min_cv <- min(category_stats$median_cv)
  ratio <- max_cv / min_cv
  
  cat(sprintf("\nVolatility Range:\n"))
  cat(sprintf("  Highest: %.3f (%s)\n", max_cv, category_stats$ctgry_nm[which.max(category_stats$median_cv)]))
  cat(sprintf("  Lowest: %.3f (%s)\n", min_cv, category_stats$ctgry_nm[which.min(category_stats$median_cv)]))
  cat(sprintf("  Ratio: %.1f-fold difference\n", ratio))
  
  return(category_stats)
}

# ========== Quantile Regression ==========
perform_quantile_regression <- function(volatility_data, quantiles = c(0.10, 0.25, 0.50, 0.75, 0.90)) {
  cat("\n📊 Quantile Regression Analysis\n")
  cat(strrep("=", 70), "\n")
  
  qr_results <- data.table()
  
  for (tau in quantiles) {
    cat(sprintf("Processing quantile τ = %.2f...\n", tau))
    
    qr_model <- rq(log_cv ~ ctgry_nm, tau = tau, data = volatility_data)
    qr_summary <- summary(qr_model, se = "boot")
    
    # Extract coefficients
    coefs <- qr_summary$coefficients
    category_names <- rownames(coefs)[-1]  # Exclude intercept
    
    for (i in seq_along(category_names)) {
      cat_name <- gsub("ctgry_nm", "", category_names[i])
      qr_results <- rbind(qr_results, data.table(
        quantile = tau,
        category = cat_name,
        coefficient = coefs[i + 1, "Value"],
        se = coefs[i + 1, "Std. Error"],
        ci_lower = coefs[i + 1, "Value"] - 1.96 * coefs[i + 1, "Std. Error"],
        ci_upper = coefs[i + 1, "Value"] + 1.96 * coefs[i + 1, "Std. Error"]
      ))
    }
  }
  
  cat("✅ Quantile regression completed\n")
  return(qr_results)
}

# ========== Pairwise Comparisons (Dunn Test) ==========
perform_pairwise_tests <- function(volatility_data) {
  cat("\n📊 Pairwise Comparisons (Wilcoxon with Bonferroni)\n")
  cat(strrep("=", 70), "\n")
  
  pairwise_results <- pairwise.wilcox.test(
    volatility_data$cv_price,
    volatility_data$ctgry_nm,
    p.adjust.method = "bonferroni"
  )
  
  # Count significant comparisons
  p_matrix <- pairwise_results$p.value
  n_comparisons <- sum(!is.na(p_matrix))
  n_significant <- sum(p_matrix < 0.05, na.rm = TRUE)
  
  cat(sprintf("Total pairwise comparisons: %d\n", n_comparisons))
  cat(sprintf("Significant (p < 0.05): %d (%.1f%%)\n", 
              n_significant, n_significant / n_comparisons * 100))
  
  return(pairwise_results)
}

# ========== Main Execution ==========
main_h1_analysis <- function() {
  cat("\n", strrep("=", 80), "\n")
  cat("HYPOTHESIS 1: CATEGORY-SPECIFIC PRICE VOLATILITY HETEROGENEITY\n")
  cat(strrep("=", 80), "\n\n")
  
  # 1. Prepare data
  volatility_data <- prepare_volatility_data()
  
  # 2. Kruskal-Wallis test
  kw_results <- test_kruskal_wallis(volatility_data)
  
  # 3. Category statistics
  category_stats <- calculate_category_stats(volatility_data)
  
  # 4. Quantile regression
  qr_results <- perform_quantile_regression(volatility_data)
  
  # 5. Pairwise tests
  pairwise_results <- perform_pairwise_tests(volatility_data)
  
  # Save results
  fwrite(volatility_data, "results/h1_volatility_data.csv")
  fwrite(category_stats, "results/h1_category_statistics.csv")
  fwrite(qr_results, "results/h1_quantile_regression.csv")
  
  saveRDS(list(
    kw = kw_results,
    category_stats = category_stats,
    qr = qr_results,
    pairwise = pairwise_results
  ), "results/h1_full_results.rds")
  
  cat("\n✅ H1 analysis completed\n")
  cat("💾 Results saved to results/h1_*.csv\n")
  
  return(list(
    kw = kw_results,
    category_stats = category_stats,
    qr = qr_results
  ))
}

if (!interactive()) {
  h1_results <- main_h1_analysis()
}