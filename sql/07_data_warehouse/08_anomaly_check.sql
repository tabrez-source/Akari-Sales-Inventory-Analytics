-- Data Anomaly 
USE Akari_OLTP;
GO

IF OBJECT_ID('dbo.InventoryMovement_Anomaly_Backup', 'U') IS NULL
BEGIN
    SELECT *
    INTO dbo.InventoryMovement_Anomaly_Backup
    FROM dbo.InventoryMovement
    WHERE MovementID = 548857;
END;

SELECT *
FROM dbo.InventoryMovement_Anomaly_Backup;

USE Akari_OLTP;
GO

UPDATE dbo.InventoryMovement
SET Quantity = 394847
WHERE MovementID = 548857
  AND ProductID = 76
  AND MovementType = 'INWARD'
  AND Quantity = 39484785;

  SELECT *
FROM dbo.InventoryMovement
WHERE MovementID = 548857;

USE Akari_DW;
GO

TRUNCATE TABLE fact.FactInventoryMovement;
GO

SELECT
    SUM(InwardQuantity) AS TotalInwardQuantity,
    SUM(OutwardQuantity) AS TotalOutwardQuantity,
    SUM(InwardQuantity) - SUM(OutwardQuantity) AS NetMovementQuantity
FROM Akari_DW.fact.FactInventoryMovement;

SELECT
    MovementID,
    MovementDate,
    ProductID,
    ProductName,
    MovementType,
    Quantity
FROM rpt.vw_InventoryMovementAnalysis
WHERE MovementType = 'INWARD'
  AND MovementDate > '2019-12-31'
  AND Quantity > 1000000;

