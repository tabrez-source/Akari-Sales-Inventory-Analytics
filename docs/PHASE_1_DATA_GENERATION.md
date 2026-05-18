\# Phase 1 – Data Generation



\---



\## Objective



To generate a realistic dataset that reflects Akari’s business operations and supports downstream analytics.



\---



\## Architecture



```text

Seed Data → Python Scripts → Raw CSV Files → SQL Staging (Next Phase)

```



\---



\## Output Files



\### Master Data



\* product\_categories.csv

\* products.csv

\* branches.csv

\* godowns.csv

\* sales\_heads.csv

\* distributors.csv



\---



\### Pricing and Schemes



\* product\_price\_history.csv

\* price\_lists.csv

\* price\_list\_items.csv

\* schemes.csv

\* scheme\_slabs.csv



\---



\### Transactions



\* sales\_orders.csv

\* sales\_order\_items.csv

\* dispatches.csv



\---



\### Inventory



\* stock\_inward.csv

\* stock\_outward.csv

\* inventory\_snapshot.csv



\---



\## Scripts



```

scripts/data\_generation/

```



| Script                         | Purpose                         |

| ------------------------------ | ------------------------------- |

| 01\_generate\_master\_data.py     | Product and category data       |

| 02\_generate\_business\_master.py | Branches, godowns, distributors |

| 03\_generate\_price\_data.py      | Pricing and schemes             |

| 04\_generate\_sales\_data.py      | Sales transactions              |

| 05\_generate\_inventory\_data.py  | Inventory movement              |



\---



\## Business Logic



\### Sales



\* 80–150 orders per day

\* Lower activity on Sundays

\* Seasonal variation (Diwali spike)

\* Pre-orders for selected categories



\---



\### Regions



\* Four primary branches

\* Cross-region sales included



\---



\### Pricing



\* Quarterly adjustments

\* Weekly price lists

\* Low-stock exclusion



\---



\### Schemes



\* Annual Diwali schemes

\* Turnover-based slabs



\---



\### Inventory



\* Imports every 2–3 months

\* Regular inter-branch transfers

\* Dispatch-based stock reduction



\---



\## Data Scale



\* \~200K orders

\* \~400K+ order items

\* Multi-year dataset



\---



\## Data Cleaning



Handled in Python:



\* Removed currency symbols

\* Cleaned numeric formatting

\* Standardized data types



\---



\## Outcome



The dataset is ready for:



\* SQL Server staging

\* Data validation

\* Data modeling

\* Power BI reporting



\---



\## Next Phase



Phase 2: SQL Server Staging



\* Import CSV files

\* Apply data types

\* Validate data

\* Prepare for modeling



