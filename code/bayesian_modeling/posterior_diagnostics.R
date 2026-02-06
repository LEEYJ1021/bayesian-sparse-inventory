# posterior_diagnostics.R
# Convergence Checks and Posterior Diagnostics

library(coda)
library(data.table)
library(ggplot2)

# ========== Gelman-Rubin Diagnostic ==========
gelman_rubin_diagnostic <- function(mcmc_samples) {
  cat("\n📊 Gelman-Rubin Convergence Diagnostic\n")
  cat(strrep("=", 60), "\n")
  
  # Calculate R-hat for all parameters
  gelman_diag <- gelman.diag(mcmc_samples, multivariate = FALSE)
  rhat_values <- gelman_diag$psrf[, "Point est."]
  
  # Summary statistics
  cat(sprintf("Mean R-hat: %.4f\n", mean(rhat_values, na.rm = TRUE)))
  cat(sprintf("Max R-hat: %.4f\n", max(rhat_values, na.rm = TRUE)))
  cat(sprintf("SD R-hat: %.6f\n", sd(rhat_values, na.rm = TRUE)))
  
  # Convergence check
  failed <- sum(rhat_values > 1.1, na.rm = TRUE)
  total <- length(rhat_values)
  pass_rate <- (1 - failed / total) * 100
  
  cat(sprintf("\nConvergence Pass Rate: %.1f%% (%d/%d parameters)\n", 
              pass_rate, total - failed, total))
  
  if (failed == 0) {
    cat("✅ All parameters converged (R-hat < 1.1)\n")
  } else {
    cat(sprintf("⚠️ Warning: %d parameters failed convergence\n", failed))
  }
  
  return(list(
    mean_rhat = mean(rhat_values, na.rm = TRUE),
    max_rhat = max(rhat_values, na.rm = TRUE),
    pass_rate = pass_rate,
    rhat_values = rhat_values
  ))
}

# ========== Effective Sample Size ==========
calculate_ess <- function(mcmc_samples) {
  cat("\n📊 Effective Sample Size (ESS)\n")
  cat(strrep("=", 60), "\n")
  
  ess_values <- effectiveSize(mcmc_samples)
  
  cat(sprintf("Mean ESS: %.0f\n", mean(ess_values, na.rm = TRUE)))
  cat(sprintf("Median ESS: %.0f\n", median(ess_values, na.rm = TRUE)))
  cat(sprintf("Min ESS: %.0f\n", min(ess_values, na.rm = TRUE)))
  cat(sprintf("Max ESS: %.0f\n", max(ess_values, na.rm = TRUE)))
  
  # Check if ESS is adequate (> 1000)
  low_ess <- sum(ess_values < 1000, na.rm = TRUE)
  if (low_ess == 0) {
    cat("✅ All parameters have adequate ESS (> 1000)\n")
  } else {
    cat(sprintf("⚠️ %d parameters have low ESS (< 1000)\n", low_ess))
  }
  
  return(ess_values)
}

# ========== Trace Plots ==========
plot_trace <- function(mcmc_samples, params = NULL, output_file = "results/figures/trace_plots.png") {
  cat("\n📊 Generating trace plots...\n")
  
  if (is.null(params)) {
    # Select first 6 parameters
    all_params <- varnames(mcmc_samples)
    params <- all_params[1:min(6, length(all_params))]
  }
  
  png(output_file, width = 1200, height = 800, res = 150)
  par(mfrow = c(length(params), 1), mar = c(3, 4, 2, 1))
  
  for (param in params) {
    traceplot(mcmc_samples[, param], main = param, ylab = "Value")
  }
  
  dev.off()
  cat(sprintf("✅ Trace plots saved to %s\n", output_file))
}

# ========== Main Diagnostic Report ==========
diagnostic_report <- function(mcmc_samples, output_dir = "results") {
  cat("\n" , strrep("=", 80), "\n")
  cat("COMPREHENSIVE POSTERIOR DIAGNOSTICS REPORT\n")
  cat(strrep("=", 80), "\n")
  
  # 1. Gelman-Rubin
  gelman_results <- gelman_rubin_diagnostic(mcmc_samples)
  
  # 2. Effective Sample Size
  ess_results <- calculate_ess(mcmc_samples)
  
  # 3. Trace plots
  plot_trace(mcmc_samples, output_file = file.path(output_dir, "figures", "trace_plots.png"))
  
  # 4. Summary table
  summary_df <- data.table(
    Parameter = names(gelman_results$rhat_values)[1:min(20, length(gelman_results$rhat_values))],
    Rhat = gelman_results$rhat_values[1:min(20, length(gelman_results$rhat_values))],
    ESS = ess_results[1:min(20, length(ess_results))]
  )
  
  fwrite(summary_df, file.path(output_dir, "diagnostic_summary.csv"))
  cat(sprintf("\n💾 Diagnostic summary saved to %s\n", 
              file.path(output_dir, "diagnostic_summary.csv")))
  
  return(list(
    gelman = gelman_results,
    ess = ess_results,
    summary = summary_df
  ))
}

# ========== Example Usage ==========
if (!interactive()) {
  # Load posterior samples
  posterior_samples <- readRDS("results/posterior_samples.rds")
  
  # Run diagnostics
  diagnostics <- diagnostic_report(posterior_samples)
  
  cat("\n✅ Diagnostic report completed\n")
}