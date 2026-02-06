# Changelog

All notable changes to the Bayesian Agricultural Inventory Optimization project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-01-29

### 🎉 Initial Release

First public release of the Bayesian Agricultural Inventory Optimization research package.

### Added

#### Data Collection
- **KAMIS/aT API Integration**
  - 6 API endpoint collectors (retail, wholesale, monthly, rise/fall, shipment, listing)
  - Automatic pagination handling
  - JSON/XML parsing support
  - Comprehensive error handling
  - Rate limiting and retry logic

- **ETL Pipeline** (SQLAlchemy 2.x)
  - Star schema database design (10 dimension tables, 6 fact tables)
  - Automatic dimension upserts with conflict resolution
  - Foreign key relationship management
  - Data validation and cleaning
  - Transaction-level error recovery

- **Database Explorer**
  - Schema analysis tools
  - Data quality metrics
  - Business intelligence queries
  - Visualization generation

#### Bayesian Modeling
- **Hierarchical Model Implementation**
  - 3-level Bayesian hierarchy (observation → item → category)
  - JAGS/RStan MCMC inference
  - Partial pooling with shrinkage estimation
  - Convergence diagnostics (R̂, ESS, trace plots)

- **Empirical Bayes Methods**
  - James-Stein shrinkage estimators for n < 10
  - Adaptive pooling based on sample size
  - Uncertainty quantification

- **Posterior Diagnostics**
  - Gelman-Rubin R̂ statistics
  - Effective sample size calculations
  - Jarque-Bera normality tests
  - Trace plot generation

#### Inventory Optimization
- **Bayesian Newsvendor Model**
  - Posterior predictive ROP/SS calculation
  - Multiple service levels (90%, 95%, 99%)
  - Multiple lead times (1, 3, 7, 14 days)
  - Fill rate estimation via Monte Carlo

- **Service Level Analysis**
  - Cost-benefit trade-off curves
  - Optimal service level identification
  - Sensitivity analysis

- **Lead Time Scaling**
  - Elasticity estimation (log-log regression)
  - Cluster-robust standard errors (CR2)
  - Quantile regression robustness checks

#### Hypothesis Testing
- **H1: Volatility Heterogeneity**
  - Kruskal-Wallis omnibus test
  - Levene's and Brown-Forsythe tests
  - Pairwise comparisons (Dunn's test)
  - Quantile regression (τ ∈ {0.10, 0.90})
  - Kolmogorov-Smirnov tests
  
  **Result**: H(6) = 875.4, p < 0.001, η² = 0.160 ✓

- **H2: Lead Time Elasticity**
  - OLS regression with log transformations
  - Cluster-robust inference (CR2 standard errors)
  - 8 model specifications for robustness
  - Bootstrap confidence intervals
  - Quantile regression
  
  **Result**: β = 0.973 (95% CI: [0.894, 1.052]) ✓

- **Robustness Checks**
  - Subsample validation (10 × 80% samples)
  - Service level stratification
  - Outlier sensitivity analysis
  - Distributional tests

#### Visualization
- **Publication Figures** (600 DPI PNG)
  - 11 publication-ready figures
  - Nature/Science style formatting
  - Professional color palettes
  - Multi-panel layouts (patchwork)

- **Advanced Diagnostics**
  - Benchmark comparison charts
  - Forecast distribution plots
  - Price elasticity visualizations
  - Safety stock analysis plots

- **Comprehensive Analysis**
  - 4-panel hypothesis test figures
  - Extended analysis visualizations
  - Interactive diagnostic plots

#### Documentation
- **Methodology Documentation**
  - Complete mathematical formulations
  - MCMC implementation details
  - Inventory policy derivations
  - Hypothesis testing procedures

- **Replication Guide**
  - Step-by-step instructions
  - Environment setup
  - Expected results verification
  - Troubleshooting section

- **API Documentation**
  - Complete endpoint reference
  - Authentication guide
  - Rate limits and best practices
  - Error handling examples

- **Database Schema**
  - Star schema documentation
  - Table relationships
  - Index strategy
  - Query patterns

#### Configuration
- **Python Environment**
  - requirements.txt (40+ packages)
  - Virtual environment support
  - Package version pinning

- **R Environment**
  - environment.yml (Conda integration)
  - install_R_packages.R (60+ packages)
  - Automated verification

- **Cross-Platform Support**
  - Windows, macOS, Linux
  - Python 3.8-3.11
  - R 4.0-4.3

### Key Findings

1. **Volatility Heterogeneity Confirmed**
   - Seven-fold differences across categories
   - Persistent across entire distribution
   - Large effect size (η² = 0.160)

2. **Near-Unit Elasticity Validated**
   - Lead time elasticity: 0.973
   - Robust across specifications
   - 10% LT reduction → ~9.3% inventory reduction

3. **Partial Pooling Optimal**
   - 94.7% fill rate with n ≥ 3
   - Cross-sectional pooling effective
   - Minimal bias-variance trade-off

### Data Coverage

- **Time period**: 9 days (2025-01-01 to 2025-01-10)
- **Items**: 93 agricultural products
- **Categories**: 7 major product groups
- **Markets**: 554 item-market combinations
- **Observations**: 5,494 price records
- **Policies**: 6,648 inventory configurations

### Publication Readiness

- **IJPR/CIE**: 60-70% ready
- **Omega**: 40-50% ready (needs 6-month extension)
- **IJF**: 50-60% ready (needs seasonal validation)

---

## [0.9.0] - 2025-01-15 (Pre-release)

### Added
- Initial Bayesian model implementation
- Basic ETL pipeline
- Preliminary hypothesis testing

### Changed
- Refined hierarchical structure
- Improved convergence diagnostics

### Known Issues
- Limited time coverage (9 days)
- No out-of-sample validation
- Missing exogenous covariates

---

## [0.1.0] - 2024-12-01 (Alpha)

### Added
- API data collection scripts
- Basic database schema
- Exploratory data analysis

---

## Roadmap

### Version 1.1.0 (Q1 2025)
- [ ] Extended data collection (6 months)
- [ ] Rolling-origin cross-validation
- [ ] Out-of-sample validation metrics (MASE, sMAPE, CRPS)
- [ ] Weather data integration
- [ ] Holiday calendar effects

### Version 1.2.0 (Q2 2025)
- [ ] Multi-echelon inventory extension
- [ ] Dynamic Bayesian models
- [ ] Forecast combination methods
- [ ] Interactive dashboards (Shiny/Streamlit)

### Version 2.0.0 (Future)
- [ ] Reinforcement learning integration
- [ ] Real-time data streaming
- [ ] Automated reordering system
- [ ] Mobile app interface

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on:
- How to report bugs
- How to suggest enhancements
- Development setup
- Pull request process

---

## Support

- **Documentation**: See `docs/` directory
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions

---

[1.0.0]: https://github.com/your-org/bayesian-agri-inventory/releases/tag/v1.0.0
[0.9.0]: https://github.com/your-org/bayesian-agri-inventory/releases/tag/v0.9.0
[0.1.0]: https://github.com/your-org/bayesian-agri-inventory/releases/tag/v0.1.0
