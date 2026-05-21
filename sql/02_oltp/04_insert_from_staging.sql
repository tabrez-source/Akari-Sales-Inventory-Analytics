USE Akari_OLTP;
GO

INSERT INTO dbo.ProductCategory (CategoryName)
SELECT DISTINCT
    LTRIM(RTRIM(CategoryName))
FROM Akari_Staging.stg.ProductCategories_Raw
WHERE CategoryName IS NOT NULL
  AND LTRIM(RTRIM(CategoryName)) <> ''
  AND LTRIM(RTRIM(CategoryName)) NOT IN (
      SELECT CategoryName FROM dbo.ProductCategory
  );

INSERT INTO dbo.Product (
    CategoryID,
    SKU,
    ProductName,
    Brand,
    UnitOfMeasure,
    IsActive
)
SELECT DISTINCT
    pc.CategoryID,
    LTRIM(RTRIM(p.SKU)),
    
    -- ProductName (we construct it)
    LTRIM(RTRIM(
        p.CategoryName + ' ' + ISNULL(p.ModelNumber, '')
    )),
    
    'Akari', -- Brand (you can refine later)
    
    'PCS', -- default
    
    CASE 
        WHEN p.IsActive = '1' THEN 1
        ELSE 0
    END

FROM Akari_Staging.stg.Products_Raw p
JOIN dbo.ProductCategory pc
    ON LTRIM(RTRIM(p.CategoryName)) = pc.CategoryName

WHERE p.SKU IS NOT NULL
AND LTRIM(RTRIM(p.SKU)) <> '';

INSERT INTO dbo.Distributor (
    DistributorName,
    RegionID,
    CreditLimit,
    ActivityTier,
    City,
    IsActive
)
SELECT DISTINCT
    LTRIM(RTRIM(d.DistributorName)),
    
    r.RegionID,
    
    CAST(d.CreditLimit AS DECIMAL(18,2)),
    
    LTRIM(RTRIM(d.ActivityTier)),
    
    LTRIM(RTRIM(d.City)),
    
    CASE 
        WHEN d.IsActive = '1' THEN 1
        ELSE 0
    END

FROM Akari_Staging.stg.Distributors_Raw d

JOIN dbo.Branch b
    ON b.BranchID = CAST(d.RegionBranchID AS INT)

JOIN dbo.Region r
    ON b.RegionID = r.RegionID

WHERE d.DistributorName IS NOT NULL
AND LTRIM(RTRIM(d.DistributorName)) <> '';

INSERT INTO dbo.DistributorSalesHeadAssignment
(
    DistributorID,
    SalesHeadID,
    AssignedFrom,
    AssignedTo,
    IsActive
)
SELECT
    d_oltp.DistributorID,
    sh.SalesHeadID,
    CAST('2020-01-01' AS DATE) AS AssignedFrom,
    NULL AS AssignedTo,
    1 AS IsActive
FROM Akari_Staging.stg.Distributors_Raw d_raw
JOIN dbo.Distributor d_oltp
    ON LTRIM(RTRIM(d_raw.DistributorName)) = d_oltp.DistributorName
JOIN dbo.SalesHead sh
    ON sh.SalesHeadID = CAST(d_raw.AssignedSalesHeadID AS INT);

INSERT INTO dbo.SalesOrder
(
    DistributorID,
    SalesHeadID,
    OrderDate,
    OrderStatus,
    IsCredit
)
SELECT
    d.DistributorID,
    sh.SalesHeadID,
    TRY_CONVERT(DATE, so.OrderDate),
    LTRIM(RTRIM(so.OrderStatus)),
    1 AS IsCredit
FROM Akari_Staging.stg.SalesOrders_Raw so
JOIN dbo.Distributor d
    ON d.DistributorID = CAST(so.DistributorID AS INT)
JOIN dbo.SalesHead sh
    ON sh.SalesHeadID = CAST(so.SalesHeadID AS INT)
WHERE TRY_CONVERT(DATE, so.OrderDate) IS NOT NULL;

INSERT INTO dbo.SalesOrderItem
(
    SalesOrderID,
    ProductID,
    Quantity,
    UnitPrice,
    DiscountPercent
)
SELECT
    so.SalesOrderID,
    p.ProductID,
    CAST(i.Quantity AS INT),
    CAST(i.UnitPrice AS DECIMAL(18,2)),
    CAST(i.DiscountPercent AS DECIMAL(5,2))
FROM Akari_Staging.stg.SalesOrderItems_Raw i
JOIN dbo.SalesOrder so
    ON so.SalesOrderID = CAST(i.SalesOrderID AS INT)
JOIN dbo.Product p
    ON p.SKU = LTRIM(RTRIM(i.SKU))
WHERE TRY_CAST(i.Quantity AS INT) > 0
  AND TRY_CAST(i.UnitPrice AS DECIMAL(18,2)) IS NOT NULL
  AND TRY_CAST(i.DiscountPercent AS DECIMAL(5,2)) IS NOT NULL;

  -- Calculates totals per order derived from SalesOrder    
  UPDATE so
SET so.TotalAmount = x.OrderTotal
FROM dbo.SalesOrder so
JOIN (
    SELECT 
        SalesOrderID,
        SUM(LineTotal) AS OrderTotal
    FROM dbo.SalesOrderItem
    GROUP BY SalesOrderID
) x
ON so.SalesOrderID = x.SalesOrderID;

INSERT INTO dbo.Dispatch
(
    SalesOrderID,
    GodownID,
    DispatchDate,
    LRNumber,
    TransporterName,
    DispatchStatus
)
SELECT
    so.SalesOrderID,
    g.GodownID,
    TRY_CONVERT(DATE, d.DispatchDate),
    LTRIM(RTRIM(d.LRNumber)),
    LTRIM(RTRIM(d.TransportName)),
    LTRIM(RTRIM(d.DispatchStatus))
FROM Akari_Staging.stg.Dispatches_Raw d
JOIN dbo.SalesOrder so
    ON so.SalesOrderID = CAST(d.SalesOrderID AS INT)
JOIN dbo.Godown g
    ON g.GodownID = CAST(d.GodownID AS INT)
WHERE TRY_CONVERT(DATE, d.DispatchDate) IS NOT NULL;

-- Insert InventoryMovement (from Dispatch)
INSERT INTO dbo.InventoryMovement
(
    ProductID,
    FromGodownID,
    Quantity,
    MovementType,
    ReferenceID,
    MovementDate
)
SELECT
    soi.ProductID,
    d.GodownID,
    soi.Quantity,
    'OUTWARD',
    d.DispatchID,
    d.DispatchDate
FROM dbo.Dispatch d
JOIN dbo.SalesOrderItem soi
    ON soi.SalesOrderID = d.SalesOrderID;

-- Insert InventoryMovement (Inwards)
INSERT INTO dbo.InventoryMovement
(
    ProductID,
    FromGodownID,
    ToGodownID,
    Quantity,
    MovementType,
    ReferenceID,
    MovementDate
)
SELECT
    p.ProductID,
    NULL AS FromGodownID,
    g.GodownID AS ToGodownID,
    CAST(i.Quantity AS INT),
    'INWARD',
    CAST(i.InwardID AS INT),
    TRY_CONVERT(DATE, i.InwardDate)
FROM Akari_Staging.stg.StockInward_Raw i
JOIN dbo.Product p
    ON p.SKU = LTRIM(RTRIM(i.SKU))
JOIN dbo.Godown g
    ON g.GodownID = CAST(i.GodownID AS INT)
WHERE TRY_CONVERT(DATE, i.InwardDate) IS NOT NULL
  AND TRY_CAST(i.Quantity AS INT) > 0;

  INSERT INTO dbo.PriceListHeader
(
    PriceListID,
    PriceListDate,
    BranchID,
    Status
)
SELECT
    CAST(PriceListID AS INT),
    TRY_CONVERT(DATE, PriceListDate),
    CAST(BranchID AS INT),
    LTRIM(RTRIM(Status))
FROM Akari_Staging.stg.PriceLists_Raw
WHERE TRY_CONVERT(DATE, PriceListDate) IS NOT NULL;

INSERT INTO dbo.ProductPriceHistory
(
    ProductID,
    EffectiveFromDate,
    EffectiveToDate,
    UnitPrice,
    PriceListBranch
)
SELECT
    p.ProductID,
    TRY_CONVERT(DATE, ph.EffectiveFromDate),
    TRY_CONVERT(DATE, ph.EffectiveToDate),
    CAST(ph.UnitPrice AS DECIMAL(18,2)),
    LTRIM(RTRIM(ph.PriceListBranch))
FROM Akari_Staging.stg.ProductPriceHistory_Raw ph
JOIN dbo.Product p
    ON p.SKU = LTRIM(RTRIM(ph.SKU))
WHERE TRY_CONVERT(DATE, ph.EffectiveFromDate) IS NOT NULL
  AND TRY_CONVERT(DATE, ph.EffectiveToDate) IS NOT NULL;

INSERT INTO dbo.Scheme
(
    SchemeName,
    SchemeType,
    StartDate,
    EndDate,
    IsActive
)
SELECT
    LTRIM(RTRIM(SchemeName)),
    LTRIM(RTRIM(SchemeType)),
    TRY_CONVERT(DATE, StartDate),
    TRY_CONVERT(DATE, EndDate),
    CASE WHEN IsActive = '1' THEN 1 ELSE 0 END
FROM Akari_Staging.stg.Schemes_Raw
WHERE TRY_CONVERT(DATE, StartDate) IS NOT NULL;

INSERT INTO dbo.SchemeSlab
(
    SchemeID,
    SlabName,
    MinTurnover,
    MaxTurnover,
    BenefitType,
    BenefitValue
)
SELECT
    CAST(SchemeID AS INT),
    LTRIM(RTRIM(SlabName)),
    CAST(MinTurnover AS DECIMAL(18,2)),
    CAST(MaxTurnover AS DECIMAL(18,2)),
    LTRIM(RTRIM(BenefitType)),
    CAST(BenefitValue AS DECIMAL(10,2))
FROM Akari_Staging.stg.SchemeSlabs_Raw;