\# Akari Sales \& Inventory Analytics Platform



A business-aligned data engineering and BI project built using Python, SQL Server, and Power BI.



\---



\## Objective



To design an end-to-end analytics system for Akari’s offline distribution business, covering:



\* Sales tracking

\* Inventory movement

\* Pricing strategy

\* Scheme performance

\* Region-wise analysis



\---



\## Tech Stack



| Layer           | Tool            |

| --------------- | --------------- |

| Data Generation | Python (Pandas) |

| Data Storage    | SQL Server      |

| Data Modeling   | Star Schema     |

| Visualization   | Power BI        |

| Version Control | GitHub          |



\---



\## Data Pipeline



```text

Seed Data

→ Python Data Generation

→ Raw CSV Files

→ SQL Server (Staging → Clean → DW)

→ Power BI

```



\---



\## Project Structure



```text

Akari-Sales-Inventory-Analytics/

│

├── data/

│   ├── seed/

│   └── raw/

│

├── scripts/

│   └── data\_generation/

│

├── sql/

├── docs/

├── powerbi/

└── README.md

```



\---



\## Dataset Overview



\* 6 years of data (2020–2025)

\* \~150K–200K sales orders

\* Weekly price lists

\* Inventory movement across branches



\---



\## Key Business Logic



\### Business Structure



\* 4 branches: Mumbai, Chennai, Delhi, Kolkata

\* Central warehouse: Bhiwandi

\* \~200 distributors

\* 1 sales head per branch



\---



\### Sales Behavior



\* 80–150 orders per day

\* 30–40% cross-region sales

\* Mostly same-day dispatch



\---



\### Pricing



\* Quarterly price updates

\* Weekly price lists

\* Low-stock product exclusion



\---



\### Schemes



\* Diwali-based turnover schemes

\* Slab-based incentives



\---



\### Inventory



\* Imports every 2–3 months

\* Regular branch transfers

\* Dispatch-linked stock movement



\---



\## Documentation



Detailed documentation:



```

docs/PHASE\_1\_DATA\_GENERATION.md

```



\---



\## Status



\* Phase 1: Data Generation (Completed)

\* Phase 2: SQL Staging (In Progress)



\---



\## Author



Shamsh Tabrez Shaikh

Data Analyst (SQL, Power BI)



