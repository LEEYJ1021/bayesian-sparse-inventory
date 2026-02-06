# robustness_checks.R
# Bootstrap, Subsample Validation, Sensitivity Analysis

library(data.table)
library(boot)
library(parallel)

# ========== Bootstrap Confidence Intervals ==========
bootstrap_elasticity <- function(h2_data, R = 1000) {
  cat("🔄 Running bootstrap analysis (R = ", R, ")...\n")
  
  # Bootstrap function
  elasticity_boot <- function(data, indices) {
    d <- data[indices, ]
    model <- lm(log_rop ~ log_leadtime, data = d)
    return(coef(model)["log_leadtime"])
  }
  
  # Run bootstrap
  boot_results <- boot(
    data = as.data.frame(h2_data),
    statistic = elasticity_boot,
    R = R,
    parallel = "multicore",
    ncpus = detectCores() - 1
  )
  
  # Calculate confidence intervals
  boot_ci <- boot.ci(boot_results, type = c("norm", "basic", "perc", "bca"))
  
  cat("✅ Bootstrap completed\n")
  cat("\nBootstrap Confidence Intervals:\n")
  print(boot_ci)
  
  return(boot_results)
}

# ========== Subsample Validation ==========
subsample_validation <- function(h2_data, n_subsamples = 10, sample_fraction = 0.8) {
  cat(sprintf("\n🔄 Subsample validation (%d samples, %.0f%% each)...\n", 
              n_subsamples, sample_fraction * 100))
  
  set.seed(123)
  subsample_results <- data.table()
  
  for (i in 1:n_subsamples) {
    # Random subsample
    subsample_idx <- sample(1:nrow(h2_data), size = floor(nrow(h2_data) * sample_fraction))
    subsample_data <- h2_data[subsample_idx, ]
    
    # Estimate model
    model <- lm(log_rop ~ log_leadtime, data = subsample_data)
    
    elasticity <- coef(model)["log_leadtime"]
    se <- summary(model)$coefficients["log_leadtime", "Std. Error"]
    r2 <- summary(model)$r.squared
    
    subsample_results <- rbind(subsample_results, data.table(
      subsample = i,
      n = nrow(subsample_data),
      elasticity = elasticity,
      se = se,
      r_squared = r2,
      ci_lower = elasticity - 1.96 * se,
      ci_upper = elasticity + 1.96 * se
    ))
  }
  
  cat("✅ Subsample validation completed\n")
  cat(sprintf("Mean elasticity: %.4f (SD: %.4f)\n", 
              mean(subsample_results$elasticity), 
              sd(subsample_results$elasticity)))
  cat(sprintf("Range: [%.4f, %.4f]\n", 
              min(subsample_results$elasticity), 
              max(subsample_results$elasticity)))
  
  return(subsample_results)
}

# ========== Service Level Stratification ==========
service_level_stratification <- function(h2_data) {
  cat("\n🔄 Service level stratification analysis...\n")
  
  # Create service level categories
  h2_data[, service_cat := cut(
    service_level,
    breaks = c(0, 0.93, 0.96, 0.99, 1),
    labels = c("90-93%", "93-96%", "96-99%", "99%+")
  )]
  
  stratified_results <- data.table()
  
  for (sl_cat in levels(h2_data$service_cat)) {
    subset_data <- h2_data[service_cat == sl_cat]
    
    if (nrow(subset_data) < 10) {
      cat(sprintf("Skipping %s (n = %d)\n", sl_cat, nrow(subset_data)))
      next
    }
    
    model <- lm(log_rop ~ log_leadtime, data = subset_data)
    
    elasticity <- coef(model)["log_leadtime"]
    se <- summary(model)$coefficients["log_leadtime", "Std. Error"]
    
    stratified_results <- rbind(stratified_results, data.table(
      service_category = sl_cat,
      n = nrow(subset_data),
      elasticity = elasticity,
      se = se,
      ci_lower = elasticity - 1.96 * se,
      ci_upper = elasticity + 1.96 * se
    ))
  }
  
  print(stratified_results)
  
  return(stratified_results)
}

# ========== Sensitivity to Outliers ==========
outlier_sensitivity <- function(h2_data) {
  cat("\n🔄 Outlier sensitivity analysis...\n")
  
  # Calculate Cook's distance
  baseline_model <- lm(log_rop ~ log_leadtime, data = h2_data)
  cooksd <- cooks.distance(baseline_model)
  
  # Define outlier thresholds
  thresholds <- c(Inf, 4/nrow(h2_data), 1/nrow(h2_data))
  threshold_names <- c("All data", "Exclude high Cook's D (>4/n)", "Exclude very high (>1/n)")
  
  sensitivity_results <- data.table()
  
  for (i in seq_along(thresholds)) {
    # Filter data
    if (thresholds[i] == Inf) {
      filtered_data <- h2_data
    } else {
      filtered_data <- h2_data[cooksd <= thresholds[i]]
    }
    
    # Re-estimate
    model <- lm(log_rop ~ log_leadtime, data = filtered_data)
    
    elasticity <- coef(model)["log_leadtime"]
    se <- summary(model)$coefficients["log_leadtime", "Std. Error"]
    
    sensitivity_results <- rbind(sensitivity_results, data.table(
      scenario = threshold_names[i],
      n = nrow(filtered_data),
      n_excluded = nrow(h2_data) - nrow(filtered_data),
      elasticity = elasticity,
      se = se
    ))
  }
  
  print(sensitivity_results)
  
  return(sensitivity_results)
}

# ========== Main Robustness Check ==========
main_robustness_checks <- function() {
  cat("\n", strrep("=", 80), "\n")
  cat("ROBUSTNESS CHECKS FOR H2\n")
  cat(strrep("=", 80), "\n\n")
  
  # Load data
  h2_data <- fread("results/h2_regression_data.csv")
  
  # 1. Bootstrap
  boot_results <- bootstrap_elasticity(h2_data, R = 1000)
  
  # 2. Subsample validation
  subsample_results <- subsample_validation(h2_data)
  
  # 3. Service level stratification
  stratified_results <- service_level_stratification(h2_data)
  
  # 4. Outlier sensitivity
  sensitivity_results <- outlier_sensitivity(h2_data)
  
  # Save all results
  saveRDS(boot_results, "results/robustness_bootstrap.rds")
  fwrite(subsample_results, "results/robustness_subsample.csv")
  fwrite(stratified_results, "results/robustness_stratified.csv")
  fwrite(sensitivity_results, "results/robustness_sensitivity.csv")
  
  cat("\n✅ All robustness checks completed\n")
  cat("💾 Results saved to results/robustness_*.csv\n")
  
  return(list(
    bootstrap = boot_results,
    subsample = subsample_results,
    stratified = stratified_results,
    sensitivity = sensitivity_results
  ))
}

if (!interactive()) {
  robustness_results <- main_robustness_checks()
}