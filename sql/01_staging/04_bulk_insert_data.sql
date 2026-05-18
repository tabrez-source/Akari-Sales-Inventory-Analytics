/*
    Project: Akari Sales & Inventory Analytics Platform
    Phase: 2 - SQL Server Staging
    Script: 04_bulk_insert_data.sql
    Purpose: Load TSV files into raw staging tables
*/

USE Akari_Staging;
GO

/*
    Update file paths before running this script.
*/

BULK INSERT stg.Products_Raw
FROM 'C:\Projects\Akari\data\processed\products.tsv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

BULK INSERT stg.Distributors_Raw
FROM 'C:\Projects\Akari\data\processed\distributors.tsv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = '\t',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO