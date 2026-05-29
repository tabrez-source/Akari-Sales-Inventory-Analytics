
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
