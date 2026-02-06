# hierarchical_model.R
# Bayesian Hierarchical Model with MCMC (JAGS/Stan)

library(rjags)
library(coda)
library(data.table)

# ========== Load Data ==========
fact_price <- fread("data/processed/fact_price_daily_202601291929.csv")
metadata <- fread("data/processed/metadata_item_catalog_202601291929.csv")

# ========== Prepare Data for JAGS ==========
prepare_jags_data <- function(df) {
  df <- df[!is.na(price) & price > 0]
  
  # Create category indices
  df[, category_idx := as.integer(factor(ctgry_cd))]
  df[, item_idx := as.integer(factor(item_cd))]
  
  list(
    y = log(df$price + 1),  # Log-transformed prices
    item = df$item_idx,
    category = df$category_idx,
    N = nrow(df),
    N_items = max(df$item_idx),
    N_categories = max(df$category_idx)
  )
}

jags_data <- prepare_jags_data(fact_price)

# ========== JAGS Model Specification ==========
model_string <- "
model {
  # Level 1: Observation model
  for (i in 1:N) {
    y[i] ~ dnorm(mu_item[item[i]], tau_obs)
  }
  
  # Level 2: Partial pooling across items
  for (j in 1:N_items) {
    mu_item[j] ~ dnorm(mu_category[category[j]], tau_between)
  }
  
  # Level 3: Hyperpriors
  for (k in 1:N_categories) {
    mu_category[k] ~ dnorm(mu_0, tau_0)
  }
  
  # Priors
  mu_0 ~ dnorm(9.147, 0.01)      # Empirical mean of log-prices
  tau_obs ~ dgamma(0.01, 0.01)   # Observation precision
  tau_between ~ dgamma(0.01, 0.01) # Between-item precision
  tau_0 <- 0.01                  # Hyperprior precision
  
  # Derived quantities
  sigma_obs <- 1 / sqrt(tau_obs)
  sigma_between <- 1 / sqrt(tau_between)
}
"

# ========== Run MCMC ==========
run_hierarchical_mcmc <- function(jags_data, n_iter = 2000, n_burnin = 500) {
  cat("🔄 Running MCMC...\n")
  
  # Initialize model
  model <- jags.model(
    textConnection(model_string),
    data = jags_data,
    n.chains = 2,
    n.adapt = 1000
  )
  
  # Burn-in
  update(model, n_burnin)
  
  # Sample from posterior
  samples <- coda.samples(
    model,
    variable.names = c("mu_item", "mu_category", "sigma_obs", "sigma_between"),
    n.iter = n_iter,
    thin = 2
  )
  
  cat("✅ MCMC completed\n")
  return(samples)
}

# ========== Convergence Diagnostics ==========
check_convergence <- function(samples) {
  cat("\n📊 Convergence Diagnostics\n")
  cat("="*60, "\n")
  
  # Gelman-Rubin diagnostic
  gelman_diag <- gelman.diag(samples, multivariate = FALSE)
  cat("Gelman-Rubin R-hat (should be < 1.1):\n")
  print(summary(gelman_diag$psrf[, "Point est."]))
  
  # Effective sample size
  ess <- effectiveSize(samples)
  cat("\nEffective Sample Size:\n")
  print(summary(ess))
  
  # Return TRUE if converged
  max_rhat <- max(gelman_diag$psrf[, "Point est."], na.rm = TRUE)
  min_ess <- min(ess, na.rm = TRUE)
  
  converged <- (max_rhat < 1.1) & (min_ess > 1000)
  
  if (converged) {
    cat("\n✅ Model converged successfully\n")
  } else {
    cat("\n⚠️ Warning: Convergence issues detected\n")
  }
  
  return(converged)
}

# ========== Main Execution ==========
main <- function() {
  cat("🚀 Bayesian Hierarchical Model - MCMC Inference\n")
  cat("="*60, "\n\n")
  
  # Run MCMC
  posterior_samples <- run_hierarchical_mcmc(jags_data)
  
  # Check convergence
  converged <- check_convergence(posterior_samples)
  
  # Save results
  saveRDS(posterior_samples, "results/posterior_samples.rds")
  cat("\n💾 Posterior samples saved to results/posterior_samples.rds\n")
  
  return(posterior_samples)
}

if (!interactive()) {
  main()
}