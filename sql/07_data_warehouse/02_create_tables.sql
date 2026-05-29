USE Akari_DW;
GO

CREATE TABLE dim.DimDate
(
    DateKey       INT NOT NULL PRIMARY KEY,
    FullDate      DATE NOT NULL,

    DayNumber     INT NOT NULL,
    DayName       NVARCHAR(20) NOT NULL,

    WeekNumber    INT NOT NULL,

    MonthNumber   INT NOT NULL,
    MonthName     NVARCHAR(20) NOT NULL,

    QuarterNumber INT NOT NULL,
    QuarterName   NVARCHAR(10) NOT NULL,

    YearNumber    INT NOT NULL,
    YearMonth     NVARCHAR(7) NOT NULL,

    IsWeekend     BIT NOT NULL DEFAULT 0,
    IsHoliday     BIT NOT NULL DEFAULT 0,
    HolidayName   NVARCHAR(100) NULL
);

CREATE TABLE dim.DimProduct
(
    ProductKey   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ProductID    INT NOT NULL,
    SKU          NVARCHAR(50) NOT NULL,
    ProductName  NVARCHAR(150) NOT NULL,
    CategoryID   INT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    IsActive     BIT NOT NULL DEFAULT 1
);

CREATE TABLE dim.DimGeography
(
    GeographyKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    RegionID     INT NOT NULL,
    RegionName   NVARCHAR(50) NOT NULL,
    BranchID     INT NOT NULL,
    BranchName   NVARCHAR(100) NOT NULL,
    IsActive     BIT NOT NULL DEFAULT 1
);

CREATE TABLE dim.DimSalesHead
(
    SalesHeadKey  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SalesHeadID   INT NOT NULL,
    SalesHeadName NVARCHAR(150) NOT NULL,
    BranchID      INT NOT NULL,
    BranchName    NVARCHAR(100) NOT NULL,
    RegionID      INT NOT NULL,
    RegionName    NVARCHAR(50) NOT NULL,
    IsActive      BIT NOT NULL DEFAULT 1
);

USE Akari_DW;
GO

CREATE TABLE dim.DimDistributor
(
    DistributorKey              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    DistributorID               INT NOT NULL,
    DistributorName             NVARCHAR(150) NOT NULL,

    City                        NVARCHAR(100) NULL,
    StateName                   NVARCHAR(100) NULL,

    BroadRegionID               INT NULL,
    BroadRegionName             NVARCHAR(50) NULL,

    AssignedSalesHeadID         INT NULL,
    AssignedSalesHeadName       NVARCHAR(150) NULL,
    AssignedSalesHeadBranch     NVARCHAR(100) NULL,
    AssignedSalesHeadBaseRegion NVARCHAR(50) NULL,

    CreditLimit                 DECIMAL(12,2) NULL,
    ActivityTier                NVARCHAR(50) NULL,

    IsActive                    BIT NOT NULL DEFAULT 1
);

USE Akari_DW;
GO

CREATE TABLE fact.FactSales
(
    FactSalesKey              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    SalesOrderID              INT NOT NULL,
    SalesOrderItemID          INT NOT NULL,
    OrderNumber               NVARCHAR(50) NOT NULL,

    OrderDateKey              INT NOT NULL,
    ProductKey                INT NOT NULL,
    DistributorKey            INT NOT NULL,
    SalesHeadKey              INT NOT NULL,
    GeographyKey              INT NOT NULL,

    Quantity                  INT NOT NULL,
    UnitPrice                 DECIMAL(12,2) NOT NULL,
    DiscountPercent           DECIMAL(5,2) NOT NULL,
    LineTotal                 DECIMAL(14,2) NOT NULL,

    OrderStatus               NVARCHAR(50) NOT NULL,

    IsCrossBaseRegionSale     BIT NOT NULL DEFAULT 0,
    IsOutsideAssignedSalesHead BIT NOT NULL DEFAULT 0
);



USE Akari_DW;
GO

CREATE TABLE fact.FactInventoryMovement
(
    InventoryMovementKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    MovementID           INT NOT NULL,
    MovementDateKey      INT NOT NULL,
    ProductKey           INT NOT NULL,

    FromGodownKey        INT NULL,
    ToGodownKey          INT NULL,

    FromGodownID         INT NULL,
    ToGodownID           INT NULL,

    MovementType         NVARCHAR(50) NOT NULL,
    Quantity             INT NOT NULL,

    InwardQuantity       INT NOT NULL DEFAULT 0,
    OutwardQuantity      INT NOT NULL DEFAULT 0,

    ReferenceID          INT NULL
);