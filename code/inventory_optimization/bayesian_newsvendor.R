# bayesian_newsvendor.R
# Posterior Predictive Reorder Point (ROP) and Safety Stock (SS) Calculation

library(data.table)
library(parallel)

# ========== Posterior Predictive Distribution ==========
generate_posterior_predictive <- function(posterior_samples, lead_time = 7, n_samples = 1000) {
  cat(sprintf("🔄 Generating posterior predictive for LT=%d days...\n", lead_time))
  
  # Extract posterior parameters
  mu_samples <- posterior_samples$mu_item  # Item-level means
  sigma_samples <- posterior_samples$sigma_obs  # Observation std
  
  # Generate predictive samples
  predictive_samples <- lapply(1:n_samples, function(i) {
    mu <- sample(mu_samples, 1)
    sigma <- sample(sigma_samples, 1)
    
    # Lead time demand ~ N(LT * mu, sqrt(LT) * sigma)
    mu_LT <- lead_time * mu
    sigma_LT <- sqrt(lead_time) * sigma
    
    rnorm(1, mean = mu_LT, sd = sigma_LT)
  })
  
  predictive_samples <- unlist(predictive_samples)
  
  cat("✅ Posterior predictive generated\n")
  return(predictive_samples)
}

# ========== Calculate ROP and SS ==========
calculate_inventory_policy <- function(predictive_samples, service_level = 0.95) {
  # Reorder Point = quantile at service level
  ROP <- quantile(predictive_samples, service_level)
  
  # Safety Stock = ROP - E[demand_LT]
  mean_demand <- mean(predictive_samples)
  SS <- ROP - mean_demand
  
  # Credible intervals
  ROP_CI <- quantile(predictive_samples, c(0.025, 0.975))
  
  return(list(
    ROP_mean = ROP,
    ROP_CI_lower = ROP_CI[1],
    ROP_CI_upper = ROP_CI[2],
    SS_mean = SS,
    mean_demand_LT = mean_demand,
    service_level = service_level
  ))
}

# ========== Fill Rate Calculation ==========
calculate_fill_rate <- function(predictive_samples, order_quantity) {
  # Fill Rate = E[min(D, Q) / D]
  fill_rate <- mean(pmin(predictive_samples, order_quantity) / predictive_samples)
  return(fill_rate)
}

# ========== Main Policy Generation ==========
generate_inventory_policies <- function(posterior_samples, 
                                       lead_times = c(1, 3, 7, 14),
                                       service_levels = c(0.90, 0.95, 0.99)) {
  cat("\n🔄 Generating inventory policies...\n")
  cat(strrep("=", 60), "\n")
  
  policies <- data.table()
  
  for (lt in lead_times) {
    for (sl in service_levels) {
      cat(sprintf("Processing LT=%d, SL=%.0f%%...\n", lt, sl * 100))
      
      # Generate posterior predictive
      pred_samples <- generate_posterior_predictive(posterior_samples, lead_time = lt)
      
      # Calculate policy
      policy <- calculate_inventory_policy(pred_samples, service_level = sl)
      
      # Calculate fill rate
      fill_rate <- calculate_fill_rate(pred_samples, policy$ROP_mean)
      
      # Store results
      policies <- rbind(policies, data.table(
        lead_time = lt,
        service_level = sl,
        ROP_mean = policy$ROP_mean,
        ROP_CI_lower = policy$ROP_CI_lower,
        ROP_CI_upper = policy$ROP_CI_upper,
        SS_mean = policy$SS_mean,
        mean_demand_LT = policy$mean_demand_LT,
        fill_rate = fill_rate
      ))
    }
  }
  
  cat("\n✅ Inventory policies generated\n")
  cat(sprintf("Total policies: %d\n", nrow(policies)))
  
  return(policies)
}

# ========== Example Usage ==========
if (!interactive()) {
  # Load posterior samples
  posterior_samples <- readRDS("results/posterior_samples.rds")
  
  # Generate policies
  policies <- generate_inventory_policies(posterior_samples)
  
  # Save results
  fwrite(policies, "results/inventory_policies.csv")
  cat("\n💾 Policies saved to results/inventory_policies.csv\n")
}