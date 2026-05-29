SELECT COUNT(*) AS ViewRowCount
FROM rpt.vw_SalesAnalysis;

SELECT COUNT(*) AS FactSalesRowCount
FROM fact.FactSales;

SELECT
    SUM(LineTotal) AS ViewTotalSales
FROM rpt.vw_SalesAnalysis;

SELECT
    SUM(LineTotal) AS FactTotalSales
FROM fact.FactSales;

SELECT
    SalesOwnershipStatus,
    COUNT(*) AS TotalRows,
    SUM(LineTotal) AS TotalSales
FROM rpt.vw_SalesAnalysis
GROUP BY SalesOwnershipStatus;

SELECT COUNT(*) AS ViewRowCount
FROM rpt.vw_InventoryMovementAnalysis;

SELECT COUNT(*) AS FactInventoryMovementRowCount
FROM fact.FactInventoryMovement;

SELECT
    SUM(InwardQuantity) AS ViewTotalInward,
    SUM(OutwardQuantity) AS ViewTotalOutward,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS ViewNetMovement
FROM rpt.vw_InventoryMovementAnalysis;

SELECT
    SUM(InwardQuantity) AS FactTotalInward,
    SUM(OutwardQuantity) AS FactTotalOutward,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS FactNetMovement
FROM fact.FactInventoryMovement;

SELECT
    MovementTypeLabel,
    COUNT(*) AS TotalRows,
    SUM(Quantity) AS TotalQuantity,
    SUM(InwardQuantity) AS TotalInwardQuantity,
    SUM(OutwardQuantity) AS TotalOutwardQuantity
FROM rpt.vw_InventoryMovementAnalysis
GROUP BY MovementTypeLabel;

SELECT TOP 50 *
FROM rpt.vw_DistributorSalesHeadPerformance
ORDER BY YearNumber, TotalSales DESC;

SELECT SUM(TotalSales) AS ViewTotalSales
FROM rpt.vw_DistributorSalesHeadPerformance;

SELECT SUM(LineTotal) AS FactTotalSales
FROM fact.FactSales;

SELECT
    SalesOwnershipStatus,
    SUM(TotalOrders) AS TotalOrders,
    SUM(TotalOrderLines) AS TotalOrderLines,
    SUM(TotalQuantity) AS TotalQuantity,
    SUM(TotalSales) AS TotalSales
FROM rpt.vw_DistributorSalesHeadPerformance
GROUP BY SalesOwnershipStatus;

SELECT TOP(10)
    YearNumber,
    DistributorName,
    DistributorCity,
    DistributorState,
    ActualSalesHeadName,
    SalesOwnershipStatus,
    TotalSales,
    DistributorSalesRankByYear
FROM rpt.vw_DistributorSalesHeadPerformance
WHERE DistributorSalesRankByYear <= 10
ORDER BY YearNumber, DistributorSalesRankByYear;

SELECT TOP 50 *
FROM rpt.vw_ProductPerformance
ORDER BY YearMonth, TotalSales DESC;

SELECT SUM(TotalSales) AS ViewTotalSales
FROM rpt.vw_ProductPerformance;

SELECT SUM(LineTotal) AS FactTotalSales
FROM fact.FactSales;

SELECT
    YearMonth,
    ProductName,
    CategoryName,
    TotalQuantitySold,
    TotalSales,
    ProductSalesRankByMonth
FROM rpt.vw_ProductPerformance
WHERE ProductSalesRankByMonth <= 10
ORDER BY YearMonth, ProductSalesRankByMonth;

SELECT
    CategoryName,
    SUM(TotalOrders) AS TotalOrders,
    SUM(TotalQuantitySold) AS TotalQuantitySold,
    SUM(TotalSales) AS TotalSales
FROM rpt.vw_ProductPerformance
GROUP BY CategoryName
ORDER BY TotalSales DESC;

SELECT TOP 50 *
FROM rpt.vw_SalesHeadPerformance
ORDER BY YearMonth, TotalSales DESC;

SELECT SUM(TotalSales) AS ViewTotalSales
FROM rpt.vw_SalesHeadPerformance;

SELECT SUM(LineTotal) AS FactTotalSales
FROM fact.FactSales;

SELECT
    YearMonth,
    SalesHeadName,
    BranchName,
    RegionName,
    TotalOrders,
    ActiveDistributors,
    TotalQuantitySold,
    TotalSales,
    SalesHeadSalesRankByMonth
FROM rpt.vw_SalesHeadPerformance
ORDER BY YearMonth, SalesHeadSalesRankByMonth;

SELECT TOP 50 *
FROM rpt.vw_InventoryProductMovement
ORDER BY YearMonth, TotalOutwardQuantity DESC;

SELECT
    SUM(TotalInwardQuantity) AS ViewTotalInward,
    SUM(TotalOutwardQuantity) AS ViewTotalOutward,
    SUM(NetMovementQuantity) AS ViewNetMovement
FROM rpt.vw_InventoryProductMovement;

SELECT
    SUM(InwardQuantity) AS FactTotalInward,
    SUM(OutwardQuantity) AS FactTotalOutward,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS FactNetMovement
FROM fact.FactInventoryMovement;

SELECT
    YearMonth,
    ProductName,
    CategoryName,
    TotalOutwardQuantity,
    ProductOutwardRankByMonth
FROM rpt.vw_InventoryProductMovement
WHERE ProductOutwardRankByMonth <= 10
ORDER BY YearMonth, ProductOutwardRankByMonth;

SELECT
    YearMonth,
    ProductName,
    CategoryName,
    TotalInwardQuantity,
    TotalOutwardQuantity,
    NetMovementQuantity,
    CAST(
        TotalOutwardQuantity * 100.0 / NULLIF(TotalInwardQuantity, 0)
        AS DECIMAL(10,2)
    ) AS OutwardToInwardPercent
FROM rpt.vw_InventoryProductMovement
WHERE TotalInwardQuantity > 0
  AND YearMonth > '2019-12'
  AND TotalOutwardQuantity < TotalInwardQuantity * 0.20
ORDER BY YearMonth, OutwardToInwardPercent ASC;



SELECT
    MovementID,
    MovementDate,
    ProductID,
    SKU,
    ProductName,
    CategoryName,
    MovementType,
    Quantity,
    ToGodownName,
    EffectiveGodownName,
    ReferenceID
FROM rpt.vw_InventoryMovementAnalysis
WHERE MovementType = 'INWARD'
  AND MovementDate > '2019-12-31'
  AND Quantity > 1000000
ORDER BY Quantity DESC;

SELECT TOP 50 *
FROM rpt.vw_GodownInventorySummary
ORDER BY YearMonth, GodownName, NetMovementQuantity DESC;

SELECT
    SUM(TotalInwardQuantity) AS ViewTotalInward,
    SUM(TotalOutwardQuantity) AS ViewTotalOutward,
    SUM(NetMovementQuantity) AS ViewNetMovement
FROM rpt.vw_GodownInventorySummary;

SELECT
    SUM(InwardQuantity) AS FactTotalInward,
    SUM(OutwardQuantity) AS FactTotalOutward,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS FactNetMovement
FROM fact.FactInventoryMovement;

SELECT TOP 50 *
FROM rpt.vw_CategoryPerformance
ORDER BY YearMonth, TotalSales DESC;

SELECT SUM(TotalSales) AS ViewTotalSales
FROM rpt.vw_CategoryPerformance;

SELECT SUM(LineTotal) AS FactTotalSales
FROM fact.FactSales;

SELECT
    SUM(TotalInwardQuantity) AS ViewTotalInward,
    SUM(TotalOutwardQuantity) AS ViewTotalOutward,
    SUM(NetMovementQuantity) AS ViewNetMovement
FROM rpt.vw_CategoryPerformance;

SELECT
    SUM(InwardQuantity) AS FactTotalInward,
    SUM(OutwardQuantity) AS FactTotalOutward,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS FactNetMovement
FROM fact.FactInventoryMovement;

SELECT *
FROM rpt.vw_ExecutiveSalesSummary
ORDER BY YearMonth;

SELECT SUM(TotalSales) AS ViewTotalSales
FROM rpt.vw_ExecutiveSalesSummary;

SELECT SUM(LineTotal) AS FactTotalSales
FROM fact.FactSales;

SELECT
    SUM(TotalInwardQuantity) AS ViewTotalInward,
    SUM(TotalOutwardQuantity) AS ViewTotalOutward,
    SUM(NetMovementQuantity) AS ViewNetMovement
FROM rpt.vw_ExecutiveSalesSummary;

SELECT
    SUM(InwardQuantity) AS FactTotalInward,
    SUM(OutwardQuantity) AS FactTotalOutward,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS FactNetMovement
FROM fact.FactInventoryMovement;