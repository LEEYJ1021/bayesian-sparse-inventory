# h2_lead_time_elasticity.R
# H2: Lead Time Multiplicative Effect (Near-Unit Elasticity)
# Cluster-Robust Regression (CR2)

library(data.table)
library(lmtest)
library(sandwich)
library(estimatr)
library(car)

# ========== Load Data ==========
prepare_h2_data <- function() {
  cat("🔄 Loading inventory policy data...\n")
  
  inventory_policy <- fread("data/processed/bayesian_inventory_policy_202601291928.csv")
  
  # Filter and transform
  h2_data <- inventory_policy[
    is.finite(reorder_point_mean) & reorder_point_mean > 0 &
    is.finite(safety_stock_mean) &
    is.finite(service_level) & service_level > 0 &
    is.finite(lead_time) & lead_time > 0
  ]
  
  # Log transformations
  h2_data[, `:=`(
    log_rop = log(reorder_point_mean),
    log_ss = log(pmax(safety_stock_mean, 0.1)),  # Avoid log(0)
    log_leadtime = log(lead_time),
    service_pct = service_level * 100
  )]
  
  cat(sprintf("✅ Data prepared: %d observations\n", nrow(h2_data)))
  return(h2_data)
}

# ========== H2: Baseline OLS Regression ==========
estimate_baseline_model <- function(h2_data) {
  cat("\n📊 H2: Baseline OLS Regression\n")
  cat(strrep("=", 70), "\n")
  
  model <- lm(log_rop ~ log_leadtime, data = h2_data)
  
  cat("\nModel: log(ROP) ~ log(LT)\n")
  print(summary(model))
  
  # Extract results
  elasticity <- coef(model)["log_leadtime"]
  se <- summary(model)$coefficients["log_leadtime", "Std. Error"]
  t_stat <- summary(model)$coefficients["log_leadtime", "t value"]
  p_value <- summary(model)$coefficients["log_leadtime", "Pr(>|t|)"]
  r_squared <- summary(model)$r.squared
  
  cat(sprintf("\nLead Time Elasticity: %.4f***\n", elasticity))
  cat(sprintf("Std. Error: %.4f\n", se))
  cat(sprintf("95%% CI: [%.4f, %.4f]\n", 
              elasticity - 1.96 * se, 
              elasticity + 1.96 * se))
  cat(sprintf("R²: %.4f\n", r_squared))
  
  return(list(model = model, elasticity = elasticity, se = se, r_squared = r_squared))
}

# ========== Cluster-Robust Inference (CR2) ==========
estimate_cluster_robust <- function(h2_data) {
  cat("\n📊 Cluster-Robust Standard Errors (CR2)\n")
  cat(strrep("=", 70), "\n")
  
  # Using estimatr package for CR2
  model_cr2 <- lm_robust(
    log_rop ~ log_leadtime * service_level,
    data = h2_data,
    clusters = item_cd,
    se_type = "CR2"
  )
  
  print(summary(model_cr2))
  
  # Extract results
  elasticity <- coef(model_cr2)["log_leadtime"]
  se_cr2 <- model_cr2$std.error["log_leadtime"]
  ci_lower <- elasticity - 1.96 * se_cr2
  ci_upper <- elasticity + 1.96 * se_cr2
  
  cat("\n" , strrep("=", 70), "\n")
  cat("PRIMARY ELASTICITY ESTIMATE (Cluster-Robust CR2)\n")
  cat(strrep("=", 70), "\n")
  cat(sprintf("Elasticity (β): %.4f***\n", elasticity))
  cat(sprintf("Cluster-Robust SE: %.4f\n", se_cr2))
  cat(sprintf("95%% CI: [%.4f, %.4f]\n", ci_lower, ci_upper))
  cat(sprintf("R²: %.4f\n", model_cr2$r.squared))
  cat(sprintf("Clusters (items): %d\n", length(unique(h2_data$item_cd))))
  
  # Interpretation
  cat("\nInterpretation:\n")
  cat(sprintf("  1%% ↑ LT → %.2f%% ↑ ROP\n", elasticity * 100))
  cat(sprintf("  2× LT → %.1f%% ↑ ROP\n", (2^elasticity - 1) * 100))
  cat(sprintf("  Classical √LT prediction: β = 0.5\n"))
  cat(sprintf("  Observed / Classical: %.2f×\n", elasticity / 0.5))
  
  return(list(
    model = model_cr2,
    elasticity = elasticity,
    se = se_cr2,
    ci_lower = ci_lower,
    ci_upper = ci_upper
  ))
}

# ========== Model Specifications Comparison ==========
compare_specifications <- function(h2_data) {
  cat("\n📊 Model Specification Comparison\n")
  cat(strrep("=", 70), "\n")
  
  specs <- list(
    "M1: Basic" = log_rop ~ log_leadtime,
    "M2: + Service" = log_rop ~ log_leadtime + service_level,
    "M3: + Interaction" = log_rop ~ log_leadtime * service_level,
    "M4: + Controls" = log_rop ~ log_leadtime * service_level + log(demand_std)
  )
  
  results <- data.table()
  
  for (spec_name in names(specs)) {
    tryCatch({
      if (spec_name == "M4: + Controls" && !"demand_std" %in% names(h2_data)) {
        cat(sprintf("Skipping %s (demand_std not available)\n", spec_name))
        next
      }
      
      model <- lm(specs[[spec_name]], data = h2_data)
      
      elasticity <- coef(model)["log_leadtime"]
      se <- summary(model)$coefficients["log_leadtime", "Std. Error"]
      r2 <- summary(model)$r.squared
      
      results <- rbind(results, data.table(
        Specification = spec_name,
        Elasticity = elasticity,
        SE = se,
        CI_lower = elasticity - 1.96 * se,
        CI_upper = elasticity + 1.96 * se,
        R_squared = r2
      ))
    }, error = function(e) {
      cat(sprintf("Error in %s: %s\n", spec_name, e$message))
    })
  }
  
  print(results)
  
  return(results)
}

# ========== Diagnostics ==========
perform_diagnostics <- function(model, h2_data) {
  cat("\n📊 Model Diagnostics\n")
  cat(strrep("=", 70), "\n")
  
  # 1. Heteroskedasticity (Breusch-Pagan)
  bp_test <- lmtest::bptest(model)
  cat(sprintf("Breusch-Pagan Test: χ² = %.2f, p = %.4f\n", 
              bp_test$statistic, bp_test$p.value))
  
  # 2. Multicollinearity (VIF)
  if (length(coef(model)) > 2) {
    vif_values <- car::vif(model)
    cat(sprintf("Max VIF: %.2f ", max(vif_values)))
    if (max(vif_values) < 5) {
      cat("✓ Acceptable\n")
    } else {
      cat("⚠ High multicollinearity\n")
    }
  }
  
  # 3. Normality (Shapiro-Wilk on residuals)
  residuals_sample <- sample(residuals(model), min(5000, length(residuals(model))))
  shapiro_test <- shapiro.test(residuals_sample)
  cat(sprintf("Shapiro-Wilk (residuals): W = %.4f, p = %.4f\n", 
              shapiro_test$statistic, shapiro_test$p.value))
  
  # 4. Influential observations (Cook's distance)
  cooksd <- cooks.distance(model)
  influential <- sum(cooksd > 4 / length(cooksd))
  cat(sprintf("Influential observations: %d (%.1f%%)\n", 
              influential, influential / length(cooksd) * 100))
}

# ========== Main Execution ==========
main_h2_analysis <- function() {
  cat("\n", strrep("=", 80), "\n")
  cat("HYPOTHESIS 2: LEAD TIME MULTIPLICATIVE EFFECT\n")
  cat(strrep("=", 80), "\n\n")
  
  # 1. Load data
  h2_data <- prepare_h2_data()
  
  # 2. Baseline model
  baseline_results <- estimate_baseline_model(h2_data)
  
  # 3. Cluster-robust estimation
  cr2_results <- estimate_cluster_robust(h2_data)
  
  # 4. Specification comparison
  spec_comparison <- compare_specifications(h2_data)
  
  # 5. Diagnostics
  perform_diagnostics(baseline_results$model, h2_data)
  
  # Save results
  fwrite(h2_data, "results/h2_regression_data.csv")
  fwrite(spec_comparison, "results/h2_specification_comparison.csv")
  
  saveRDS(list(
    baseline = baseline_results,
    cr2 = cr2_results,
    specifications = spec_comparison
  ), "results/h2_full_results.rds")
  
  cat("\n✅ H2 analysis completed\n")
  cat("💾 Results saved to results/h2_*.csv\n")
  
  return(list(
    baseline = baseline_results,
    cr2 = cr2_results,
    specifications = spec_comparison
  ))
}

if (!interactive()) {
  h2_results <- main_h2_analysis()
}