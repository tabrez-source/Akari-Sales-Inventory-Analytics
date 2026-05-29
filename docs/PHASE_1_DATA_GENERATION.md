# Phase 1: Data Generation

## Objective

The objective of this phase was to generate realistic synthetic business data for the Akari Sales & Inventory Analytics Platform.

This data supports the full analytics pipeline from raw data generation to SQL Server, data warehouse modeling, and future Power BI reporting.

## Tools Used

* Python
* Pandas
* CSV file handling
* TSV file preparation

## Scripts

```text
scripts/data_generation/
├── 01_generate_master_data.py
├── 02_generate_business_master.py
├── 03_generate_price_data.py
├── 04_generate_sales_data.py
├── 05_generate_inventory_data.py
└── 06_prepare_sql_load_files.py
```

## Work Completed

* Generated master data
* Generated product and distributor data
* Generated pricing data
* Generated sales transaction data
* Generated inventory data
* Prepared SQL-load-ready files

## Key Challenge

CSV files caused ingestion issues during SQL Server bulk loading.

## Solution

CSV files were converted into TSV files using Python.

TSV files worked better with SQL Server `BULK INSERT` because tab delimiters reduced parsing issues.

## Output

The output of this phase was a set of structured load-ready files prepared for SQL Server staging.

## Learning Outcome

This phase helped build understanding of:

* Synthetic business data generation
* Data preparation using Python
* File formatting for SQL Server ingestion
* Real-world data pipeline preparation
