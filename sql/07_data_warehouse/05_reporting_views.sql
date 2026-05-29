USE Akari_DW;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rpt')
    EXEC('CREATE SCHEMA rpt');
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_SalesAnalysis
AS
SELECT
    -- Sales identifiers
    fs.FactSalesKey,
    fs.SalesOrderID,
    fs.SalesOrderItemID,
    fs.OrderNumber,
    fs.OrderStatus,

    -- Date
    dd.DateKey,
    dd.FullDate AS OrderDate,
    dd.DayName,
    dd.WeekNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.QuarterNumber,
    dd.QuarterName,
    dd.YearNumber,
    dd.YearMonth,
    dd.IsWeekend,
    dd.IsHoliday,
    dd.HolidayName,

    -- Product
    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName,

    -- Distributor
    ddis.DistributorID,
    ddis.DistributorName,
    ddis.City AS DistributorCity,
    ddis.StateName AS DistributorState,
    ddis.BroadRegionID AS DistributorBroadRegionID,
    ddis.BroadRegionName AS DistributorBroadRegionName,
    ddis.ActivityTier,
    ddis.CreditLimit,

    -- Assigned sales head / owner
    ddis.AssignedSalesHeadID,
    ddis.AssignedSalesHeadName,
    ddis.AssignedSalesHeadBranch,
    ddis.AssignedSalesHeadBaseRegion,

    -- Actual sales head from order
    dsh.SalesHeadID AS ActualSalesHeadID,
    dsh.SalesHeadName AS ActualSalesHeadName,
    dsh.BranchName AS ActualSalesHeadBranch,
    dsh.RegionName AS ActualSalesHeadBaseRegion,

    -- Selling geography from order
    dg.BranchID AS SellingBranchID,
    dg.BranchName AS SellingBranchName,
    dg.RegionID AS SellingRegionID,
    dg.RegionName AS SellingRegionName,

    -- Measures
    fs.Quantity,
    fs.UnitPrice,
    fs.DiscountPercent,
    fs.LineTotal,

    -- Business flags
    fs.IsCrossBaseRegionSale,
    fs.IsOutsideAssignedSalesHead,

    -- Business-friendly labels
    CASE
        WHEN fs.IsOutsideAssignedSalesHead = 1 THEN 'Outside Assigned Sales Head'
        ELSE 'Within Assigned Sales Head'
    END AS SalesOwnershipStatus,

    CASE
        WHEN fs.IsCrossBaseRegionSale = 1 THEN 'Cross Base Region'
        ELSE 'Same Base Region'
    END AS BaseRegionStatus

FROM fact.FactSales fs
INNER JOIN dim.DimDate dd
    ON fs.OrderDateKey = dd.DateKey
INNER JOIN dim.DimProduct dp
    ON fs.ProductKey = dp.ProductKey
INNER JOIN dim.DimDistributor ddis
    ON fs.DistributorKey = ddis.DistributorKey
INNER JOIN dim.DimSalesHead dsh
    ON fs.SalesHeadKey = dsh.SalesHeadKey
INNER JOIN dim.DimGeography dg
    ON fs.GeographyKey = dg.GeographyKey;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_InventoryMovementAnalysis
AS
SELECT
    -- Inventory movement identifiers
    fim.InventoryMovementKey,
    fim.MovementID,
    fim.ReferenceID,

    -- Date
    dd.DateKey,
    dd.FullDate AS MovementDate,
    dd.DayName,
    dd.WeekNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.QuarterNumber,
    dd.QuarterName,
    dd.YearNumber,
    dd.YearMonth,
    dd.IsWeekend,
    dd.IsHoliday,
    dd.HolidayName,

    -- Product
    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName,

    -- Movement details
    fim.MovementType,
    fim.Quantity,
    fim.InwardQuantity,
    fim.OutwardQuantity,

    -- From godown
    fg.GodownID AS FromGodownID,
    fg.GodownName AS FromGodownName,
    fg.BranchName AS FromGodownBranch,
    fg.RegionName AS FromGodownRegion,
    fg.Location AS FromGodownLocation,
    fg.IsCentral AS IsFromCentralGodown,

    -- To godown
    tg.GodownID AS ToGodownID,
    tg.GodownName AS ToGodownName,
    tg.BranchName AS ToGodownBranch,
    tg.RegionName AS ToGodownRegion,
    tg.Location AS ToGodownLocation,
    tg.IsCentral AS IsToCentralGodown,

    -- Business-friendly movement labels
    CASE
        WHEN fim.MovementType = 'INWARD' THEN 'Stock In'
        WHEN fim.MovementType = 'OUTWARD' THEN 'Stock Out'
        ELSE 'Other Movement'
    END AS MovementTypeLabel,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.GodownName
        WHEN fim.MovementType = 'OUTWARD' THEN fg.GodownName
        ELSE COALESCE(tg.GodownName, fg.GodownName)
    END AS EffectiveGodownName,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.RegionName
        WHEN fim.MovementType = 'OUTWARD' THEN fg.RegionName
        ELSE COALESCE(tg.RegionName, fg.RegionName)
    END AS EffectiveGodownRegion,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.BranchName
        WHEN fim.MovementType = 'OUTWARD' THEN fg.BranchName
        ELSE COALESCE(tg.BranchName, fg.BranchName)
    END AS EffectiveGodownBranch

FROM fact.FactInventoryMovement fim
INNER JOIN dim.DimDate dd
    ON fim.MovementDateKey = dd.DateKey
INNER JOIN dim.DimProduct dp
    ON fim.ProductKey = dp.ProductKey
LEFT JOIN dim.DimGodown fg
    ON fim.FromGodownKey = fg.GodownKey
LEFT JOIN dim.DimGodown tg
    ON fim.ToGodownKey = tg.GodownKey;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_DistributorSalesHeadPerformance
AS
SELECT
    -- Year
    dd.YearNumber,

    -- Distributor
    ddis.DistributorID,
    ddis.DistributorName,
    ddis.City AS DistributorCity,
    ddis.StateName AS DistributorState,
    ddis.BroadRegionName AS DistributorBroadRegion,
    ddis.ActivityTier,
    ddis.CreditLimit,

    -- Actual sales head
    dsh.SalesHeadID AS ActualSalesHeadID,
    dsh.SalesHeadName AS ActualSalesHeadName,
    dsh.BranchName AS ActualSalesHeadBranch,
    dsh.RegionName AS ActualSalesHeadBaseRegion,

    -- Flags
    fs.IsOutsideAssignedSalesHead,
    CASE
        WHEN fs.IsOutsideAssignedSalesHead = 1 THEN 'Outside Assigned Sales Head'
        ELSE 'Within Assigned Sales Head'
    END AS SalesOwnershipStatus,

    -- Measures
    COUNT(DISTINCT fs.SalesOrderID) AS TotalOrders,
    COUNT(*) AS TotalOrderLines,
    SUM(fs.Quantity) AS TotalQuantity,
    SUM(fs.LineTotal) AS TotalSales,
    AVG(fs.LineTotal) AS AvgLineSales,

    -- Simple ranking helper within year
    RANK() OVER
    (
        PARTITION BY dd.YearNumber
        ORDER BY SUM(fs.LineTotal) DESC
    ) AS DistributorSalesRankByYear

FROM fact.FactSales fs
INNER JOIN dim.DimDate dd
    ON fs.OrderDateKey = dd.DateKey
INNER JOIN dim.DimDistributor ddis
    ON fs.DistributorKey = ddis.DistributorKey
INNER JOIN dim.DimSalesHead dsh
    ON fs.SalesHeadKey = dsh.SalesHeadKey
GROUP BY
    dd.YearNumber,

    ddis.DistributorID,
    ddis.DistributorName,
    ddis.City,
    ddis.StateName,
    ddis.BroadRegionName,
    ddis.ActivityTier,
    ddis.CreditLimit,

    dsh.SalesHeadID,
    dsh.SalesHeadName,
    dsh.BranchName,
    dsh.RegionName,

    fs.IsOutsideAssignedSalesHead;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_ProductPerformance
AS
SELECT
    -- Time
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    -- Product
    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName,

    -- Measures
    COUNT(DISTINCT fs.SalesOrderID) AS TotalOrders,
    COUNT(*) AS TotalOrderLines,
    SUM(fs.Quantity) AS TotalQuantitySold,
    SUM(fs.LineTotal) AS TotalSales,
    AVG(fs.UnitPrice) AS AvgUnitPrice,
    AVG(fs.DiscountPercent) AS AvgDiscountPercent,
    AVG(fs.LineTotal) AS AvgLineSales,

    -- Ranking helpers
    RANK() OVER
    (
        PARTITION BY dd.YearNumber, dd.MonthNumber
        ORDER BY SUM(fs.LineTotal) DESC
    ) AS ProductSalesRankByMonth,

    RANK() OVER
    (
        PARTITION BY dd.YearNumber, dd.MonthNumber
        ORDER BY SUM(fs.Quantity) DESC
    ) AS ProductQuantityRankByMonth

FROM fact.FactSales fs
INNER JOIN dim.DimDate dd
    ON fs.OrderDateKey = dd.DateKey
INNER JOIN dim.DimProduct dp
    ON fs.ProductKey = dp.ProductKey
GROUP BY
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_SalesHeadPerformance
AS
SELECT
    -- Time
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    -- Sales Head
    dsh.SalesHeadID,
    dsh.SalesHeadName,
    dsh.BranchID,
    dsh.BranchName,
    dsh.RegionID,
    dsh.RegionName,

    -- Measures
    COUNT(DISTINCT fs.SalesOrderID) AS TotalOrders,
    COUNT(*) AS TotalOrderLines,
    COUNT(DISTINCT fs.DistributorKey) AS ActiveDistributors,
    SUM(fs.Quantity) AS TotalQuantitySold,
    SUM(fs.LineTotal) AS TotalSales,
    AVG(fs.LineTotal) AS AvgLineSales,

    -- Ranking by month
    RANK() OVER
    (
        PARTITION BY dd.YearNumber, dd.MonthNumber
        ORDER BY SUM(fs.LineTotal) DESC
    ) AS SalesHeadSalesRankByMonth,

    RANK() OVER
    (
        PARTITION BY dd.YearNumber, dd.MonthNumber
        ORDER BY SUM(fs.Quantity) DESC
    ) AS SalesHeadQuantityRankByMonth

FROM fact.FactSales fs
INNER JOIN dim.DimDate dd
    ON fs.OrderDateKey = dd.DateKey
INNER JOIN dim.DimSalesHead dsh
    ON fs.SalesHeadKey = dsh.SalesHeadKey
GROUP BY
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    dsh.SalesHeadID,
    dsh.SalesHeadName,
    dsh.BranchID,
    dsh.BranchName,
    dsh.RegionID,
    dsh.RegionName;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_InventoryProductMovement
AS
SELECT
    -- Time
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    -- Product
    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName,

    -- Movement measures
    COUNT(*) AS TotalMovementRows,
    SUM(fim.Quantity) AS TotalMovementQuantity,
    SUM(fim.InwardQuantity) AS TotalInwardQuantity,
    SUM(fim.OutwardQuantity) AS TotalOutwardQuantity,
    SUM(fim.InwardQuantity) - SUM(fim.OutwardQuantity) AS NetMovementQuantity,

    -- Movement type counts
    SUM(CASE WHEN fim.MovementType = 'INWARD' THEN 1 ELSE 0 END) AS InwardMovementCount,
    SUM(CASE WHEN fim.MovementType = 'OUTWARD' THEN 1 ELSE 0 END) AS OutwardMovementCount,

    -- Ranking helpers
    RANK() OVER
    (
        PARTITION BY dd.YearNumber, dd.MonthNumber
        ORDER BY SUM(fim.OutwardQuantity) DESC
    ) AS ProductOutwardRankByMonth,

    RANK() OVER
    (
        PARTITION BY dd.YearNumber, dd.MonthNumber
        ORDER BY SUM(fim.InwardQuantity) DESC
    ) AS ProductInwardRankByMonth,

    RANK() OVER
    (
        PARTITION BY dd.YearNumber, dd.MonthNumber
        ORDER BY SUM(fim.InwardQuantity) - SUM(fim.OutwardQuantity) DESC
    ) AS ProductNetMovementRankByMonth

FROM fact.FactInventoryMovement fim
INNER JOIN dim.DimDate dd
    ON fim.MovementDateKey = dd.DateKey
INNER JOIN dim.DimProduct dp
    ON fim.ProductKey = dp.ProductKey
GROUP BY
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_GodownInventorySummary
AS
SELECT
    -- Time
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    -- Effective godown
    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.GodownID
        WHEN fim.MovementType = 'OUTWARD' THEN fg.GodownID
        ELSE COALESCE(tg.GodownID, fg.GodownID)
    END AS GodownID,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.GodownName
        WHEN fim.MovementType = 'OUTWARD' THEN fg.GodownName
        ELSE COALESCE(tg.GodownName, fg.GodownName)
    END AS GodownName,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN ISNULL(tg.BranchName, 'Central Warehouse')
        WHEN fim.MovementType = 'OUTWARD' THEN ISNULL(fg.BranchName, 'Central Warehouse')
        ELSE ISNULL(COALESCE(tg.BranchName, fg.BranchName), 'Central Warehouse')
    END AS GodownBranch,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN ISNULL(tg.RegionName, 'Central')
        WHEN fim.MovementType = 'OUTWARD' THEN ISNULL(fg.RegionName, 'Central')
        ELSE ISNULL(COALESCE(tg.RegionName, fg.RegionName), 'Central')
    END AS GodownRegion,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.Location
        WHEN fim.MovementType = 'OUTWARD' THEN fg.Location
        ELSE COALESCE(tg.Location, fg.Location)
    END AS GodownLocation,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.IsCentral
        WHEN fim.MovementType = 'OUTWARD' THEN fg.IsCentral
        ELSE COALESCE(tg.IsCentral, fg.IsCentral)
    END AS IsCentralGodown,

    -- Product
    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName,

    -- Measures
    COUNT(*) AS TotalMovementRows,
    SUM(fim.InwardQuantity) AS TotalInwardQuantity,
    SUM(fim.OutwardQuantity) AS TotalOutwardQuantity,
    SUM(fim.InwardQuantity) - SUM(fim.OutwardQuantity) AS NetMovementQuantity

FROM fact.FactInventoryMovement fim
INNER JOIN dim.DimDate dd
    ON fim.MovementDateKey = dd.DateKey
INNER JOIN dim.DimProduct dp
    ON fim.ProductKey = dp.ProductKey
LEFT JOIN dim.DimGodown fg
    ON fim.FromGodownKey = fg.GodownKey
LEFT JOIN dim.DimGodown tg
    ON fim.ToGodownKey = tg.GodownKey

GROUP BY
    dd.YearNumber,
    dd.MonthNumber,
    dd.MonthName,
    dd.YearMonth,
    dd.QuarterNumber,
    dd.QuarterName,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.GodownID
        WHEN fim.MovementType = 'OUTWARD' THEN fg.GodownID
        ELSE COALESCE(tg.GodownID, fg.GodownID)
    END,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.GodownName
        WHEN fim.MovementType = 'OUTWARD' THEN fg.GodownName
        ELSE COALESCE(tg.GodownName, fg.GodownName)
    END,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN ISNULL(tg.BranchName, 'Central Warehouse')
        WHEN fim.MovementType = 'OUTWARD' THEN ISNULL(fg.BranchName, 'Central Warehouse')
        ELSE ISNULL(COALESCE(tg.BranchName, fg.BranchName), 'Central Warehouse')
    END,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN ISNULL(tg.RegionName, 'Central')
        WHEN fim.MovementType = 'OUTWARD' THEN ISNULL(fg.RegionName, 'Central')
        ELSE ISNULL(COALESCE(tg.RegionName, fg.RegionName), 'Central')
    END,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.Location
        WHEN fim.MovementType = 'OUTWARD' THEN fg.Location
        ELSE COALESCE(tg.Location, fg.Location)
    END,

    CASE
        WHEN fim.MovementType = 'INWARD' THEN tg.IsCentral
        WHEN fim.MovementType = 'OUTWARD' THEN fg.IsCentral
        ELSE COALESCE(tg.IsCentral, fg.IsCentral)
    END,

    dp.ProductID,
    dp.SKU,
    dp.ProductName,
    dp.CategoryID,
    dp.CategoryName;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_CategoryPerformance
AS
WITH SalesCategory AS
(
    SELECT
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName,

        dp.CategoryID,
        dp.CategoryName,

        COUNT(DISTINCT fs.SalesOrderID) AS TotalOrders,
        COUNT(*) AS TotalOrderLines,
        SUM(fs.Quantity) AS TotalQuantitySold,
        SUM(fs.LineTotal) AS TotalSales
    FROM fact.FactSales fs
    INNER JOIN dim.DimDate dd
        ON fs.OrderDateKey = dd.DateKey
    INNER JOIN dim.DimProduct dp
        ON fs.ProductKey = dp.ProductKey
    GROUP BY
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName,
        dp.CategoryID,
        dp.CategoryName
),
InventoryCategory AS
(
    SELECT
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName,

        dp.CategoryID,
        dp.CategoryName,

        SUM(fim.InwardQuantity) AS TotalInwardQuantity,
        SUM(fim.OutwardQuantity) AS TotalOutwardQuantity,
        SUM(fim.InwardQuantity) - SUM(fim.OutwardQuantity) AS NetMovementQuantity
    FROM fact.FactInventoryMovement fim
    INNER JOIN dim.DimDate dd
        ON fim.MovementDateKey = dd.DateKey
    INNER JOIN dim.DimProduct dp
        ON fim.ProductKey = dp.ProductKey
    GROUP BY
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName,
        dp.CategoryID,
        dp.CategoryName
)
SELECT
    COALESCE(s.YearNumber, i.YearNumber) AS YearNumber,
    COALESCE(s.MonthNumber, i.MonthNumber) AS MonthNumber,
    COALESCE(s.MonthName, i.MonthName) AS MonthName,
    COALESCE(s.YearMonth, i.YearMonth) AS YearMonth,
    COALESCE(s.QuarterNumber, i.QuarterNumber) AS QuarterNumber,
    COALESCE(s.QuarterName, i.QuarterName) AS QuarterName,

    COALESCE(s.CategoryID, i.CategoryID) AS CategoryID,
    COALESCE(s.CategoryName, i.CategoryName) AS CategoryName,

    ISNULL(s.TotalOrders, 0) AS TotalOrders,
    ISNULL(s.TotalOrderLines, 0) AS TotalOrderLines,
    ISNULL(s.TotalQuantitySold, 0) AS TotalQuantitySold,
    ISNULL(s.TotalSales, 0) AS TotalSales,

    ISNULL(i.TotalInwardQuantity, 0) AS TotalInwardQuantity,
    ISNULL(i.TotalOutwardQuantity, 0) AS TotalOutwardQuantity,
    ISNULL(i.NetMovementQuantity, 0) AS NetMovementQuantity,

    CASE
        WHEN ISNULL(i.TotalInwardQuantity, 0) = 0 THEN NULL
        ELSE CAST(i.TotalOutwardQuantity * 100.0 / NULLIF(i.TotalInwardQuantity, 0) AS DECIMAL(10,2))
    END AS OutwardToInwardPercent,

    RANK() OVER
    (
        PARTITION BY COALESCE(s.YearNumber, i.YearNumber), COALESCE(s.MonthNumber, i.MonthNumber)
        ORDER BY ISNULL(s.TotalSales, 0) DESC
    ) AS CategorySalesRankByMonth,

    RANK() OVER
    (
        PARTITION BY COALESCE(s.YearNumber, i.YearNumber), COALESCE(s.MonthNumber, i.MonthNumber)
        ORDER BY ISNULL(i.TotalOutwardQuantity, 0) DESC
    ) AS CategoryOutwardRankByMonth

FROM SalesCategory s
FULL OUTER JOIN InventoryCategory i
    ON s.YearMonth = i.YearMonth
   AND s.CategoryID = i.CategoryID;
GO

USE Akari_DW;
GO

CREATE OR ALTER VIEW rpt.vw_ExecutiveSalesSummary
AS
WITH SalesSummary AS
(
    SELECT
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName,

        COUNT(DISTINCT fs.SalesOrderID) AS TotalOrders,
        COUNT(*) AS TotalOrderLines,
        COUNT(DISTINCT fs.DistributorKey) AS ActiveDistributors,
        COUNT(DISTINCT fs.ProductKey) AS ActiveProducts,
        COUNT(DISTINCT fs.SalesHeadKey) AS ActiveSalesHeads,

        SUM(fs.Quantity) AS TotalQuantitySold,
        SUM(fs.LineTotal) AS TotalSales,
        AVG(fs.LineTotal) AS AvgLineSales,

        CAST(
            SUM(fs.LineTotal) * 1.0 / NULLIF(COUNT(DISTINCT fs.SalesOrderID), 0)
            AS DECIMAL(18,2)
        ) AS AvgOrderValue
    FROM fact.FactSales fs
    INNER JOIN dim.DimDate dd
        ON fs.OrderDateKey = dd.DateKey
    GROUP BY
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName
),
InventorySummary AS
(
    SELECT
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName,

        SUM(fim.InwardQuantity) AS TotalInwardQuantity,
        SUM(fim.OutwardQuantity) AS TotalOutwardQuantity,
        SUM(fim.InwardQuantity) - SUM(fim.OutwardQuantity) AS NetMovementQuantity
    FROM fact.FactInventoryMovement fim
    INNER JOIN dim.DimDate dd
        ON fim.MovementDateKey = dd.DateKey
    GROUP BY
        dd.YearNumber,
        dd.MonthNumber,
        dd.MonthName,
        dd.YearMonth,
        dd.QuarterNumber,
        dd.QuarterName
)
SELECT
    COALESCE(s.YearNumber, i.YearNumber) AS YearNumber,
    COALESCE(s.MonthNumber, i.MonthNumber) AS MonthNumber,
    COALESCE(s.MonthName, i.MonthName) AS MonthName,
    COALESCE(s.YearMonth, i.YearMonth) AS YearMonth,
    COALESCE(s.QuarterNumber, i.QuarterNumber) AS QuarterNumber,
    COALESCE(s.QuarterName, i.QuarterName) AS QuarterName,

    ISNULL(s.TotalOrders, 0) AS TotalOrders,
    ISNULL(s.TotalOrderLines, 0) AS TotalOrderLines,
    ISNULL(s.ActiveDistributors, 0) AS ActiveDistributors,
    ISNULL(s.ActiveProducts, 0) AS ActiveProducts,
    ISNULL(s.ActiveSalesHeads, 0) AS ActiveSalesHeads,

    ISNULL(s.TotalQuantitySold, 0) AS TotalQuantitySold,
    ISNULL(s.TotalSales, 0) AS TotalSales,
    ISNULL(s.AvgLineSales, 0) AS AvgLineSales,
    ISNULL(s.AvgOrderValue, 0) AS AvgOrderValue,

    ISNULL(i.TotalInwardQuantity, 0) AS TotalInwardQuantity,
    ISNULL(i.TotalOutwardQuantity, 0) AS TotalOutwardQuantity,
    ISNULL(i.NetMovementQuantity, 0) AS NetMovementQuantity

FROM SalesSummary s
FULL OUTER JOIN InventorySummary i
    ON s.YearMonth = i.YearMonth;
GO