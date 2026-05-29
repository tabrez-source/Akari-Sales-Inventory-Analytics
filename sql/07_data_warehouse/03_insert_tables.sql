DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate   DATE = '2030-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dim.DimDate
    (
        DateKey,
        FullDate,
        DayNumber,
        DayName,
        WeekNumber,
        MonthNumber,
        MonthName,
        QuarterNumber,
        QuarterName,
        YearNumber,
        YearMonth,
        IsWeekend,
        IsHoliday,
        HolidayName
    )
    VALUES
    (
        CONVERT(INT, FORMAT(@StartDate, 'yyyyMMdd')),
        @StartDate,
        DAY(@StartDate),
        DATENAME(WEEKDAY, @StartDate),
        DATEPART(WEEK, @StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DATEPART(QUARTER, @StartDate),
        CONCAT('Q', DATEPART(QUARTER, @StartDate)),
        YEAR(@StartDate),
        FORMAT(@StartDate, 'yyyy-MM'),
        CASE 
            WHEN DATENAME(WEEKDAY, @StartDate) IN ('Saturday', 'Sunday') THEN 1 
            ELSE 0 
        END,
        0,
        NULL
    );

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;

INSERT INTO Akari_DW.dim.DimProduct
(
    ProductID,
    SKU,
    ProductName,
    CategoryID,
    CategoryName,
    IsActive
)
SELECT
    p.ProductID,
    p.SKU,
    p.ProductName,
    p.CategoryID,
    ISNULL(pc.CategoryName, 'Unknown') AS CategoryName,
    ISNULL(p.IsActive, 1) AS IsActive
FROM Akari_OLTP.dbo.Product p
LEFT JOIN Akari_OLTP.dbo.ProductCategory pc
    ON p.CategoryID = pc.CategoryID;

INSERT INTO Akari_DW.dim.DimGeography
(
    RegionID,
    RegionName,
    BranchID,
    BranchName,
    IsActive
)
SELECT
    r.RegionID,
    r.RegionName,
    b.BranchID,
    b.BranchName,
    ISNULL(b.IsActive, 1) AS IsActive
FROM Akari_OLTP.dbo.Branch b
LEFT JOIN Akari_OLTP.dbo.Region r
    ON b.RegionID = r.RegionID;

    INSERT INTO Akari_DW.dim.DimSalesHead
(
    SalesHeadID,
    SalesHeadName,
    BranchID,
    BranchName,
    RegionID,
    RegionName,
    IsActive
)
SELECT
    sh.SalesHeadID,
    sh.SalesHeadName,
    b.BranchID,
    b.BranchName,
    r.RegionID,
    r.RegionName,
    ISNULL(sh.IsActive, 1) AS IsActive
FROM Akari_OLTP.dbo.SalesHead sh
LEFT JOIN Akari_OLTP.dbo.Branch b
    ON sh.BranchID = b.BranchID
LEFT JOIN Akari_OLTP.dbo.Region r
    ON b.RegionID = r.RegionID;

USE Akari_DW;
GO

INSERT INTO dim.DimDistributor
(
    DistributorID,
    DistributorName,
    City,
    StateName,
    BroadRegionID,
    BroadRegionName,
    AssignedSalesHeadID,
    AssignedSalesHeadName,
    AssignedSalesHeadBranch,
    AssignedSalesHeadBaseRegion,
    CreditLimit,
    ActivityTier,
    IsActive
)
SELECT
    d.DistributorID,
    d.DistributorName,
    d.City,
    d.StateName,

    d.RegionID AS BroadRegionID,
    br.RegionName AS BroadRegionName,

    sh.SalesHeadID AS AssignedSalesHeadID,
    sh.SalesHeadName AS AssignedSalesHeadName,
    b.BranchName AS AssignedSalesHeadBranch,
    shr.RegionName AS AssignedSalesHeadBaseRegion,

    d.CreditLimit,
    d.ActivityTier,
    ISNULL(d.IsActive, 1) AS IsActive
FROM Akari_OLTP.dbo.Distributor d
LEFT JOIN Akari_OLTP.dbo.Region br
    ON d.RegionID = br.RegionID
LEFT JOIN Akari_OLTP.dbo.SalesHead sh
    ON d.SalesHeadID = sh.SalesHeadID
LEFT JOIN Akari_OLTP.dbo.Branch b
    ON sh.BranchID = b.BranchID
LEFT JOIN Akari_OLTP.dbo.Region shr
    ON b.RegionID = shr.RegionID;

USE Akari_DW;
GO

INSERT INTO fact.FactSales
(
    SalesOrderID,
    SalesOrderItemID,
    OrderNumber,
    OrderDateKey,
    ProductKey,
    DistributorKey,
    SalesHeadKey,
    GeographyKey,
    Quantity,
    UnitPrice,
    DiscountPercent,
    LineTotal,
    OrderStatus,
    IsCrossBaseRegionSale,
    IsOutsideAssignedSalesHead
)
SELECT
    s.SalesOrderID,
    s.SalesOrderItemID,
    s.OrderNumber,

    dd.DateKey AS OrderDateKey,
    dp.ProductKey,
    ddis.DistributorKey,
    dsh.SalesHeadKey,
    dg.GeographyKey,

    s.Quantity,
    s.UnitPrice,
    s.DiscountPercent,
    s.LineTotal,
    s.OrderStatus,

    CASE
        WHEN ddis.BroadRegionID <> dsh.RegionID THEN 1
        ELSE 0
    END AS IsCrossBaseRegionSale,

    CASE
        WHEN ddis.AssignedSalesHeadID <> dsh.SalesHeadID THEN 1
        ELSE 0
    END AS IsOutsideAssignedSalesHead

FROM Akari_OLTP.dbo.vw_SalesDetail s
INNER JOIN dim.DimDate dd
    ON s.OrderDate = dd.FullDate
INNER JOIN dim.DimProduct dp
    ON s.ProductID = dp.ProductID
INNER JOIN dim.DimDistributor ddis
    ON s.DistributorID = ddis.DistributorID
INNER JOIN dim.DimSalesHead dsh
    ON s.SalesHeadID = dsh.SalesHeadID
INNER JOIN dim.DimGeography dg
    ON s.BranchID = dg.BranchID;


USE Akari_DW;
GO

INSERT INTO fact.FactInventoryMovement
(
    MovementID,
    MovementDateKey,
    ProductKey,
    FromGodownKey,
    ToGodownKey,
    FromGodownID,
    ToGodownID,
    MovementType,
    Quantity,
    InwardQuantity,
    OutwardQuantity,
    ReferenceID
)
SELECT
    im.MovementID,
    dd.DateKey AS MovementDateKey,
    dp.ProductKey,

    fg.GodownKey AS FromGodownKey,
    tg.GodownKey AS ToGodownKey,

    im.FromGodownID,
    im.ToGodownID,

    im.MovementType,
    im.Quantity,

    CASE 
        WHEN im.MovementType = 'INWARD' THEN im.Quantity 
        ELSE 0 
    END AS InwardQuantity,

    CASE 
        WHEN im.MovementType = 'OUTWARD' THEN im.Quantity 
        ELSE 0 
    END AS OutwardQuantity,

    im.ReferenceID
FROM Akari_OLTP.dbo.InventoryMovement im
INNER JOIN dim.DimDate dd
    ON im.MovementDate = dd.FullDate
INNER JOIN dim.DimProduct dp
    ON im.ProductID = dp.ProductID
LEFT JOIN dim.DimGodown fg
    ON im.FromGodownID = fg.GodownID
LEFT JOIN dim.DimGodown tg
    ON im.ToGodownID = tg.GodownID;