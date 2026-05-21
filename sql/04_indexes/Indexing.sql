-- SalesOrder
CREATE INDEX IX_SalesOrder_DistributorID
ON dbo.SalesOrder (DistributorID);

CREATE INDEX IX_SalesOrder_SalesHeadID
ON dbo.SalesOrder (SalesHeadID);

CREATE INDEX IX_SalesOrder_OrderDate
ON dbo.SalesOrder (OrderDate);

CREATE INDEX IX_SalesOrder_OrderStatus
ON dbo.SalesOrder (OrderStatus);

-- SalesOrderItem
CREATE INDEX IX_SalesOrderItem_SalesOrderID
ON dbo.SalesOrderItem (SalesOrderID);

CREATE INDEX IX_SalesOrderItem_ProductID
ON dbo.SalesOrderItem (ProductID);

-- Dispatch
CREATE INDEX IX_Dispatch_SalesOrderID
ON dbo.Dispatch (SalesOrderID);

CREATE INDEX IX_Dispatch_GodownID
ON dbo.Dispatch (GodownID);

-- InventoryMovement
CREATE INDEX IX_InventoryMovement_ProductID
ON dbo.InventoryMovement (ProductID);

CREATE INDEX IX_InventoryMovement_FromGodownID
ON dbo.InventoryMovement (FromGodownID);

CREATE INDEX IX_InventoryMovement_ToGodownID
ON dbo.InventoryMovement (ToGodownID);

CREATE INDEX IX_InventoryMovement_MovementType
ON dbo.InventoryMovement (MovementType);

-- Distributor
CREATE INDEX IX_Distributor_RegionID
ON dbo.Distributor (RegionID);

-- Product
CREATE INDEX IX_Product_CategoryID
ON dbo.Product (CategoryID);