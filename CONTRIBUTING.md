# Contributing to Bayesian Agricultural Inventory Optimization

Thank you for your interest in contributing to this research project! This document provides guidelines for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in all interactions.

### Expected Behavior

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

---

## How Can I Contribute?

### Reporting Bugs

Before submitting a bug report:
1. Check the existing issues to avoid duplicates
2. Collect relevant information (OS, Python/R versions, error messages)
3. Include a minimal reproducible example

**Bug Report Template:**

```markdown
**Description**
A clear description of the bug.

**To Reproduce**
Steps to reproduce the behavior:
1. Load data with '...'
2. Run analysis '...'
3. See error

**Expected Behavior**
What you expected to happen.

**Environment**
- OS: [e.g., Ubuntu 22.04]
- Python version: [e.g., 3.10]
- R version: [e.g., 4.3]
- Package versions: [key packages]

**Additional Context**
Any other relevant information.
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:
1. Use a clear and descriptive title
2. Provide a detailed description of the proposed feature
3. Explain why this enhancement would be useful
4. Include examples if possible

### Contributing Code

Areas where contributions are especially welcome:

#### Data Collection & Processing
- Additional API endpoints integration
- Data cleaning improvements
- Feature engineering enhancements
- ETL pipeline optimization

#### Bayesian Modeling
- Alternative hierarchical structures
- Convergence diagnostics improvements
- Prior sensitivity analysis
- Model comparison frameworks

#### Inventory Optimization
- Alternative service level strategies
- Multi-echelon inventory systems
- Dynamic programming approaches
- Reinforcement learning integration

#### Visualization
- Interactive dashboards
- Additional diagnostic plots
- Publication-quality figure templates

#### Documentation
- Tutorial notebooks
- Video walkthroughs
- Methodology explanations
- Case studies

---

## Development Setup

### Prerequisites

- Python 3.8+ (3.10 recommended)
- R 4.0+ (4.3 recommended)
- Git
- MySQL 8.0+ (for database replication)

### Installation Steps

1. **Fork and clone the repository:**

```bash
git clone https://github.com/YOUR-USERNAME/bayesian-agri-inventory.git
cd bayesian-agri-inventory
```

2. **Set up Python environment:**

```bash
# Using conda (recommended)
conda env create -f environment.yml
conda activate agri-inventory

# Or using pip
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development dependencies
```

3. **Install R packages:**

```r
source("install_R_packages.R")
```

4. **Set up pre-commit hooks:**

```bash
pre-commit install
```

### Development Dependencies

Create `requirements-dev.txt` with:

```
# Testing
pytest>=7.0
pytest-cov>=4.0
hypothesis>=6.0

# Code quality
black>=23.0
flake8>=6.0
mypy>=1.0
pylint>=2.15

# Documentation
sphinx>=5.0
sphinx-rtd-theme>=1.0
nbsphinx>=0.8

# Jupyter
jupyter>=1.0
jupyterlab>=3.0
```

---

## Coding Standards

### Python Style Guide

Follow **PEP 8** with these specifics:

```python
# Good: Clear function names and docstrings
def calculate_reorder_point(
    demand_mean: float,
    demand_std: float,
    lead_time: int,
    service_level: float = 0.95
) -> float:
    """Calculate reorder point using newsvendor model.
    
    Args:
        demand_mean: Expected demand per period
        demand_std: Standard deviation of demand
        lead_time: Lead time in days
        service_level: Target service level (0-1)
        
    Returns:
        Reorder point in units
        
    Example:
        >>> calculate_reorder_point(100, 20, 7, 0.95)
        782.6
    """
    from scipy import stats
    z_score = stats.norm.ppf(service_level)
    rop = lead_time * demand_mean + z_score * np.sqrt(lead_time) * demand_std
    return rop
```

**Key Points:**
- Line length: 100 characters (not 79)
- Use type hints
- Docstrings: Google style
- Imports: Standard library → Third party → Local
- Use `black` for automatic formatting

### R Style Guide

Follow **tidyverse style guide**:

```r
# Good: Clear and consistent
calculate_safety_stock <- function(demand_std, lead_time, z_score) {
  # Calculate safety stock
  # 
  # Args:
  #   demand_std: Standard deviation of demand
  #   lead_time: Lead time in days
  #   z_score: Z-score for service level
  #
  # Returns:
  #   Safety stock in units
  
  safety_stock <- z_score * sqrt(lead_time) * demand_std
  return(safety_stock)
}
```

**Key Points:**
- Variable names: `snake_case`
- Line length: 80-100 characters
- Use `<-` for assignment (not `=`)
- Space after commas
- Comments: `#` followed by space

### SQL Style Guide

```sql
-- Good: Readable and well-structured
SELECT 
    i.item_nm AS item_name,
    COUNT(*) AS transaction_count,
    ROUND(AVG(f.price), 2) AS avg_price
FROM fact_price_daily f
INNER JOIN dim_item i ON f.item_id = i.item_id
WHERE f.date_key >= 20250101
    AND f.price > 0
GROUP BY i.item_id, i.item_nm
ORDER BY transaction_count DESC
LIMIT 10;
```

---

## Testing Guidelines

### Python Tests

Use `pytest` for all Python code:

```python
# tests/test_inventory.py
import pytest
from src.inventory import calculate_reorder_point

def test_reorder_point_basic():
    """Test basic ROP calculation."""
    rop = calculate_reorder_point(
        demand_mean=100,
        demand_std=20,
        lead_time=7,
        service_level=0.95
    )
    assert 700 < rop < 800, "ROP should be in reasonable range"

def test_reorder_point_zero_std():
    """Test ROP with zero variance."""
    rop = calculate_reorder_point(
        demand_mean=100,
        demand_std=0,
        lead_time=7,
        service_level=0.95
    )
    assert rop == 700, "ROP should equal mean demand when std=0"

@pytest.mark.parametrize("service_level,expected_min", [
    (0.90, 700),
    (0.95, 750),
    (0.99, 800),
])
def test_reorder_point_service_levels(service_level, expected_min):
    """Test ROP increases with service level."""
    rop = calculate_reorder_point(100, 20, 7, service_level)
    assert rop >= expected_min
```

### R Tests

Use `testthat` for R code:

```r
# tests/testthat/test_inventory.R
library(testthat)

test_that("Safety stock calculation works", {
  ss <- calculate_safety_stock(
    demand_std = 20,
    lead_time = 7,
    z_score = 1.96
  )
  
  expect_gt(ss, 0)
  expect_lt(ss, 200)
  expect_type(ss, "double")
})

test_that("Safety stock increases with service level", {
  ss_90 <- calculate_safety_stock(20, 7, qnorm(0.90))
  ss_95 <- calculate_safety_stock(20, 7, qnorm(0.95))
  
  expect_gt(ss_95, ss_90)
})
```

### Running Tests

```bash
# Python
pytest tests/ --cov=src --cov-report=html

# R
R CMD check .
Rscript -e "devtools::test()"
```

---

## Documentation Standards

### Code Documentation

**Python:**
- All public functions/classes: Docstrings
- Use Google style
- Include examples for complex functions

**R:**
- Use roxygen2 comments
- Include `@param`, `@return`, `@examples`

### File Documentation

Every source file should have:

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Module: Inventory optimization calculations

This module provides functions for calculating optimal inventory
policies under uncertainty using Bayesian methods.

Author: [Your Name]
Date: 2025-01-29
"""
```

### Markdown Documentation

- Use ATX-style headers (`#`, `##`, `###`)
- Include table of contents for long documents
- Use code blocks with language identifiers
- Keep line length reasonable (~100 chars)

---

## Pull Request Process

### Before Submitting

1. **Update documentation** for any changed functionality
2. **Add tests** for new features
3. **Run all tests** and ensure they pass
4. **Update CHANGELOG.md** with your changes
5. **Check code style** with linters

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] CHANGELOG.md updated
- [ ] All tests passing

## Related Issues
Fixes #123
```

### Review Process

1. Submit PR with clear title and description
2. Wait for automated checks (CI/CD)
3. Address reviewer feedback
4. Maintainer will merge when approved

---

## Commit Message Guidelines

Use **Conventional Commits**:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (no logic change)
- `refactor`: Code restructuring
- `test`: Adding/updating tests
- `chore`: Maintenance

**Examples:**

```
feat(inventory): Add multi-echelon optimization support

Implement hierarchical inventory optimization for
multi-stage supply chains.

Closes #45

---

fix(api): Handle missing price data gracefully

Check for null values before processing to prevent
crashes when API returns incomplete data.

---

docs(readme): Update installation instructions

Add conda installation steps and troubleshooting section.
```

---

## Questions?

- **General questions**: Open a GitHub Discussion
- **Bug reports**: Create an Issue
- **Feature requests**: Create an Issue with "enhancement" label
- **Security issues**: Email [security contact] directly

---

## Attribution

Contributors will be acknowledged in:
- `README.md` (Contributors section)
- Paper acknowledgments (for significant contributions)
- `AUTHORS.md` file

---

Thank you for contributing to advancing inventory optimization research! 🎉
