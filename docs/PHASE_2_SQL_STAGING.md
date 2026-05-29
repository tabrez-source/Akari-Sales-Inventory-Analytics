\# Phase 2: SQL Server Staging



\## Objective



The objective of this phase was to create a raw staging layer in SQL Server and load generated data into staging tables.



The staging layer stores raw imported data before it is cleaned and transformed into OLTP and data warehouse structures.



\## Database



```sql

Akari\_Staging

```



\## Schema



```sql

stg

```



\## SQL Scripts



```text

sql/01\_staging/

├── 01\_create\_database.sql

├── 02\_create\_schemas.sql

├── 03\_create\_staging\_tables.sql

├── 04\_bulk\_insert\_data.sql

└── 05\_data\_validation.sql

```



\## Execution Flow



```text

Create Database

&#x20;   ↓

Create Schema

&#x20;   ↓

Create Raw Staging Tables

&#x20;   ↓

Load TSV Files Using BULK INSERT

&#x20;   ↓

Run Data Validation

```



\## Work Completed



\* Created SQL Server staging database

\* Created `stg` schema

\* Created raw staging tables

\* Loaded large TSV files using `BULK INSERT`

\* Validated loaded data



\## Validation Checks



\* Row count checks

\* Duplicate checks

\* Blank value checks

\* Basic business distribution checks

\* Data load verification



\## Why Staging Is Important



The staging layer is used to:



\* Keep raw imported data separate

\* Debug data load issues

\* Validate data before transformation

\* Support clean downstream modeling



\## Learning Outcome



This phase helped build understanding of:



\* SQL Server staging design

\* Schema-based organization

\* Bulk data loading

\* Data validation

\* ETL workflow structure



