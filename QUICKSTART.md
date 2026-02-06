# Quick Start Guide

Get up and running with Bayesian Agricultural Inventory Optimization in 15 minutes!

---

## 🚀 15-Minute Quick Start

### Prerequisites Checklist

- [ ] Python 3.8+ installed
- [ ] R 4.0+ installed  
- [ ] Git installed
- [ ] 8GB RAM available
- [ ] Internet connection (for package installation)

---

## Step 1: Clone Repository (2 minutes)

```bash
git clone https://github.com/your-org/bayesian-agri-inventory.git
cd bayesian-agri-inventory
```

---

## Step 2: Set Up Environment (5 minutes)

### Option A: Conda (Recommended)

```bash
# Create environment
conda env create -f environment.yml

# Activate environment
conda activate agri-inventory
```

### Option B: pip + R

```bash
# Python packages
pip install -r requirements.txt

# R packages
Rscript install_R_packages.R
```

**Expected output:**
```
✓ Installing 40 Python packages...
✓ Installing 60+ R packages...
✓ All packages installed successfully
```

---

## Step 3: Run Quick Test (3 minutes)

### Test Python Environment

```bash
python -c "import pandas, numpy, sqlalchemy; print('✓ Python environment ready')"
```

### Test R Environment

```bash
Rscript -e "library(tidyverse); library(rjags); cat('✓ R environment ready\n')"
```

---

## Step 4: Run Analysis (5 minutes)

### Option A: Use Pre-processed Data (Fastest)

```r
# Launch R
R

# Load processed data
library(data.table)
fact_price <- fread("data/processed/fact_price_daily_202601291929.csv")
inventory_policy <- fread("data/processed/bayesian_inventory_policy_202601291928.csv")

# View summary
cat(sprintf("✓ Loaded %s price observations\n", nrow(fact_price)))
cat(sprintf("✓ Loaded %s inventory policies\n", nrow(inventory_policy)))

# Generate a quick visualization
library(ggplot2)
top_items <- fact_price[, .N, by = item_nm][order(-N)][1:10]
ggplot(top_items, aes(x = reorder(item_nm, N), y = N)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Top 10 Items by Transaction Count", x = NULL, y = "Count") +
  theme_minimal()

ggsave("quick_test_plot.png", width = 8, height = 6, dpi = 150)
cat("✓ Plot saved to quick_test_plot.png\n")
```

### Option B: Run Full Analysis Pipeline

```r
# Run Bayesian model
source("code/bayesian_modeling/hierarchical_model.R")

# Generate inventory policies
source("code/inventory_optimization/bayesian_newsvendor.R")

# Test hypotheses
source("code/hypothesis_testing/h1_volatility_heterogeneity.R")

# Create visualizations
source("code/visualization/publication_figures.R")
```

**Expected runtime:** 
- Bayesian model: 5-15 minutes
- Inventory policies: 2-5 minutes
- Hypothesis tests: 3-7 minutes
- Visualizations: 1-3 minutes

**Total:** ~15-30 minutes

---

## Verify Installation

### Python Verification

```python
import pandas as pd
import numpy as np
from sqlalchemy import create_engine

# Check versions
print(f"pandas: {pd.__version__}")
print(f"numpy: {np.__version__}")
print("✓ Python environment verified")
```

### R Verification

```r
library(tidyverse)
library(data.table)
library(rjags)
library(ggplot2)

cat("✓ R environment verified\n")
cat("Package versions:\n")
cat(sprintf("  - tidyverse: %s\n", packageVersion("tidyverse")))
cat(sprintf("  - data.table: %s\n", packageVersion("data.table")))
cat(sprintf("  - rjags: %s\n", packageVersion("rjags")))
```

---

## Expected Results

After running the analysis, you should have:

### Generated Files

```
results/
├── figures/
│   ├── Figure1_H1_Volatility_Heterogeneity.png      ✓
│   ├── Figure3_H2_Lead_Time_Effect.png              ✓
│   ├── Figure5_Parameter_Estimates.png              ✓
│   └── ... (11 total figures)
├── tables/
│   ├── Table1_H1_Category_Statistics.docx           ✓
│   ├── Table3_H2_Regression_Results.docx            ✓
│   └── ... (4 total tables)
└── logs/
    └── analysis_log_[timestamp].txt                 ✓
```

### Key Statistics to Verify

```r
# Load results
h1_results <- readRDS("results/h1_full_results.rds")
h2_results <- readRDS("results/h2_full_results.rds")

# Verify H1 (Volatility Heterogeneity)
cat("H1 Kruskal-Wallis H-statistic:", h1_results$kw$h_statistic, "\n")
# Expected: H ≈ 875.4

# Verify H2 (Lead Time Elasticity)
cat("H2 Elasticity:", h2_results$cr2$elasticity, "\n")
# Expected: β ≈ 0.973
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Package Installation Fails

**Symptom:** `ERROR: Could not install package 'rjags'`

**Solution:**
```bash
# On Ubuntu/Debian
sudo apt-get install jags

# On macOS
brew install jags

# On Windows
# Download from: https://sourceforge.net/projects/mcmc-jags/
```

#### Issue 2: Memory Error

**Symptom:** `Error: vector memory exhausted`

**Solution:**
```r
# Increase R memory limit (Windows)
memory.limit(size = 16000)  # 16GB

# Or use smaller dataset for testing
fact_price_sample <- fact_price[sample(.N, 1000)]
```

#### Issue 3: MCMC Not Converging

**Symptom:** `Warning: R-hat > 1.1`

**Solution:**
```r
# Increase iterations
model <- update(model, iter = 5000, warmup = 2000)
```

#### Issue 4: Python Import Error

**Symptom:** `ModuleNotFoundError: No module named 'pandas'`

**Solution:**
```bash
# Ensure virtual environment is activated
conda activate agri-inventory

# Or reinstall packages
pip install -r requirements.txt --force-reinstall
```

---

## Next Steps

### 1. Explore the Data (30 minutes)

```r
# Load and explore
source("code/data_collection/db_explorer.py")  # Python
source("code/visualization/advanced_diagnostics.R")  # R
```

### 2. Run Full Replication (1-2 hours)

Follow detailed instructions in `docs/REPLICATION_GUIDE.md`

### 3. Read Methodology (1 hour)

Study `docs/METHODOLOGY.md` for mathematical details

### 4. Customize for Your Data

- Modify `code/data_collection/api_explorer.py` for your data source
- Adjust priors in `code/bayesian_modeling/hierarchical_model.R`
- Update inventory parameters in `code/inventory_optimization/`

---

## Learning Resources

### Essential Reading

1. **Start here:** `README.md` - Project overview
2. **Next:** `docs/REPLICATION_GUIDE.md` - Detailed walkthrough
3. **Deep dive:** `docs/METHODOLOGY.md` - Mathematical foundations

### Code Examples

- `code/visualization/publication_figures.R` - Figure generation
- `code/bayesian_modeling/hierarchical_model.R` - MCMC implementation
- `code/hypothesis_testing/h1_volatility_heterogeneity.R` - Statistical tests

### Video Tutorials (Coming Soon)

- Setting up the environment
- Running the full pipeline
- Interpreting results
- Customizing for your data

---

## Getting Help

### Documentation

- **README**: Project overview and quick start
- **REPLICATION_GUIDE**: Detailed step-by-step instructions
- **METHODOLOGY**: Mathematical and statistical details
- **API_DOCUMENTATION**: Data source reference
- **DATABASE_SCHEMA**: Data structure

### Support Channels

1. **GitHub Issues**: Bug reports and feature requests
2. **GitHub Discussions**: General questions and ideas
3. **Documentation**: Check `docs/` folder first

### Before Asking for Help

- [ ] Checked documentation
- [ ] Searched existing issues
- [ ] Verified environment setup
- [ ] Tried troubleshooting steps above
- [ ] Prepared minimal reproducible example

---

## Success Checklist

After completing this guide, you should:

- [ ] Have working Python and R environments
- [ ] Successfully loaded processed data
- [ ] Generated at least one figure
- [ ] Verified key statistical results
- [ ] Know where to find detailed documentation
- [ ] Understand next steps for your workflow

---

## Congratulations! 🎉

You're now ready to:

✅ Replicate published results  
✅ Explore the agricultural price data  
✅ Run Bayesian inventory optimization  
✅ Test statistical hypotheses  
✅ Generate publication-quality figures  

**Next:** Read `docs/REPLICATION_GUIDE.md` for the complete analysis workflow.

---

## Quick Reference Card

```
# Activate environment
conda activate agri-inventory

# Run analysis
Rscript -e "source('code/visualization/publication_figures.R')"

# Check results
ls results/figures/

# Deactivate
conda deactivate
```

**Need more help?** → `docs/REPLICATION_GUIDE.md`

**Found a bug?** → GitHub Issues

**Have a question?** → GitHub Discussions

---

*Last updated: January 29, 2025*
