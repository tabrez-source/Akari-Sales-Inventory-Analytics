CREATE VIEW dbo.vw_SalesDetail AS
SELECT
    so.SalesOrderID,
    so.OrderNumber,
    so.OrderDate,
    so.OrderStatus,

    d.DistributorID,
    d.DistributorName,

    sh.SalesHeadID,
    sh.SalesHeadName,

    b.BranchID,
    b.BranchName,

    r.RegionID,
    r.RegionName,

    p.ProductID,
    p.ProductName,
    p.SKU,
    pc.CategoryName,

    soi.Quantity,
    soi.UnitPrice,
    soi.DiscountPercent,
    soi.LineTotal

FROM dbo.SalesOrder so

JOIN dbo.SalesOrderItem soi
    ON so.SalesOrderID = soi.SalesOrderID

JOIN dbo.Product p
    ON soi.ProductID = p.ProductID

JOIN dbo.ProductCategory pc
    ON p.CategoryID = pc.CategoryID

JOIN dbo.Distributor d
    ON so.DistributorID = d.DistributorID

JOIN dbo.SalesHead sh
    ON so.SalesHeadID = sh.SalesHeadID

JOIN dbo.Branch b
    ON sh.BranchID = b.BranchID

JOIN dbo.Region r
    ON b.RegionID = r.RegionID;


CREATE VIEW dbo.vw_InventoryStatus AS
SELECT 
    p.ProductID,
    p.SKU,
    p.ProductName,
    pc.CategoryName,
    g.GodownID,
    g.GodownName,

    SUM(CASE 
        WHEN im.MovementType = 'INWARD' THEN im.Quantity
        WHEN im.MovementType = 'OUTWARD' THEN -im.Quantity
        ELSE 0
    END) AS CurrentStock

FROM dbo.InventoryMovement im
JOIN dbo.Product p 
    ON im.ProductID = p.ProductID
JOIN dbo.ProductCategory pc
    ON p.CategoryID = pc.CategoryID
JOIN dbo.Godown g
    ON COALESCE(im.ToGodownID, im.FromGodownID) = g.GodownID
GROUP BY 
    p.ProductID,
    p.SKU,
    p.ProductName,
    pc.CategoryName,
    g.GodownID,
    g.GodownName;

CREATE VIEW dbo.vw_DistributorPerformance AS
WITH DistributorSales AS (
    SELECT
        d.DistributorID,
        d.DistributorName,
        d.ActivityTier,
        d.CreditLimit,

        YEAR(so.OrderDate) AS SalesYear,

        sh.SalesHeadID,
        sh.SalesHeadName,
        b.BranchName,

        COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
        SUM(so.TotalAmount) AS YearlyTurnover
    FROM dbo.SalesOrder so
    JOIN dbo.Distributor d 
        ON so.DistributorID = d.DistributorID
    JOIN dbo.SalesHead sh
        ON so.SalesHeadID = sh.SalesHeadID
    JOIN dbo.Branch b
        ON sh.BranchID = b.BranchID
    WHERE so.OrderStatus <> 'Cancelled'
    GROUP BY
        d.DistributorID,
        d.DistributorName,
        d.ActivityTier,
        d.CreditLimit,
        YEAR(so.OrderDate),
        sh.SalesHeadID,
        sh.SalesHeadName,
        b.BranchName
)
SELECT
    *,
    RANK() OVER (
        PARTITION BY SalesYear
        ORDER BY YearlyTurnover DESC
    ) AS YearlyRank
FROM DistributorSales;

ALTER VIEW dbo.vw_DistributorPerformance AS
WITH DistributorSales AS (
    SELECT
        d.DistributorID,
        d.DistributorName,
        d.ActivityTier,
        d.CreditLimit,

        YEAR(so.OrderDate) AS SalesYear,

        sh.SalesHeadID,
        sh.SalesHeadName,

        b.BranchID,
        b.BranchName,

        r.RegionID,
        r.RegionName,

        COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
        SUM(so.TotalAmount) AS YearlyTurnover

    FROM dbo.SalesOrder so

    JOIN dbo.Distributor d 
        ON so.DistributorID = d.DistributorID

    JOIN dbo.SalesHead sh
        ON so.SalesHeadID = sh.SalesHeadID

    JOIN dbo.Branch b
        ON sh.BranchID = b.BranchID

    JOIN dbo.Region r
        ON b.RegionID = r.RegionID

    WHERE so.OrderStatus <> 'Cancelled'

    GROUP BY
        d.DistributorID,
        d.DistributorName,
        d.ActivityTier,
        d.CreditLimit,
        YEAR(so.OrderDate),
        sh.SalesHeadID,
        sh.SalesHeadName,
        b.BranchID,
        b.BranchName,
        r.RegionID,
        r.RegionName
)
SELECT
    *,
    RANK() OVER (
        PARTITION BY SalesYear
        ORDER BY YearlyTurnover DESC
    ) AS YearlyRank
FROM DistributorSales;

CREATE VIEW dbo.vw_CrossRegionSales AS
SELECT
    sh.SalesHeadID,
    sh.SalesHeadName,

    b.BranchID AS SalesHeadBranchID,
    b.BranchName AS SalesHeadBranchName,
    sr.RegionID AS SalesHeadRegionID,
    sr.RegionName AS SalesHeadRegion,

    d.DistributorID,
    d.DistributorName,
    dr.RegionID AS DistributorRegionID,
    dr.RegionName AS DistributorRegion,

    YEAR(so.OrderDate) AS SalesYear,

    COUNT(DISTINCT so.SalesOrderID) AS TotalOrders,
    SUM(so.TotalAmount) AS TotalTurnover

FROM dbo.SalesOrder so

JOIN dbo.SalesHead sh
    ON so.SalesHeadID = sh.SalesHeadID

JOIN dbo.Branch b
    ON sh.BranchID = b.BranchID

JOIN dbo.Region sr
    ON b.RegionID = sr.RegionID

JOIN dbo.Distributor d
    ON so.DistributorID = d.DistributorID

JOIN dbo.Region dr
    ON d.RegionID = dr.RegionID

WHERE sr.RegionID <> dr.RegionID
  AND so.OrderStatus <> 'Cancelled'

GROUP BY
    sh.SalesHeadID,
    sh.SalesHeadName,
    b.BranchID,
    b.BranchName,
    sr.RegionID,
    sr.RegionName,
    d.DistributorID,
    d.DistributorName,
    dr.RegionID,
    dr.RegionName,
    YEAR(so.OrderDate);
