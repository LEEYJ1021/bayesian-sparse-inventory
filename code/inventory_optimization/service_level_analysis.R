# service_level_analysis.R
# Service Level Sensitivity Analysis for Inventory Policies

library(data.table)
library(ggplot2)
library(scales)

# ========== Service Level Trade-off Analysis ==========
analyze_service_level_tradeoff <- function(posterior_samples, 
                                          lead_time = 7,
                                          service_levels = seq(0.85, 0.99, by = 0.01)) {
  cat("🔄 Analyzing service level trade-offs...\n")
  cat(sprintf("Lead Time: %d days\n", lead_time))
  cat(sprintf("Service Levels: %.0f%% to %.0f%%\n", 
              min(service_levels) * 100, max(service_levels) * 100))
  
  results <- data.table()
  
  # Generate posterior predictive once
  mu_samples <- posterior_samples$mu_item
  sigma_samples <- posterior_samples$sigma_obs
  
  n_samples <- 5000
  predictive_samples <- sapply(1:n_samples, function(i) {
    mu <- sample(mu_samples, 1)
    sigma <- sample(sigma_samples, 1)
    mu_LT <- lead_time * mu
    sigma_LT <- sqrt(lead_time) * sigma
    rnorm(1, mean = mu_LT, sd = sigma_LT)
  })
  
  mean_demand <- mean(predictive_samples)
  
  for (sl in service_levels) {
    # Calculate ROP and SS
    ROP <- quantile(predictive_samples, sl)
    SS <- ROP - mean_demand
    
    # Calculate expected costs (newsvendor)
    holding_cost <- 1  # per unit
    shortage_cost <- 9  # per unit
    
    expected_holding <- holding_cost * mean(pmax(ROP - predictive_samples, 0))
    expected_shortage <- shortage_cost * mean(pmax(predictive_samples - ROP, 0))
    total_cost <- expected_holding + expected_shortage
    
    # Fill rate
    fill_rate <- mean(pmin(predictive_samples, ROP) / predictive_samples)
    
    results <- rbind(results, data.table(
      service_level = sl,
      ROP = ROP,
      SS = SS,
      expected_holding = expected_holding,
      expected_shortage = expected_shortage,
      total_cost = total_cost,
      fill_rate = fill_rate
    ))
  }
  
  cat("✅ Service level analysis completed\n")
  
  return(results)
}

# ========== Visualize Trade-off Curve ==========
plot_service_level_tradeoff <- function(analysis_results, output_file = "results/figures/service_level_tradeoff.png") {
  cat("📊 Generating service level trade-off visualization...\n")
  
  # Create multi-panel plot
  p1 <- ggplot(analysis_results, aes(x = service_level * 100, y = ROP)) +
    geom_line(color = "#E64B35", size = 1.2) +
    geom_ribbon(aes(ymin = ROP * 0.95, ymax = ROP * 1.05), alpha = 0.2, fill = "#E64B35") +
    labs(title = "A. Reorder Point vs Service Level",
         x = "Service Level (%)", y = "Reorder Point") +
    theme_minimal(base_size = 12)
  
  p2 <- ggplot(analysis_results, aes(x = service_level * 100, y = total_cost)) +
    geom_line(color = "#4DBBD5", size = 1.2) +
    geom_point(data = analysis_results[which.min(total_cost)], 
               color = "red", size = 3) +
    labs(title = "B. Total Expected Cost vs Service Level",
         x = "Service Level (%)", y = "Total Cost") +
    theme_minimal(base_size = 12)
  
  p3 <- ggplot(analysis_results, aes(x = service_level * 100, y = SS)) +
    geom_line(color = "#00A087", size = 1.2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    labs(title = "C. Safety Stock vs Service Level",
         x = "Service Level (%)", y = "Safety Stock") +
    theme_minimal(base_size = 12)
  
  combined_plot <- gridExtra::grid.arrange(p1, p2, p3, ncol = 2)
  
  ggsave(output_file, combined_plot, width = 12, height = 8, dpi = 600)
  cat(sprintf("✅ Plot saved to %s\n", output_file))
}

# ========== Find Optimal Service Level ==========
find_optimal_service_level <- function(analysis_results) {
  cat("\n📊 Finding optimal service level...\n")
  cat(strrep("=", 60), "\n")
  
  optimal_idx <- which.min(analysis_results$total_cost)
  optimal_sl <- analysis_results$service_level[optimal_idx]
  
  cat(sprintf("Optimal Service Level: %.1f%%\n", optimal_sl * 100))
  cat(sprintf("ROP: %.2f\n", analysis_results$ROP[optimal_idx]))
  cat(sprintf("Safety Stock: %.2f\n", analysis_results$SS[optimal_idx]))
  cat(sprintf("Total Cost: %.2f\n", analysis_results$total_cost[optimal_idx]))
  cat(sprintf("Fill Rate: %.2f%%\n", analysis_results$fill_rate[optimal_idx] * 100))
  
  return(optimal_sl)
}

# ========== Main Execution ==========
if (!interactive()) {
  # Load posterior samples
  posterior_samples <- readRDS("results/posterior_samples.rds")
  
  # Run analysis
  analysis_results <- analyze_service_level_tradeoff(posterior_samples)
  
  # Find optimal
  optimal_sl <- find_optimal_service_level(analysis_results)
  
  # Visualize
  plot_service_level_tradeoff(analysis_results)
  
  # Save results
  fwrite(analysis_results, "results/service_level_analysis.csv")
  cat("\n💾 Results saved to results/service_level_analysis.csv\n")
}