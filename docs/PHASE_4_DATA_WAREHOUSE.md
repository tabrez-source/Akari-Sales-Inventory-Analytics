\# Phase 4 – Data Warehouse



\## Objective



Create an analytics-ready data model optimized for reporting and future Power BI dashboards.



\---



\## SQL Folder



```text

sql/07\_data\_warehouse/

```



\---



\## Scripts



```text

01\_create\_schema.sql

02\_create\_tables.sql

03\_insert\_tables.sql

04\_dw\_validation.sql

05\_reporting\_views.sql

06\_future\_reporting\_views.sql

07\_view\_validation.sql

08\_anomaly\_check.sql

```



\---



\## Work Completed



\### Data Warehouse Design



\* Created Data Warehouse schema

\* Created Dimension tables

\* Created Fact tables



\### Data Loading



\* Loaded data from OLTP into the Data Warehouse

\* Validated warehouse data after loading



\### Reporting Layer



Created reporting views to simplify future Power BI development and provide business-friendly datasets for analysis.



\---



\## Validation



Implemented the following validation checks:



\* Row count validation

\* Referential integrity checks

\* Missing key detection

\* Reporting view validation

\* Anomaly detection



\---



\## Business Value



The Data Warehouse enables analysis such as:



\* Product performance analysis

\* Regional sales trend analysis

\* Distributor effectiveness evaluation

\* Revenue and profitability analysis

\* Inventory movement and trend monitoring



\---



\## Outcome



Created a scalable analytical layer designed to support reporting, business intelligence, and future decision-making through Power BI dashboards.



