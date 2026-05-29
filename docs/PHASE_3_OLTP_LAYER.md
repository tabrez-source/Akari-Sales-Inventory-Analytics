# Phase 3: OLTP Layer

## Objective

The objective of this phase was to transform raw staging data into a structured Operational Transaction Processing (OLTP) system.

The OLTP layer organizes business data into normalized relational tables and serves as the operational foundation for downstream analytics.

## SQL Components

```text
sql/02_oltp/
sql/03_views/
sql/04_indexes/
sql/05_procedures/
sql/06_automation/
```

## Work Completed

### Database Design

- Created normalized business tables
- Implemented primary keys
- Implemented foreign keys
- Added business constraints

### Data Loading

- Loaded clean data from staging tables
- Applied business transformation logic
- Validated loaded records

### Optimization

- Created reporting views
- Added indexing strategies
- Developed stored procedures
- Implemented validation scripts

## Data Quality Observation

Approximately 18% of completed orders did not have corresponding dispatch records.

## Assumption

Dispatch information was either incomplete or not captured for all completed orders.

## Decision

- Retained original order status
- Flagged the issue as a data quality concern
- Avoided altering business data without supporting evidence

## Validation Checks

- Primary key validation
- Foreign key validation
- Duplicate checks
- Missing value checks
- Relationship integrity checks

## Why OLTP Is Important

The OLTP layer is used to:

- Organize business entities
- Reduce data redundancy
- Enforce business rules
- Improve data integrity
- Prepare clean source data for the Data Warehouse

## Learning Outcome

This phase helped build understanding of:

- OLTP database design
- Data normalization
- Primary and foreign key relationships
- Constraints and business rules
- Data validation techniques
- Real-world data quality handling

## Outcome

A structured and validated OLTP system was established to support Data Warehouse development and business reporting.