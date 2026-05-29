
USE Akari_DW;
GO

/* ============================================================
   1. Dimension count validation
============================================================ */
SELECT 'DimProduct' AS TableName,
       (SELECT COUNT(*) FROM Akari_OLTP.dbo.Product) AS OLTP_Count,
       (SELECT COUNT(*) FROM Akari_DW.dim.DimProduct) AS DW_Count;

SELECT 'DimGeography' AS TableName,
       (SELECT COUNT(*) FROM Akari_OLTP.dbo.Branch) AS OLTP_Count,
       (SELECT COUNT(*) FROM Akari_DW.dim.DimGeography) AS DW_Count;

SELECT 'DimSalesHead' AS TableName,
       (SELECT COUNT(*) FROM Akari_OLTP.dbo.SalesHead) AS OLTP_Count,
       (SELECT COUNT(*) FROM Akari_DW.dim.DimSalesHead) AS DW_Count;

SELECT 'DimDistributor' AS TableName,
       (SELECT COUNT(*) FROM Akari_OLTP.dbo.Distributor) AS OLTP_Count,
       (SELECT COUNT(*) FROM Akari_DW.dim.DimDistributor) AS DW_Count;

SELECT 'DimGodown' AS TableName,
       (SELECT COUNT(*) FROM Akari_OLTP.dbo.Godown) AS OLTP_Count,
       (SELECT COUNT(*) FROM Akari_DW.dim.DimGodown) AS DW_Count;
GO

/* ============================================================
   2. Dimension duplicate business-key checks
   Expected: no rows from each query
============================================================ */
SELECT ProductID, COUNT(*) AS DuplicateCount
FROM dim.DimProduct
GROUP BY ProductID
HAVING COUNT(*) > 1;

SELECT BranchID, COUNT(*) AS DuplicateCount
FROM dim.DimGeography
GROUP BY BranchID
HAVING COUNT(*) > 1;

SELECT SalesHeadID, COUNT(*) AS DuplicateCount
FROM dim.DimSalesHead
GROUP BY SalesHeadID
HAVING COUNT(*) > 1;

SELECT DistributorID, COUNT(*) AS DuplicateCount
FROM dim.DimDistributor
GROUP BY DistributorID
HAVING COUNT(*) > 1;

SELECT GodownID, COUNT(*) AS DuplicateCount
FROM dim.DimGodown
GROUP BY GodownID
HAVING COUNT(*) > 1;
GO

/* ============================================================
   3. Missing / incomplete dimension mapping checks
   Expected: no rows, except central godown may have NULL branch/region.
============================================================ */
SELECT *
FROM dim.DimProduct
WHERE ProductID IS NULL
   OR ProductName IS NULL
   OR SKU IS NULL;

SELECT *
FROM dim.DimSalesHead
WHERE BranchID IS NULL
   OR RegionID IS NULL;

SELECT *
FROM dim.DimDistributor
WHERE StateName IS NULL
   OR AssignedSalesHeadID IS NULL
   OR AssignedSalesHeadName IS NULL;

SELECT *
FROM dim.DimGodown
WHERE IsCentral = 0
  AND (BranchID IS NULL OR RegionID IS NULL);
GO

/* ============================================================
   4. FactSales row count and total validation
============================================================ */
SELECT COUNT(*) AS OLTP_SalesDetail_Count
FROM Akari_OLTP.dbo.vw_SalesDetail;

SELECT COUNT(*) AS DW_FactSales_Count
FROM Akari_DW.fact.FactSales;

SELECT SUM(LineTotal) AS OLTP_TotalSales
FROM Akari_OLTP.dbo.vw_SalesDetail;

SELECT SUM(LineTotal) AS DW_TotalSales
FROM Akari_DW.fact.FactSales;
GO

/* ============================================================
   5. FactSales duplicate grain check
   Grain: 1 row = 1 SalesOrderItemID
   Expected: no rows
============================================================ */
SELECT 
    SalesOrderItemID,
    COUNT(*) AS DuplicateCount
FROM fact.FactSales
GROUP BY SalesOrderItemID
HAVING COUNT(*) > 1;
GO

/* ============================================================
   6. FactSales business flag validation
============================================================ */
SELECT 
    IsCrossBaseRegionSale,
    COUNT(*) AS TotalRows,
    SUM(LineTotal) AS TotalSales
FROM fact.FactSales
GROUP BY IsCrossBaseRegionSale;

SELECT 
    IsOutsideAssignedSalesHead,
    COUNT(*) AS TotalRows,
    SUM(LineTotal) AS TotalSales
FROM fact.FactSales
GROUP BY IsOutsideAssignedSalesHead;

SELECT
    dd.AssignedSalesHeadName,
    dsh.SalesHeadName AS ActualSalesHead,
    fs.IsOutsideAssignedSalesHead,
    COUNT(*) AS TotalRows,
    SUM(fs.LineTotal) AS TotalSales
FROM fact.FactSales fs
INNER JOIN dim.DimDistributor dd
    ON fs.DistributorKey = dd.DistributorKey
INNER JOIN dim.DimSalesHead dsh
    ON fs.SalesHeadKey = dsh.SalesHeadKey
GROUP BY
    dd.AssignedSalesHeadName,
    dsh.SalesHeadName,
    fs.IsOutsideAssignedSalesHead
ORDER BY
    dd.AssignedSalesHeadName,
    TotalSales DESC;
GO

/* ============================================================
   7. FactInventoryMovement row count and movement total validation
============================================================ */
SELECT COUNT(*) AS OLTP_InventoryMovement_Count
FROM Akari_OLTP.dbo.InventoryMovement;

SELECT COUNT(*) AS DW_FactInventoryMovement_Count
FROM Akari_DW.fact.FactInventoryMovement;

SELECT
    MovementType,
    COUNT(*) AS TotalRows,
    SUM(Quantity) AS TotalQuantity
FROM Akari_OLTP.dbo.InventoryMovement
GROUP BY MovementType;

SELECT
    MovementType,
    COUNT(*) AS TotalRows,
    SUM(Quantity) AS TotalQuantity
FROM Akari_DW.fact.FactInventoryMovement
GROUP BY MovementType;
GO

/* ============================================================
   8. FactInventoryMovement duplicate grain check
   Grain: 1 row = 1 MovementID
   Expected: no rows
============================================================ */
SELECT 
    MovementID,
    COUNT(*) AS DuplicateCount
FROM fact.FactInventoryMovement
GROUP BY MovementID
HAVING COUNT(*) > 1;
GO

/* ============================================================
   9. Inventory inward/outward/net movement validation
============================================================ */
SELECT
    SUM(InwardQuantity) AS TotalInwardQuantity,
    SUM(OutwardQuantity) AS TotalOutwardQuantity,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS NetMovementQuantity
FROM fact.FactInventoryMovement;
GO

/* ============================================================
   10. Missing key checks in fact tables
   Expected: no rows
============================================================ */
SELECT *
FROM fact.FactSales
WHERE OrderDateKey IS NULL
   OR ProductKey IS NULL
   OR DistributorKey IS NULL
   OR SalesHeadKey IS NULL
   OR GeographyKey IS NULL;

SELECT *
FROM fact.FactInventoryMovement
WHERE MovementDateKey IS NULL
   OR ProductKey IS NULL;
GO

/* ============================================================
   11. Final DW summary
============================================================ */
SELECT 'DimDate' AS DWObject, COUNT(*) AS TotalRows FROM dim.DimDate
UNION ALL
SELECT 'DimProduct', COUNT(*) FROM dim.DimProduct
UNION ALL
SELECT 'DimGeography', COUNT(*) FROM dim.DimGeography
UNION ALL
SELECT 'DimSalesHead', COUNT(*) FROM dim.DimSalesHead
UNION ALL
SELECT 'DimDistributor', COUNT(*) FROM dim.DimDistributor
UNION ALL
SELECT 'DimGodown', COUNT(*) FROM dim.DimGodown
UNION ALL
SELECT 'FactSales', COUNT(*) FROM fact.FactSales
UNION ALL
SELECT 'FactInventoryMovement', COUNT(*) FROM fact.FactInventoryMovement;
GO
