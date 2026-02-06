# Data Directory

This directory contains all data files used in the Bayesian Agricultural Inventory Optimization analysis.

## Directory Structure

```
data/
├── raw/                    # Raw API data (6 CSV files)
├── processed/              # Analysis-ready processed data (7 CSV files)
└── README.md              # This file
```

---

## Raw Data (`data/raw/`)

Raw data collected from the KAMIS/aT Public Data API. These files contain unprocessed data directly from the API endpoints.

### Files

1. **`periodRetail_price_data.csv`** - Daily retail price observations
2. **`periodWholesale_price_data.csv`** - Daily wholesale price observations
3. **`perYearMonth_price_data.csv`** - Monthly aggregated price statistics
4. **`risesAndFalls_info_data.csv`** - Price change rates (daily/weekly/monthly/yearly)
5. **`shipmentSequel_info_data.csv`** - Daily shipment volume data
6. **`listingException_dealings_data.csv`** - Exception trading data

### Data Dictionary: Retail & Wholesale Prices

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `exmn_ymd` | Date | Examination date (YYYYMMDD) | 20250101 |
| `ctgry_cd` | Integer | Category code | 100 |
| `ctgry_nm` | String | Category name | 채소류 (Vegetables) |
| `item_cd` | Integer | Item code | 111 |
| `item_nm` | String | Item name | 배추 (Cabbage) |
| `vrty_cd` | Integer | Variety code | 1 |
| `vrty_nm` | String | Variety name | 배추 |
| `grd_cd` | Integer | Grade code | 1 |
| `grd_nm` | String | Grade name | 상 (Superior) |
| `unit` | String | Unit description | 1kg |
| `unit_sz` | Integer | Unit size | 1 |
| `sgg_cd` | Integer | Region code | 11 |
| `sgg_nm` | String | Region name | 서울 (Seoul) |
| `mrkt_cd` | Integer | Market code | 1101 |
| `mrkt_nm` | String | Market name | 가락시장 |
| `exmn_dd_prc` | Integer | Daily price (KRW) | 3500 |
| `exmn_dd_cnvs_prc` | Integer | Converted price (KRW/unit) | 3500 |
| `se_cd` | Integer | Section code (1=retail, 2=wholesale) | 1 |
| `se_nm` | String | Section name | 소매 (Retail) |

### Data Dictionary: Monthly Prices

| Column | Type | Description |
|--------|------|-------------|
| `exmn_ym` | String | Year-month (YYYYMM) |
| `pmm_avgprc` | Integer | Previous month avg price |
| `pmm_hgprc` | Integer | Previous month high price |
| `pmm_lwprc` | Integer | Previous month low price |
| `pmm_stddvtn` | Integer | Previous month standard deviation |
| `pmm_cfcntrng` | Float | Previous month concentration range |
| `pmm_cfcntvrtn` | Float | Previous month coefficient of variation |
| `pyy_avgprc` | Integer | Previous year avg price |
| `pyy_hgprc` | Integer | Previous year high price |
| `pyy_lwprc` | Integer | Previous year low price |
| `pyy_stddvtn` | Integer | Previous year standard deviation |

### Data Dictionary: Rise/Fall Information

| Column | Type | Description |
|--------|------|-------------|
| `exmn_ymd` | Date | Examination date |
| `dd1_bfr_cmpr_rafrt` | Float | 1-day comparison rate of rise/fall (%) |
| `ww1_bfr_cmpr_rafrt` | Float | 1-week comparison rate (%) |
| `mm1_bfr_cmpr_rafrt` | Float | 1-month comparison rate (%) |
| `yy1_bfr_cmpr_rafrt` | Float | 1-year comparison rate (%) |
| `exmn_dd_avg_prc` | Integer | Daily average price |
| `exmn_dd_cnvs_avg_prc` | Integer | Daily converted average price |

### Data Dictionary: Shipment Data

| Column | Type | Description |
|--------|------|-------------|
| `spmt_ymd` | Date | Shipment date (YYYYMMDD) |
| `corp_cd` | BigInt | Corporation code |
| `corp_nm` | String | Corporation name |
| `whsl_mrkt_cd` | Integer | Wholesale market code |
| `whsl_mrkt_nm` | String | Wholesale market name |
| `gds_lclsf_cd` | Integer | Goods large classification code |
| `gds_lclsf_nm` | String | Goods large classification name |
| `gds_mclsf_cd` | Integer | Goods medium classification code |
| `gds_mclsf_nm` | String | Goods medium classification name |
| `gds_sclsf_cd` | Integer | Goods small classification code |
| `gds_sclsf_nm` | String | Goods small classification name |
| `avg_spmt_amt` | Integer | Average shipment amount |
| `avg_spmt_qty` | Integer | Average shipment quantity |
| `ww1_bfr_avg_spmt_amt` | Integer | 1 week before avg shipment amount |
| `ww2_bfr_avg_spmt_amt` | Integer | 2 weeks before avg shipment amount |
| `ww3_bfr_avg_spmt_amt` | Integer | 3 weeks before avg shipment amount |
| `ww4_bfr_avg_spmt_amt` | Integer | 4 weeks before avg shipment amount |

---

## Processed Data (`data/processed/`)

Analysis-ready data after ETL processing, cleaning, and feature engineering.

### Files

1. **`metadata_item_catalog_YYYYMMDDHHMMSS.csv`** (93 items × 7 categories)
   - Complete catalog of agricultural products
   - Hierarchical category structure
   - Item-level metadata

2. **`metadata_hierarchical_structure_YYYYMMDDHHMMSS.csv`** (554 combinations)
   - Item-market combinations
   - Observation counts per combination
   - Pooling level assignments

3. **`fact_price_daily_YYYYMMDDHHMMSS.csv`** (5,494 observations)
   - Daily price time series (9-day window)
   - All product-market combinations
   - Cleaned and validated prices

4. **`bayesian_posterior_samples_YYYYMMDDHHMMSS.csv`**
   - MCMC posterior draws
   - Parameter samples from hierarchical model
   - Convergence diagnostics included

5. **`bayesian_forecasts_YYYYMMDDHHMMSS.csv`**
   - Posterior predictive forecasts
   - Multiple time horizons (1, 3, 7, 14 days)
   - Uncertainty quantification (mean, SD, quantiles)

6. **`bayesian_inventory_policy_YYYYMMDDHHMMSS.csv`** (6,648 policies)
   - Reorder point (ROP) recommendations
   - Safety stock (SS) calculations
   - Fill rate estimates
   - Service level scenarios: 90%, 95%, 99%
   - Lead time scenarios: 1, 3, 7, 14 days

7. **`model_diagnostics_YYYYMMDDHHMMSS.csv`**
   - Gelman-Rubin R̂ statistics
   - Effective sample size (ESS)
   - Jarque-Bera normality tests
   - Convergence indicators

---

## Data Schema

### Item Catalog Schema

```
metadata_item_catalog
├── item_cd         : Unique item code (integer)
├── item_nm         : Item name (string)
├── ctgry_cd        : Category code (integer)
├── ctgry_nm        : Category name (string)
├── n_markets       : Number of markets trading this item
├── n_observations  : Total observations for this item
└── avg_price       : Average price across all observations
```

### Hierarchical Structure Schema

```
metadata_hierarchical_structure
├── hierarchy_level     : "global" | "category" | "item"
├── item_cd            : Item code (nullable)
├── ctgry_cd           : Category code (nullable)
├── n_observations     : Observation count
├── pooling_strategy   : "no_pooling" | "partial_pooling" | "complete_pooling"
└── market_coverage    : Number of markets (item level only)
```

### Price Fact Schema

```
fact_price_daily
├── exmn_ymd          : Examination date (YYYYMMDD)
├── item_cd           : Item code
├── item_nm           : Item name
├── ctgry_cd          : Category code
├── ctgry_nm          : Category name
├── mrkt_cd           : Market code
├── mrkt_nm           : Market name
├── price             : Daily price (KRW)
├── log_price         : Log-transformed price
└── price_std         : Price standard deviation (item-level)
```

### Inventory Policy Schema

```
bayesian_inventory_policy
├── item_cd                : Item code
├── item_nm                : Item name
├── service_level          : Target service level (0.90, 0.95, 0.99)
├── lead_time              : Lead time in days (1, 3, 7, 14)
├── reorder_point_mean     : ROP point estimate (KRW)
├── reorder_point_sd       : ROP standard deviation
├── reorder_point_q025     : ROP 2.5% quantile
├── reorder_point_q975     : ROP 97.5% quantile
├── safety_stock_mean      : Safety stock point estimate (KRW)
├── safety_stock_sd        : Safety stock standard deviation
├── fill_rate              : Expected fill rate (proportion)
├── demand_std             : Estimated demand volatility
├── n_observations         : Sample size for this item
└── pooling_level          : Pooling strategy used
```

---

## Data Quality Metrics

### Completeness

- **Price data**: 5,494 valid observations
- **Missing values**: < 2% across all fields
- **Date range**: 9 days (2024-01-01 to 2024-01-10)

### Coverage

- **Items**: 93 unique agricultural products
- **Categories**: 7 major product categories
- **Markets**: 554 item-market combinations
- **Regions**: Multiple markets across Korea

### Validation

- ✅ All prices > 0 (negative prices removed)
- ✅ Date ranges validated
- ✅ Foreign key relationships enforced
- ✅ No duplicate primary keys

---

## Data Sources

### KAMIS/aT API

- **Provider**: Korea Agricultural Marketing Information Service (KAMIS)
- **Agency**: Korea Agro-Fisheries & Food Trade Corporation (aT)
- **Update Frequency**: Daily
- **API Documentation**: https://www.data.go.kr/data/15058192/openapi.do
- **License**: Public data (Open API)

### Data Collection Period

- **Retail/Wholesale**: 2025-01-01 to 2025-01-02 (daily)
- **Monthly aggregates**: 2025-01 (monthly)
- **Total observation window**: 9 days

---

## Usage Notes

### For Replication

1. **Quick start**: Use processed CSV files in `data/processed/`
2. **Full pipeline**: Collect raw data from API → run `etl_pipeline.py`

### For Analysis

```r
# Load processed data
library(data.table)

# Item catalog
catalog <- fread("data/processed/metadata_item_catalog_202601291929.csv")

# Daily prices
prices <- fread("data/processed/fact_price_daily_202601291929.csv")

# Inventory policies
policies <- fread("data/processed/bayesian_inventory_policy_202601291928.csv")
```

### Data Limitations

⚠️ **Important**: Current data has limited time coverage (9 days)

**For publication in top-tier journals**, extend to:
- **Minimum**: 6 months (capture seasonality)
- **Recommended**: 12 months (full annual cycle)
- **Ideal**: 24+ months (year-over-year comparisons)

### Future Extensions

1. **Temporal**: Extend to 6-12 months
2. **Exogenous variables**: Weather, holidays, market events
3. **Demand data**: Actual sales volumes (currently using price as proxy)
4. **Out-of-sample validation**: Rolling-origin cross-validation

---

## Data Citation

If you use this dataset, please cite:

```
Korea Agricultural Marketing Information Service (KAMIS), 
Korea Agro-Fisheries & Food Trade Corporation (aT).
Agricultural Price Information Data (2025-01-01 to 2025-01-10).
Retrieved from: https://www.kamis.or.kr
```

---

## Contact

For data-related questions:
- **API Issues**: KAMIS support (https://www.kamis.or.kr)
- **Processing Questions**: See `docs/REPLICATION_GUIDE.md`
- **Analysis Questions**: See main README.md

---

**Last Updated**: January 29, 2025
