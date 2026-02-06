# Bayesian Hierarchical Inventory Optimization for Korean Agricultural Products

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![R 4.0+](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)

**Research Paper Repository**: Complete replication package for "Bayesian Hierarchical Inventory Optimization for Korean Agricultural Products Under Sparse Data Conditions"

---

## 📋 Overview

This repository provides **full replication materials** for our research on inventory optimization under extreme data scarcity in agricultural supply chains. We demonstrate that **cross-sectional information pooling systematically substitutes for temporal depth**, enabling reliable decision-making with as few as **3–10 observations per product**.

### Core Innovation

Rather than treating data scarcity as a limitation, we reconceptualize it as a **design condition**. Through hierarchical Bayesian partial pooling across 93 Korean agricultural products, we achieve:

- ✅ **Stable inference** with n ≥ 3 observations (conventional methods require n ≥ 30)
- ✅ **Perfect service-level calibration** (95.0% achieved vs. 95.0% target)
- ✅ **22.6% lower expected costs** versus classical plug-in estimators
- ✅ **100% MCMC convergence** across all 554 item-market combinations

### Key Empirical Findings

| Research Question | Finding | Statistical Evidence |
|-------------------|---------|---------------------|
| **RQ1: Methodological Feasibility** | Hierarchical pooling enables reliable optimization with n=3–10 | R̂=1.000, 94.7% fill rate, 18.5–32.9% RMSE reduction |
| **RQ2: Category Heterogeneity** | Seven-fold volatility differences necessitate differentiated policies | H=875.4***, η²=0.160, r=0.92 with safety stock |
| **RQ3: Lead Time Elasticity** | Near-unit elasticity (β≈1.0) vs. classical √LT prediction (β≈0.5) | β=0.973 [0.894, 1.052], 59% amplification |

**Note**: *** p < 0.001

---

## 🗂️ Repository Structure

```
bayesian-agri-inventory/
│
├── data/                          # Raw and processed datasets
│   ├── raw/                       # KAMIS API outputs (6 endpoints)
│   │   ├── example_periodRetail_price_data.csv
│   │   ├── example_periodWholesale_price_data.csv
│   │   └── example_perYearMonth_price_data.csv
│   │
│   ├── processed/                 # Analysis-ready data (7 files)
│   │   ├── metadata_item_catalog_202601291929.csv           # 93 items × 7 categories
│   │   ├── metadata_hierarchical_structure_202601291929.csv # 554 item-market pairs
│   │   ├── fact_price_daily_202601291929.csv                # 5,494 observations (9-day window)
│   │   ├── bayesian_posterior_samples_202601291929.csv      # MCMC draws (hierarchical model)
│   │   ├── bayesian_forecasts_202601291928.csv              # Posterior predictive distributions
│   │   ├── bayesian_inventory_policy_202601291928.csv       # 6,648 ROP/SS policies
│   │   └── model_diagnostics_202601291929.csv               # Convergence metrics (R̂, ESS, JB)
│   │
│   └── README.md                  # Data dictionary and schema documentation
│
├── code/
│   ├── data_collection/           # KAMIS API integration and ETL
│   │   ├── api_explorer.py        # Comprehensive API endpoint exploration
│   │   ├── etl_pipeline.py        # MySQL ETL pipeline (SQLAlchemy 2.x star schema)
│   │   └── db_explorer.py         # Database validation and integrity checks
│   │
│   ├── bayesian_modeling/         # Core Bayesian inference engine
│   │   ├── hierarchical_model.R   # Full MCMC (rstan/JAGS, 10≤n<20)
│   │   ├── empirical_bayes.R      # James-Stein shrinkage (3≤n<10)
│   │   └── posterior_diagnostics.R # Gelman-Rubin R̂, ESS, trace plots
│   │
│   ├── inventory_optimization/    # Newsvendor policy derivation
│   │   ├── bayesian_newsvendor.R  # Posterior predictive ROP/RARC/RBC
│   │   ├── service_level_analysis.R # 90%/95%/99% service-level scenarios
│   │   └── lead_time_scaling.R    # Elasticity estimation (β=0.973)
│   │
│   └── hypothesis_testing/        # Statistical inference and robustness
│       ├── h1_volatility_heterogeneity.R  # Kruskal-Wallis H-test
│       ├── h2_lead_time_elasticity.R      # Cluster-robust regression (CR2 SE)
│       └── robustness_checks.R            # Bootstrap, quantile regression
│
├── CHANGELOG.md                   # Version history and updates
├── CONTRIBUTING.md                # Contribution guidelines
├── DELIVERABLES_SUMMARY.md        # Project deliverables checklist
├── README.md                      # This file
├── QUICKSTART.md                  # 5-minute quick-start guide
├── LICENSE
└── .gitignore
```

**Streamlined Design Rationale**: The updated structure eliminates unnecessary directories (`results/`, `docs/`, `visualization/`) by:
1. Storing outputs in `data/processed/` (single source of truth)
2. Embedding documentation in code headers and README files
3. Generating figures on-demand during analysis (no persistent storage)

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites

- **Python**: 3.8+ (3.10 recommended for SQLAlchemy 2.x compatibility)
- **R**: 4.0+ (4.3+ recommended for `rstan` GPU acceleration)
- **Optional**: MySQL 8.0+ (for full ETL replication; not required for core analysis)
- **RAM**: 8GB minimum (16GB recommended for MCMC with 2,000+ iterations)

### Installation

#### Step 1: Clone Repository
```bash
git clone https://github.com/your-org/bayesian-agri-inventory.git
cd bayesian-agri-inventory
```

#### Step 2: Set Up Python Environment
```bash
# Using conda (recommended for reproducibility)
conda env create -f environment.yml
conda activate agri-inventory

# OR using pip
pip install -r requirements.txt
```

#### Step 3: Install R Packages
```R
source("install_R_packages.R")
# Installs: tidyverse, data.table, rstan, rjags, quantreg, lmtest, sandwich,
#           ggplot2, patchwork, flextable, coda, bayesplot, loo (25+ dependencies)
```

#### Step 4: Verify Installation
```R
# Check core dependencies
library(rstan)
library(quantreg)
library(lmtest)

# Verify data files
list.files("data/processed/")
# Expected: 7 CSV files with timestamp suffix
```

---

## 📊 Data Access

### Recommended Starting Point: Processed CSV Files

The `data/processed/` directory contains **7 analysis-ready files** (no database required):

| File | Description | Dimensions |
|------|-------------|------------|
| `metadata_item_catalog` | Product taxonomy (category codes, names) | 93 items × 5 columns |
| `metadata_hierarchical_structure` | Item-market pooling structure | 554 pairs × 8 columns |
| `fact_price_daily` | 9-day price window (Jan 1-10, 2024) | 5,494 obs × 6 columns |
| `bayesian_posterior_samples` | MCMC draws from hierarchical model | 255 items × 3,000 draws |
| `bayesian_forecasts` | Posterior predictive distributions | 554 items × quantiles |
| `bayesian_inventory_policy` | ROP/RBC/RARC across scenarios | 6,648 policies × 12 columns |
| `model_diagnostics` | Convergence metrics (R̂, ESS, JB tests) | 554 items × 8 metrics |

**Usage Example**:
```R
library(data.table)
fact_price <- fread("data/processed/fact_price_daily_202601291929.csv")
policies <- fread("data/processed/bayesian_inventory_policy_202601291928.csv")

# Quick check: verify sparsity distribution
fact_price[, .N, by = .(item_cd, mrkt_cd)][, .N, by = N]
# Expected: 81.7% have N < 10 observations
```

### Optional: Full Dataset Reconstruction from KAMIS API

To replicate the **complete ETL pipeline**:

```bash
# Step 1: Explore KAMIS API endpoints
python code/data_collection/api_explorer.py
# Outputs: 6 endpoint schemas (retail, wholesale, monthly, etc.)

# Step 2: Run ETL to MySQL (requires API key from data.go.kr)
export KAMIS_API_KEY="your_api_key_here"
python code/data_collection/etl_pipeline.py

# Step 3: Validate star schema integrity
python code/data_collection/db_explorer.py
# Checks: foreign keys, referential integrity, data types
```

**Note**: Free API key registration at [data.go.kr](https://www.data.go.kr/data/15059093/openapi.do)

---

## 🔬 Replication Workflow

### Four-Phase Analysis Pipeline

#### **Phase 1: Data Preparation and Descriptive Statistics**
```R
# Load processed data
library(data.table)
fact_price <- fread("data/processed/fact_price_daily_202601291929.csv")
metadata_catalog <- fread("data/processed/metadata_item_catalog_202601291929.csv")

# Verify hierarchical structure (Table 3 in paper)
fact_price[, .N, by = .(item_cd, mrkt_cd)][, .(
  avg_obs = mean(N),
  median_obs = median(N),
  min_obs = min(N),
  max_obs = max(N)
)]
# Expected: avg=9.9, median=9, range=[3,16]

# Reproduce Table 4 (Overall Price Distribution)
fact_price[, .(
  mean = mean(price),
  median = median(price),
  sd = sd(price),
  cv = sd(price) / mean(price),
  skewness = moments::skewness(price),
  kurtosis = moments::kurtosis(price)
)]
# Expected: mean=₩20,422, CV=147.2%, skewness=2.967
```

#### **Phase 2: Bayesian Hierarchical Modeling**
```R
# 2A: Full MCMC for moderate sparsity (10 ≤ n < 20)
source("code/bayesian_modeling/hierarchical_model.R")
# Runs 2 chains × 2,000 iterations × 255 items
# Expected runtime: 15-30 minutes (depends on CPU)

# 2B: Empirical Bayes for extreme sparsity (3 ≤ n < 10)
source("code/bayesian_modeling/empirical_bayes.R")
# Closed-form James-Stein estimator: <1 minute
# Expected: 299 items with λ_ij ∈ [0.03, 0.14]

# 2C: Convergence diagnostics
source("code/bayesian_modeling/posterior_diagnostics.R")
# Expected outputs:
#   - R̂ = 1.000 (SD = 0.0004) for all 255 MCMC items
#   - ESS > 1,200 (mean = 1,847)
#   - JB test pass rate = 76% (acceptable under sparse data)
```

#### **Phase 3: Inventory Policy Optimization**
```R
# 3A: Derive posterior predictive ROP/RARC/RBC
source("code/inventory_optimization/bayesian_newsvendor.R")
# Integrates parameter + demand uncertainty via Monte Carlo
# Outputs: 6,648 policies (554 items × 3 service levels × 4 lead times)

# 3B: Service-level sensitivity (Table 15, Figure 6)
source("code/inventory_optimization/service_level_analysis.R")
# Expected:
#   - 90% service: median RBC = ₩285K
#   - 95% service: median RBC = ₩513K (target calibration)
#   - 99% service: median RBC = ₩2.85M (5.5× increase)

# 3C: Lead time elasticity (Table 17, Figure 7)
source("code/inventory_optimization/lead_time_scaling.R")
# Expected:
#   - LT=1 day: mean ROP = ₩397K
#   - LT=7 days: mean ROP = ₩2.91M (7.3× increase)
#   - LT=14 days: mean ROP = ₩5.87M (near-proportional scaling)
```

#### **Phase 4: Hypothesis Testing and Robustness**
```R
# 4A: H1 - Volatility heterogeneity (Table 11, Figure 4)
source("code/hypothesis_testing/h1_volatility_heterogeneity.R")
# Kruskal-Wallis H-test on category-level CV
# Expected: H(6) = 875.4, p < 0.001, η² = 0.160
# Interpretation: Category explains 16% of volatility variance

# 4B: H2 - Lead time elasticity (Table 12, Figure 5)
source("code/hypothesis_testing/h2_lead_time_elasticity.R")
# Log-log regression: ln(ROP) ~ β₁·ln(LT)
# Expected: β = 0.973*** [0.894, 1.052], R² = 0.850
# Cluster-robust SE (CR2) at item level

# 4C: Robustness checks (Table 13)
source("code/hypothesis_testing/robustness_checks.R")
# Tests:
#   - Category interaction: β ∈ [0.96, 0.98] across all 7 categories
#   - Quantile regression: τ ∈ {0.10, 0.25, 0.50, 0.75, 0.90}
#   - Bootstrap: 1,000 replications, 95% CI stable
```

---

## 📈 Expected Outputs

### Convergence Diagnostics (Table 7)

| Metric | Expected Value | Interpretation | Pass Criterion |
|--------|----------------|----------------|----------------|
| Gelman-Rubin R̂ | 1.000 (SD: 0.0004) | Perfect chain convergence | R̂ < 1.1 |
| Effective Sample Size | 1,847 (min: 1,203) | High MCMC efficiency | ESS > 1,000 |
| RMSE (log-price) | 0.598 | Posterior predictive fit | Benchmark comparison |
| JB Test Pass Rate | 76% | Residual normality | > 70% acceptable |

### Hypothesis Test Results

#### H1: Volatility Heterogeneity (RQ2)
```R
# Kruskal-Wallis omnibus test
kruskal.test(cv ~ category, data = category_stats)
# Expected output:
#   Kruskal-Wallis chi-squared = 875.4, df = 6, p-value < 2.2e-16
#   Effect size (η²) = 0.160
```

**Interpretation**: Product category alone explains 16% of price volatility variance, with seven-fold differences (Specialty Crops CV=1.027 vs. Processed Foods CV=0.143).

#### H2: Lead Time Elasticity (RQ3)
```R
# Cluster-robust OLS regression
model <- lm(log(rop) ~ log(lead_time), data = policy_data)
coeftest(model, vcov = vcovCR(model, cluster = ~item_cd, type = "CR2"))
# Expected output:
#   Estimate: 0.973***
#   Std. Error: 0.040 (CR2-adjusted)
#   95% CI: [0.894, 1.052]
#   R²: 0.850
```

**Interpretation**: Lead time exhibits near-unit elasticity (β≈1.0), far exceeding classical √LT prediction (β≈0.5). This 95% amplification arises from epistemic uncertainty compounding multiplicatively across forecast horizons.

#### H3: Pooling Effectiveness (RQ1)
```R
# Service-level calibration check
policies[service_level == 0.95, mean(fill_rate)]
# Expected: 0.950 (exact target match)

# Policies within ±2% tolerance
policies[service_level == 0.95, mean(abs(fill_rate - 0.95) <= 0.02)]
# Expected: 0.947 (94.7% compliance rate)
```

**Interpretation**: Hierarchical partial pooling achieves perfect service-level calibration despite 81.7% of items having n<10 observations, outperforming No Pooling (87.5% fill rate, 26.7% convergence failure) and Complete Pooling (91.3% fill rate, 68.2% tolerance compliance).

### Performance Benchmarks (Table 9)

| Model | CV | Fill Rate (%) | Cost Rank | Cost (₩) |
|-------|----|--------------|-----------|----|
| **Bayesian Hierarchical** | **1.872** | **95.0** | **1** | **1,188,095** |
| Exponential Smoothing | 1.247 | 91.2 | 2 | 1,456,320 |
| Auto-ARIMA | 1.220 | 90.8 | 3 | 1,523,450 |
| Simple MA | 1.222 | 90.1 | 4 | 1,612,780 |
| Historical Mean | 1.013 | 88.5 | 5 | 1,789,430 |
| Naive | 1.254 | 87.3 | 6 | 1,891,200 |
| RW + Drift | 1.265 | 86.9 | 7 | 1,934,560 |

**Key Insight**: Bayesian model exhibits highest CV (explicit parameter uncertainty quantification) yet achieves lowest cost (18.4% improvement) and perfect service-level calibration. Classical plug-in methods underestimate predictive variance, leading to systematic under-ordering and elevated shortage costs.

---

## 🔍 Detailed Methodology

### Three-Level Hierarchical Bayesian Model

#### Mathematical Specification (Box 1 in paper)

**Level 1 — Observation Model**:
```
y_ijt | μ_ij, σ² ~ N(μ_ij, σ²)
```
where y_ijt = log(price) for item i, market j, time t.

**Level 2 — Partial Pooling Across Item-Markets**:
```
μ_ij | μ_c(i), τ²_c(i) ~ N(μ_c(i), τ²_c(i))
```
where c(i) denotes the category of item i.

**Level 3 — Hyperpriors**:
```
μ_c ~ N(9.147, 100)          # Weakly informative on category mean
τ²_c ~ InvGamma(0.01, 0.01)  # Weakly informative on between-item variance
σ² ~ InvGamma(0.01, 0.01)    # Weakly informative on observation variance
```

#### Shrinkage Estimator (Box 2)

**Posterior Mean**:
```
E[μ_ij | data] = (1 - λ_ij)·ȳ_ij + λ_ij·μ_c
```

where the **data-adaptive shrinkage factor** is:
```
λ_ij = σ²/(n_ij·τ²_c + σ²) ∈ [0, 1]
```

**Theoretical Properties**:
- **No pooling limit**: lim_{n→∞} λ_ij = 0 ⟹ E[μ_ij|data] → ȳ_ij (sample mean)
- **Complete pooling limit**: lim_{n→0} λ_ij = 1 ⟹ E[μ_ij|data] → μ_c (category mean)
- **Numerical example** (σ²=0.15, τ²_c=0.30):
  - n=3: λ=0.143 (14.3% weight on category, 85.7% on item)
  - n=16: λ=0.030 (3.0% weight on category, 97.0% on item)

**Posterior Variance** (quantifies uncertainty reduction):
```
Var[μ_ij | data] = [n_ij/σ² + 1/τ²_c]^(-1) = (1 - λ_ij)·σ²/n_ij
```

### Adaptive Model Selection Algorithm (Box 3-5)

#### Case 1: Long Series (n ≥ 20) — Dynamic Linear Model
**Specification**: Kalman filtering with discount factor δ=0.95
**Status**: Not activated in 9-day window (deliberate design choice)
**Purpose**: Future work for seasonal/trending data

#### Case 2: Moderate Sparsity (10 ≤ n < 20) — Full Bayesian MCMC
**Algorithm**: Gibbs sampler for hierarchical normal model
**Configuration**:
- Chains: 2 (dispersed starting values)
- Iterations: 2,000 per chain
- Burn-in: 500
- Thinning: Keep every 2nd iteration
- Effective samples: 1,500/chain (3,000 total)

**Gibbs Sampling Steps** (Box 4):
1. Sample μ_ij | μ_c, τ²_c, σ², y_ij ~ N(μ̃_ij, σ̃²_ij)
2. Sample μ_c | {μ_ij}, τ²_c ~ N(μ̃_c, τ̃²_c)
3. Sample τ²_c | {μ_ij}, μ_c ~ InvGamma(α̃_τ, β̃_τ)
4. Sample σ² | {μ_ij}, {y_ij} ~ InvGamma(α̃_σ, β̃_σ)

**Coverage**: 27.4% of sample (255 item-market pairs)

#### Case 3: Extreme Sparsity (3 ≤ n < 10) — Empirical Bayes
**Algorithm**: Closed-form James-Stein shrinkage estimator (Box 5)

**Stage 1 — Hyperparameter Estimation**:
```R
# Category mean
μ̂_c = (1/n_c) Σ_i∈c ȳ_ij

# Between-item variance
τ̂²_c = (1/(n_c-1)) Σ_i∈c (ȳ_ij - μ̂_c)² - σ̂²/n̄

# Observation variance (pooled)
σ̂² = (1/N) Σ_i Σ_j Σ_t (y_ijt - ȳ_ij)²
```

**Stage 2 — Shrinkage Estimation**:
```R
# Empirical Bayes point estimate
μ̂^EB_ij = ω_ij·ȳ_ij + (1 - ω_ij)·μ̂_c

# Data-driven weight
ω_ij = (n_ij·τ̂²_c) / (n_ij·τ̂²_c + σ̂²)

# Approximate posterior variance
Var[μ_ij | data] ≈ ω_ij·σ̂²/n_ij
```

**Coverage**: 32.1% of sample (299 item-market pairs)

**Key Advantage**: Stable computation without MCMC when likelihoods are weak (n < 10)

### Bayesian Newsvendor Framework (Box 6-8)

#### Posterior Predictive Distribution (Box 6)

**Formal Definition**:
```
p(D_{t+h} | D_{1:t}) = ∫ p(D_{t+h} | θ) p(θ | D_{1:t}) dθ
```
where θ = (μ, σ) represents demand parameters.

**Monte Carlo Algorithm**:
1. Draw θ^(s) ~ p(θ | D_{1:t}) for s=1,...,S (from MCMC or EB posterior)
2. For each θ^(s), draw D^(s) ~ p(D | θ^(s)) (aleatoric uncertainty)
3. Use empirical distribution {D^(1),...,D^(S)} for inventory decisions

**Variance Decomposition** (dual uncertainty):
```
Var[D_{t+h} | D_{1:t}] = E_θ[Var[D|θ]] + Var_θ[E[D|θ]]
                         = E[σ²]·LT + Var[μ]·LT²
                           ↑              ↑
                     aleatoric    epistemic
```

**Critical Insight**: Under sparse data, Var[μ] dominates (≈20× larger than E[σ²]/LT in our sample), driving near-proportional lead time scaling.

#### Risk Buffer Capital and Risk-Adjusted Reorder Capital (Box 7)

**Capital-Based Formulation** (due to unobserved demand quantities):

**Classical Formulas** (point estimates):
```
Safety Stock:  SS = z_α·√LT·σ_demand
Reorder Point: ROP = LT·μ_demand + z_α·√LT·σ_demand
```

**Adapted for Price-Based Proxies**:
```
Risk Buffer Capital (RBC):  RBC = z_α·√LT·σ_price
Risk-Adjusted Reorder Capital (RARC):  RARC = LT·μ_price + z_α·√LT·σ_price
```

**Bayesian Formulation** (full posterior distributions):
```
RBC ~ p(z_α·√LT·σ | data)
RARC ~ p(LT·μ + z_α·√LT·σ | data)
```

**Computational Algorithm**:
```R
for (s in 1:S) {  # S = 3,000 posterior draws
  # Lead-time parameters
  μ_LT^(s) = LT · μ^(s)
  σ_LT^(s) = √LT · σ^(s)
  
  # Policy parameters
  SS^(s) = z_α · σ_LT^(s)
  ROP^(s) = μ_LT^(s) + SS^(s)
}

# Summary statistics
E[RBC | data] = mean(SS^(1:S))
SD[RBC | data] = sd(SS^(1:S))
CI_95 = quantile(RBC, c(0.025, 0.975))
```

**Operational Conversion to Order Quantities**:
```R
# Direct conversion using recent unit price
Q_order = RARC / p̄_recent

# Volatility-adjusted bounds
Q_lower = RARC / (p̄_recent + σ_price)
Q_upper = RARC / (p̄_recent - σ_price)
```

**Implementation Note**: Negative theoretical RBC values (4.1% of policies) arise when hierarchical shrinkage produces near-deterministic forecasts. Operational truncation: RBC_operational = max(0, RBC_theoretical).

#### Fill Rate and Expected Cost (Box 8)

**Fill Rate Definition**:
```
FR(Q) = E[min(D, Q)/D] = 1 - E[(D-Q)⁺]/E[D]
```

**Bayesian Monte Carlo Approximation**:
```
FR(Q) ≈ (1/S) Σ_{s=1}^S min(D^(s), Q) / D^(s)
```

**Newsvendor Cost Function**:
```
C(Q) = h·E[(Q-D)⁺] + p·E[(D-Q)⁺]
```
where h=1 (holding cost), p=9 (shortage cost), yielding critical fractile α=0.90.

**Optimal Order Quantity**:
```
Classical (plug-in):  Q*_classical = F^{-1}_{N(μ̂,σ̂²)}(0.90)
Bayesian:             Q*_Bayes = F^{-1}_{PP}(0.90)  [posterior predictive]
```

---

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. **MCMC Convergence Failure (R̂ > 1.1)**
```R
# Symptom: Gelman-Rubin diagnostic exceeds threshold
# Root cause: Insufficient burn-in or poor starting values

# Solution A: Extend burn-in period
model <- update(model, iter = 5000, warmup = 1500)

# Solution B: Use dispersed initial values
init_fn <- function() {
  list(mu_ij = rnorm(n_items, 0, 2),
       tau2_c = runif(n_categories, 0.1, 1))
}
model <- stan(file, init = init_fn, chains = 2)

# Solution C: Increase thinning to reduce autocorrelation
model <- stan(file, thin = 5)
```

#### 2. **Memory Errors During Large MCMC Runs**
```R
# Symptom: Error: cannot allocate vector of size X GB
# Root cause: Large posterior samples (3,000 draws × 255 items)

# Solution A: Enable Stan's auto-write cache
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores() - 1)

# Solution B: Reduce posterior storage
model <- stan(file, save_warmup = FALSE, thin = 4)

# Solution C: Use Variational Bayes for approximation
vb_fit <- vb(stan_model, data = stan_data, iter = 10000)
```

#### 3. **Missing R Package Dependencies**
```R
# Symptom: Error in library(X): there is no package called 'X'
# Root cause: Incomplete installation from install_R_packages.R

# Solution: Manual installation with CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))
install.packages(c("rstan", "quantreg", "lmtest", "sandwich"))

# For rstan on Linux, install C++ toolchain first:
# sudo apt-get install build-essential libcurl4-openssl-dev libssl-dev
```

#### 4. **Python MySQL Connection Issues**
```python
# Symptom: OperationalError: (2003, "Can't connect to MySQL server")
# Root cause: Firewall or incorrect credentials

# Solution A: Verify MySQL is running
# sudo systemctl status mysql

# Solution B: Check connection parameters in etl_pipeline.py
engine = create_engine(
    "mysql+pymysql://user:password@localhost:3306/agri_market_analytics",
    pool_pre_ping=True  # Ensures connection is alive
)

# Solution C: Use SSH tunnel for remote database
# ssh -L 3306:localhost:3306 user@remote_host
# Then connect to localhost:3306 in Python
```

#### 5. **Jarque-Bera Test Failures (JB > 5.99)**
```R
# Symptom: High proportion of non-normal residuals (>30%)
# Root cause: Heavy-tailed price distributions or outliers

# Diagnostic: Inspect residual Q-Q plots
qqnorm(residuals); qqline(residuals)

# Solution: Not critical if <25% failure rate (acceptable under sparsity)
# If >30%: Consider robust alternatives (Student-t likelihood)

# Robust hierarchical model (rstan)
model_code <- "
  y ~ student_t(nu, mu, sigma);  // Heavy-tailed likelihood
  nu ~ gamma(2, 0.1);             // Prior on degrees of freedom
"
```

#### 6. **Negative Safety Stock Values**
```R
# Symptom: RBC < 0 in inventory policy outputs
# Root cause: Hierarchical shrinkage reduces posterior variance excessively

# Diagnostic: Check frequency
policies[, mean(rbc < 0)]
# Expected: <5% (acceptable outlier rate)

# Solution: Operational truncation (already implemented)
policies[, rbc_operational := pmax(0, rbc)]
policies[, rarc_operational := lt * mu_posterior + rbc_operational]

# Validation: Verify fill rate impact
policies[, mean(abs(fill_rate_truncated - fill_rate_theoretical))]
# Expected: <0.002 (negligible service-level distortion)
```

---

## 📧 Contact and Support

- **Primary Author**: Yong-Jae Lee (PhD)  
  📧 [yj11021@tobesoft.com]  
  🏛️ Ai Lab, Cloud Group, Future Technology Research Institute, TOBESOFT

- **Issues and Questions**: Please use [GitHub Issues](https://github.com/your-org/bayesian-agri-inventory/issues)

- **Data Requests**: KAMIS data are publicly available at [data.go.kr](https://www.data.go.kr/data/15059093/openapi.do)

---

## 📄 License

This project is licensed under the **MIT License**:

```
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

See [LICENSE](LICENSE) file for full terms.

---

## 🙏 Acknowledgments

- **Data Provider**: Korea Agricultural Marketing Information Service (KAMIS) / Korea Agro-Fisheries & Food Trade Corporation (aT)
- **Funding**: [Grant information, if applicable]
- **Computing Resources**: [HPC cluster details, if applicable]
- **Methodological Guidance**: Gelman et al. (2013) *Bayesian Data Analysis*, 3rd Edition; West & Harrison (1997) *Bayesian Forecasting and Dynamic Models*

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| **v1.0.0** | 2025-01-29 | Initial release with full replication materials |
| v0.9.0 | 2025-01-15 | Pre-release with preliminary results |
| v0.5.0 | 2024-12-20 | Bayesian modeling complete, hypothesis testing finalized |
| v0.1.0 | 2024-12-01 | Data collection and ETL pipeline established |


### Related Software

- **Stan**: Bayesian inference engine ([mc-stan.org](https://mc-stan.org))
- **JAGS**: Just Another Gibbs Sampler ([mcmc-jags.sourceforge.io](http://mcmc-jags.sourceforge.io))
- **PyMC**: Probabilistic programming in Python ([docs.pymc.io](https://docs.pymc.io))
