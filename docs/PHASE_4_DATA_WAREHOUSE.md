# Phase 4: Data Warehouse

## Objective

The objective of this phase was to create an analytics-ready Data Warehouse optimized for reporting and future Power BI dashboards.

The Data Warehouse transforms operational data into structures designed for business analysis and decision-making.

## SQL Folder

```text
sql/07_data_warehouse/
```

## Scripts

```text
01_create_schema.sql
02_create_tables.sql
03_insert_tables.sql
04_dw_validation.sql
05_reporting_views.sql
06_future_reporting_views.sql
07_view_validation.sql
08_anomaly_check.sql
```

## Work Completed

### Data Warehouse Design

- Created Data Warehouse schema
- Created dimension tables
- Created fact tables

### Data Loading

- Loaded data from OLTP into the Data Warehouse
- Validated warehouse data after loading

### Reporting Layer

- Created reporting views
- Created future reporting views
- Prepared datasets for Power BI integration

## Validation

Implemented the following validation checks:

- Row count validation
- Referential integrity checks
- Missing key detection
- Reporting view validation
- Anomaly detection

## Business Value

The Data Warehouse enables analysis such as:

- Product performance analysis
- Regional sales trend analysis
- Distributor effectiveness evaluation
- Revenue and profitability analysis
- Inventory movement and trend monitoring

## Why a Data Warehouse Is Important

The Data Warehouse is designed to:

- Support analytical workloads
- Improve reporting performance
- Simplify business analysis
- Separate reporting logic from OLTP operations
- Provide clean reporting datasets

## Learning Outcome

This phase helped build understanding of:

- Data Warehouse architecture
- Fact and Dimension modeling
- Reporting view development
- Data validation techniques
- Analytics-ready database design
- Business Intelligence workflows

## Outcome

A scalable analytical layer was created to support reporting, business intelligence, and future Power BI dashboard development.