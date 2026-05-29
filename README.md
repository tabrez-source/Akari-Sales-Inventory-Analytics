# Akari Sales & Inventory Analytics Platform

## Overview

Akari Sales & Inventory Analytics Platform is a portfolio project designed to simulate a real-world business intelligence system.

The project focuses on building a structured data pipeline using Python, SQL Server, and Power BI — starting from raw data generation to analytics-ready datasets.

---

## Business Context

Akari is a simulated company that sells electrical products such as:

- Torches
- Emergency lights
- AC/DC bulbs
- Lithium batteries
- Mosquito bats

The business operates through distributors across multiple cities.

The objective is to analyze:

- Sales performance
- Product demand
- Inventory movement
- Distributor behavior
- Regional and branch-level performance
- Stock and inventory trends

---

## Project Status

| Phase | Description | Status |
|------|------------|--------|
| Phase 0 | Business Understanding | Completed |
| Phase 1 | Data Generation (Python) | Completed |
| Phase 2 | SQL Server Staging | Completed |
| Phase 3 | OLTP Layer | Completed |
| Phase 4 | Data Warehouse | Completed |
| Phase 5 | Power BI Dashboard | Planned |

---

## Tech Stack

- Python
- Pandas
- SQL Server
- T-SQL
- Power BI
- GitHub

---

## Data Pipeline

```text
Python Scripts
    ↓
CSV Files
    ↓
TSV Conversion (Python)
    ↓
SQL Server BULK INSERT
    ↓
Staging Tables (stg schema)
    ↓
Data Validation
    ↓
OLTP Layer
    ↓
Data Warehouse
    ↓
Reporting Views
    ↓
Future: Power BI Dashboard