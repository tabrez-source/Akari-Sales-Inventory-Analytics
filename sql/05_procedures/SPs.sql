CREATE OR ALTER PROCEDURE dbo.sp_UpdateSalesOrderTotals
AS
BEGIN
    SET NOCOUNT ON;

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
END;

EXEC dbo.sp_UpdateSalesOrderTotals;

CREATE OR ALTER PROCEDURE dbo.sp_ValidateOLTPHealth
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 'OrdersWithoutItems' AS CheckName, COUNT(*) AS IssueCount
    FROM dbo.SalesOrder so
    LEFT JOIN dbo.SalesOrderItem soi
        ON so.SalesOrderID = soi.SalesOrderID
    WHERE soi.SalesOrderItemID IS NULL

    UNION ALL

    SELECT 'ItemsWithoutProduct', COUNT(*)
    FROM dbo.SalesOrderItem soi
    LEFT JOIN dbo.Product p
        ON soi.ProductID = p.ProductID
    WHERE p.ProductID IS NULL

    UNION ALL

    SELECT 'BadOrderReferences', COUNT(*)
    FROM dbo.SalesOrder so
    LEFT JOIN dbo.Distributor d ON so.DistributorID = d.DistributorID
    LEFT JOIN dbo.SalesHead sh ON so.SalesHeadID = sh.SalesHeadID
    WHERE d.DistributorID IS NULL
       OR sh.SalesHeadID IS NULL;
END;

EXEC dbo.sp_ValidateOLTPHealth;