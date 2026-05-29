\# Phase 3: OLTP Layer



\## Objective



The objective of this phase was to transform raw staging data into a clean OLTP layer.



The OLTP layer represents the operational business structure of Akari using relational tables, keys, constraints, and validation rules.



\## SQL Folder



```text

sql/02\_oltp/

```



\## Supporting SQL Folders



```text

sql/03\_views/

sql/04\_indexes/

sql/05\_procedures/

sql/06\_automation/

```



\## Work Completed



\* Created OLTP tables

\* Loaded data from staging into OLTP tables

\* Applied primary keys and foreign keys

\* Added business constraints

\* Created views

\* Added indexing scripts

\* Added stored procedure scripts

\* Added validation scripts



\## Why OLTP Layer Is Important



The OLTP layer is used to:



\* Organize raw data into business entities

\* Reduce redundancy

\* Improve data integrity

\* Enforce relationships

\* Prepare clean source data for the data warehouse



\## Data Quality Observation



Around 18% of completed orders do not have corresponding dispatch records.



\## Assumption



Dispatch data is either incomplete or not captured for all completed orders.



\## Decision



The original order status was retained.



This issue was flagged as a data quality issue for future investigation instead of changing business data without confirmed evidence.



\## Learning Outcome



This phase helped build understanding of:



\* OLTP database design

\* Normalization

\* Primary key and foreign key relationships

\* Constraints

\* Validation queries

\* Real-world data quality handling



