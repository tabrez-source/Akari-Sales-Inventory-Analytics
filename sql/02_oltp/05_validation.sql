USE Akari_OLTP;
GO

SELECT *
FROM dbo.ProductCategory
ORDER BY CategoryID;

SELECT 
    p.ProductID,
    p.SKU,
    p.ProductName,
    pc.CategoryName
FROM dbo.Product p
JOIN dbo.ProductCategory pc
    ON p.CategoryID = pc.CategoryID;

SELECT COUNT(*) FROM dbo.Product;

SELECT 
    d.DistributorID,
    d.DistributorName,
    d.City,
    r.RegionName,
    d.CreditLimit,
    d.ActivityTier
FROM dbo.Distributor d
JOIN dbo.Region r
    ON d.RegionID = r.RegionID;

SELECT COUNT(*) FROM dbo.Distributor;

SELECT 
    a.AssignmentID,
    d.DistributorName,
    sh.SalesHeadName,
    a.AssignedFrom,
    a.AssignedTo,
    a.IsActive
FROM dbo.DistributorSalesHeadAssignment a
JOIN dbo.Distributor d ON a.DistributorID = d.DistributorID
JOIN dbo.SalesHead sh ON a.SalesHeadID = sh.SalesHeadID;

SELECT TOP 20
    so.SalesOrderID,
    d.DistributorName,
    sh.SalesHeadName,
    so.OrderDate,
    so.OrderStatus
FROM dbo.SalesOrder so
JOIN dbo.Distributor d ON so.DistributorID = d.DistributorID
JOIN dbo.SalesHead sh ON so.SalesHeadID = sh.SalesHeadID
ORDER BY so.SalesOrderID;

SELECT TOP 20
    SalesOrderID,
    OrderNumber,
    OrderDate,
    OrderStatus
FROM dbo.SalesOrder
ORDER BY SalesOrderID;

SELECT TOP 20
    so.OrderNumber,
    p.SKU,
    p.ProductName,
    soi.Quantity,
    soi.UnitPrice,
    soi.DiscountPercent,
    soi.LineTotal
FROM dbo.SalesOrderItem soi
JOIN dbo.SalesOrder so ON soi.SalesOrderID = so.SalesOrderID
JOIN dbo.Product p ON soi.ProductID = p.ProductID
ORDER BY so.SalesOrderID;

SELECT TOP 20
    SalesOrderID,
    OrderNumber,
    TotalAmount
FROM dbo.SalesOrder
ORDER BY SalesOrderID;

SELECT COUNT(*) FROM dbo.Dispatch;

SELECT TOP 20
    d.DispatchID,
    so.OrderNumber,
    g.GodownName,
    d.DispatchDate,
    d.LRNumber,
    d.TransporterName,
    d.DispatchStatus
FROM dbo.Dispatch d
JOIN dbo.SalesOrder so ON d.SalesOrderID = so.SalesOrderID
JOIN dbo.Godown g ON d.GodownID = g.GodownID
ORDER BY d.DispatchID;

SELECT TOP 20
    p.ProductName,
    g.GodownName,
    im.Quantity,
    im.MovementType,
    im.MovementDate
FROM dbo.InventoryMovement im
JOIN dbo.Product p ON im.ProductID = p.ProductID
LEFT JOIN dbo.Godown g ON im.FromGodownID = g.GodownID;

SELECT 
    MovementType,
    COUNT(*) AS MovementCount,
    SUM(Quantity) AS TotalQuantity
FROM dbo.InventoryMovement
GROUP BY MovementType;

DECLARE @TargetInward BIGINT;
DECLARE @CurrentInward BIGINT;
DECLARE @Difference BIGINT;

SELECT @TargetInward = CAST(SUM(CASE WHEN MovementType = 'OUTWARD' THEN Quantity ELSE 0 END) * 1.20 AS BIGINT)
FROM dbo.InventoryMovement;

SELECT @CurrentInward = SUM(Quantity)
FROM dbo.InventoryMovement
WHERE MovementType = 'INWARD';

SET @Difference = @TargetInward - @CurrentInward;

UPDATE TOP (1) dbo.InventoryMovement
SET Quantity = Quantity + @Difference
WHERE MovementType = 'INWARD';

SELECT 
    MovementType,
    COUNT(*) AS MovementCount,
    SUM(Quantity) AS TotalQuantity
FROM dbo.InventoryMovement
GROUP BY MovementType;

SELECT TOP 20 *
FROM dbo.PriceListHeader
ORDER BY PriceListID;

SELECT TOP 20
    p.ProductName,
    ph.EffectiveFromDate,
    ph.EffectiveToDate,
    ph.UnitPrice
FROM dbo.ProductPriceHistory ph
JOIN dbo.Product p ON ph.ProductID = p.ProductID
ORDER BY ph.ProductID, ph.EffectiveFromDate;

SELECT 
    s.SchemeName,
    ss.SlabName,
    ss.MinTurnover,
    ss.MaxTurnover,
    ss.BenefitType,
    ss.BenefitValue
FROM dbo.SchemeSlab ss
JOIN dbo.Scheme s ON ss.SchemeID = s.SchemeID
ORDER BY s.SchemeID, ss.MinTurnover;

-- Final Validation
-- 1. Row count health check
SELECT 'ProductCategory' AS TableName, COUNT(*) AS TotalRows FROM dbo.ProductCategory
UNION ALL
SELECT 'Product', COUNT(*) FROM dbo.Product
UNION ALL
SELECT 'Distributor', COUNT(*) FROM dbo.Distributor
UNION ALL
SELECT 'SalesOrder', COUNT(*) FROM dbo.SalesOrder
UNION ALL
SELECT 'SalesOrderItem', COUNT(*) FROM dbo.SalesOrderItem
UNION ALL
SELECT 'Dispatch', COUNT(*) FROM dbo.Dispatch
UNION ALL
SELECT 'InventoryMovement', COUNT(*) FROM dbo.InventoryMovement
UNION ALL
SELECT 'Scheme', COUNT(*) FROM dbo.Scheme
UNION ALL
SELECT 'SchemeSlab', COUNT(*) FROM dbo.SchemeSlab;

    -- Orders without dispatch
    SELECT 
        so.OrderStatus,
        COUNT(*) AS OrderCount
    FROM dbo.SalesOrder so
    LEFT JOIN dbo.Dispatch d
        ON so.SalesOrderID = d.SalesOrderID
    WHERE d.DispatchID IS NULL
    GROUP BY so.OrderStatus;

-- 2. Check orders without items
SELECT so.SalesOrderID, so.OrderNumber
FROM dbo.SalesOrder so
LEFT JOIN dbo.SalesOrderItem soi 
    ON so.SalesOrderID = soi.SalesOrderID
WHERE soi.SalesOrderItemID IS NULL;

-- 3. Check negative stock by product + godown
SELECT 
    p.SKU,
    p.ProductName,
    g.GodownName,
    SUM(CASE 
        WHEN im.MovementType = 'INWARD' THEN im.Quantity
        WHEN im.MovementType = 'OUTWARD' THEN -im.Quantity
        ELSE 0
    END) AS CurrentStock
FROM dbo.InventoryMovement im
JOIN dbo.Product p ON im.ProductID = p.ProductID
LEFT JOIN dbo.Godown g 
    ON COALESCE(im.ToGodownID, im.FromGodownID) = g.GodownID
GROUP BY p.SKU, p.ProductName, g.GodownName
HAVING SUM(CASE 
        WHEN im.MovementType = 'INWARD' THEN im.Quantity
        WHEN im.MovementType = 'OUTWARD' THEN -im.Quantity
        ELSE 0
    END) < 0;


-- Completed with dispatch vs without dispatch
SELECT 
    CASE 
        WHEN d.DispatchID IS NULL THEN 'Completed without Dispatch'
        ELSE 'Completed with Dispatch'
    END AS CompletedDispatchStatus,
    COUNT(*) AS OrderCount
FROM dbo.SalesOrder so
LEFT JOIN dbo.Dispatch d
    ON so.SalesOrderID = d.SalesOrderID
WHERE so.OrderStatus = 'Completed'
GROUP BY 
    CASE 
        WHEN d.DispatchID IS NULL THEN 'Completed without Dispatch'
        ELSE 'Completed with Dispatch'
    END;