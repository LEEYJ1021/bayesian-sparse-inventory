# lead_time_scaling.R
# Lead Time Elasticity Estimation

library(data.table)
library(lmtest)
library(sandwich)

# ========== Generate Lead Time Sensitivity Data ==========
generate_leadtime_data <- function(posterior_samples, 
                                  lead_times = c(1, 2, 3, 5, 7, 10, 14, 21, 30),
                                  service_level = 0.95,
                                  n_items = 100) {
  cat("🔄 Generating lead time sensitivity data...\n")
  
  results <- data.table()
  
  for (lt in lead_times) {
    cat(sprintf("Processing LT=%d days...\n", lt))
    
    for (item_idx in 1:n_items) {
      # Sample from posterior
      mu <- sample(posterior_samples$mu_item, 1)
      sigma <- sample(posterior_samples$sigma_obs, 1)
      
      # Calculate lead time demand parameters
      mu_LT <- lt * mu
      sigma_LT <- sqrt(lt) * sigma
      
      # Calculate ROP (using normal approximation)
      z_alpha <- qnorm(service_level)
      ROP <- mu_LT + z_alpha * sigma_LT
      SS <- z_alpha * sigma_LT
      
      results <- rbind(results, data.table(
        item_id = item_idx,
        lead_time = lt,
        service_level = service_level,
        mu = mu,
        sigma = sigma,
        ROP = ROP,
        SS = SS,
        log_LT = log(lt),
        log_ROP = log(ROP),
        log_SS = log(SS)
      ))
    }
  }
  
  cat("✅ Lead time data generated\n")
  return(results)
}

# ========== Estimate Lead Time Elasticity ==========
estimate_elasticity <- function(leadtime_data) {
  cat("\n📊 Estimating Lead Time Elasticity\n")
  cat(strrep("=", 60), "\n")
  
  # Log-log regression: log(ROP) ~ log(LT)
  model <- lm(log_ROP ~ log_LT, data = leadtime_data)
  
  # Cluster-robust standard errors (clustered by item)
  vcov_cluster <- vcovCL(model, cluster = leadtime_data$item_id)
  coef_robust <- coeftest(model, vcov = vcov_cluster)
  
  # Extract elasticity
  elasticity <- coef(model)["log_LT"]
  se_robust <- coef_robust["log_LT", "Std. Error"]
  ci_lower <- elasticity - 1.96 * se_robust
  ci_upper <- elasticity + 1.96 * se_robust
  
  # Model diagnostics
  r_squared <- summary(model)$r.squared
  adj_r_squared <- summary(model)$adj.r.squared
  
  cat("\nRegression Results:\n")
  cat(sprintf("Elasticity (β): %.4f***\n", elasticity))
  cat(sprintf("Cluster-Robust SE: %.4f\n", se_robust))
  cat(sprintf("95%% CI: [%.4f, %.4f]\n", ci_lower, ci_upper))
  cat(sprintf("R²: %.4f\n", r_squared))
  cat(sprintf("Adj. R²: %.4f\n", adj_r_squared))
  cat(sprintf("N: %d\n", nrow(leadtime_data)))
  
  # Interpretation
  cat("\nInterpretation:\n")
  cat(sprintf("1%% increase in lead time → %.2f%% increase in ROP\n", elasticity * 100))
  cat(sprintf("Doubling lead time → %.1f%% increase in ROP\n", (2^elasticity - 1) * 100))
  
  # Classical prediction (square-root law)
  classical_elasticity <- 0.5
  cat(sprintf("\nClassical prediction (√LT): β = %.1f\n", classical_elasticity))
  cat(sprintf("Observed / Classical ratio: %.2f\n", elasticity / classical_elasticity))
  
  return(list(
    elasticity = elasticity,
    se = se_robust,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    r_squared = r_squared,
    model = model,
    coef_robust = coef_robust
  ))
}

# ========== Quantile Regression ==========
estimate_elasticity_quantiles <- function(leadtime_data, quantiles = c(0.1, 0.25, 0.5, 0.75, 0.9)) {
  cat("\n📊 Quantile Regression Analysis\n")
  cat(strrep("=", 60), "\n")
  
  library(quantreg)
  
  results <- data.table()
  
  for (tau in quantiles) {
    qr_model <- rq(log_ROP ~ log_LT, tau = tau, data = leadtime_data)
    qr_summary <- summary(qr_model, se = "boot")
    
    elasticity <- coef(qr_model)["log_LT"]
    se <- qr_summary$coefficients["log_LT", "Std. Error"]
    
    results <- rbind(results, data.table(
      quantile = tau,
      elasticity = elasticity,
      se = se,
      ci_lower = elasticity - 1.96 * se,
      ci_upper = elasticity + 1.96 * se
    ))
    
    cat(sprintf("τ = %.2f: β = %.4f [%.4f, %.4f]\n", 
                tau, elasticity, 
                elasticity - 1.96 * se, 
                elasticity + 1.96 * se))
  }
  
  return(results)
}

# ========== Main Execution ==========
if (!interactive()) {
  # Load posterior samples
  posterior_samples <- readRDS("results/posterior_samples.rds")
  
  # Generate data
  leadtime_data <- generate_leadtime_data(posterior_samples)
  
  # Estimate elasticity
  elasticity_results <- estimate_elasticity(leadtime_data)
  
  # Quantile regression
  quantile_results <- estimate_elasticity_quantiles(leadtime_data)
  
  # Save results
  fwrite(leadtime_data, "results/leadtime_sensitivity_data.csv")
  fwrite(quantile_results, "results/leadtime_quantile_elasticity.csv")
  
  saveRDS(elasticity_results, "results/elasticity_results.rds")
  
  cat("\n✅ Lead time scaling analysis completed\n")
}