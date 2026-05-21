use Akari_OLTP;
CREATE TABLE Region (
    RegionID INT IDENTITY PRIMARY KEY,
    RegionName NVARCHAR(50) NOT NULL UNIQUE,
    CreatedAt DATETIME DEFAULT GETDATE()
);


CREATE TABLE dbo.Branch (
    BranchID INT IDENTITY(1,1) PRIMARY KEY,
    BranchName NVARCHAR(100) NOT NULL,
    RegionID INT NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Branch_Region
    FOREIGN KEY (RegionID) REFERENCES dbo.Region(RegionID),

    CONSTRAINT UQ_Branch_Name UNIQUE (BranchName)
);


CREATE TABLE dbo.SalesHead (
    SalesHeadID INT IDENTITY(1,1) PRIMARY KEY,
    SalesHeadName NVARCHAR(100) NOT NULL,
    BranchID INT NOT NULL,
    Phone NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_SalesHead_Branch
    FOREIGN KEY (BranchID) REFERENCES dbo.Branch(BranchID)
);


CREATE TABLE dbo.Distributor (
    DistributorID INT IDENTITY(1,1) PRIMARY KEY,
    DistributorName NVARCHAR(150) NOT NULL,
    RegionID INT NOT NULL,
    CreditLimit DECIMAL(18,2) NOT NULL,
    ActivityTier NVARCHAR(20) NOT NULL, -- Top, Regular, Occasional, Dormant
    Phone NVARCHAR(20) NULL,
    City NVARCHAR(100) NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Distributor_Region
    FOREIGN KEY (RegionID) REFERENCES dbo.Region(RegionID)
);


CREATE TABLE dbo.DistributorSalesHeadAssignment (
    AssignmentID INT IDENTITY(1,1) PRIMARY KEY,
    DistributorID INT NOT NULL,
    SalesHeadID INT NOT NULL,
    AssignedFrom DATE NOT NULL,
    AssignedTo DATE NULL, -- NULL = currently active
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Assignment_Distributor
    FOREIGN KEY (DistributorID) REFERENCES dbo.Distributor(DistributorID),

    CONSTRAINT FK_Assignment_SalesHead
    FOREIGN KEY (SalesHeadID) REFERENCES dbo.SalesHead(SalesHeadID)
);


CREATE TABLE dbo.ProductCategory (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);


CREATE TABLE dbo.Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryID INT NOT NULL,
    SKU NVARCHAR(50) NOT NULL,
    ProductName NVARCHAR(150) NOT NULL,
    Brand NVARCHAR(50) NULL,
    UnitOfMeasure NVARCHAR(20) NOT NULL DEFAULT 'PCS',
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Product_Category
    FOREIGN KEY (CategoryID) REFERENCES dbo.ProductCategory(CategoryID),

    CONSTRAINT UQ_Product_SKU UNIQUE (SKU)
);


CREATE TABLE dbo.Godown (
    GodownID INT IDENTITY(1,1) PRIMARY KEY,
    GodownName NVARCHAR(100) NOT NULL,
    BranchID INT NULL, -- NULL for central warehouse (Bhiwandi)
    Location NVARCHAR(100) NOT NULL,
    IsCentral BIT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Godown_Branch
    FOREIGN KEY (BranchID) REFERENCES dbo.Branch(BranchID),

    CONSTRAINT UQ_Godown_Name UNIQUE (GodownName)
);


CREATE TABLE dbo.SalesOrder (
    SalesOrderID INT IDENTITY(1,1) PRIMARY KEY,
    DistributorID INT NOT NULL,
    SalesHeadID INT NOT NULL,
    OrderDate DATE NOT NULL,
    OrderStatus NVARCHAR(20) NOT NULL DEFAULT 'Pending', 
    TotalAmount DECIMAL(18,2) NULL, -- calculated later
    IsCredit BIT NOT NULL DEFAULT 1, -- most sales on credit
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_SalesOrder_Distributor
    FOREIGN KEY (DistributorID) REFERENCES dbo.Distributor(DistributorID),

    CONSTRAINT FK_SalesOrder_SalesHead
    FOREIGN KEY (SalesHeadID) REFERENCES dbo.SalesHead(SalesHeadID)
);


CREATE TABLE dbo.SalesOrderItem (
    SalesOrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    DiscountPercent DECIMAL(5,2) NOT NULL DEFAULT 0,
    LineTotal AS (
        Quantity * UnitPrice * (1 - DiscountPercent / 100.0)
    ) PERSISTED,

    CONSTRAINT FK_SalesOrderItem_SalesOrder
    FOREIGN KEY (SalesOrderID) REFERENCES dbo.SalesOrder(SalesOrderID),

    CONSTRAINT FK_SalesOrderItem_Product
    FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID),

    CONSTRAINT CK_SalesOrderItem_Quantity
    CHECK (Quantity > 0),

    CONSTRAINT CK_SalesOrderItem_Discount
    CHECK (DiscountPercent >= 0 AND DiscountPercent <= 100)
);


CREATE TABLE dbo.Dispatch (
    DispatchID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    GodownID INT NOT NULL,
    DispatchDate DATE NOT NULL,
    LRNumber NVARCHAR(50) NULL,
    TransporterName NVARCHAR(100) NULL,
    DispatchStatus NVARCHAR(20) NOT NULL DEFAULT 'Dispatched',
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Dispatch_SalesOrder
    FOREIGN KEY (SalesOrderID) REFERENCES dbo.SalesOrder(SalesOrderID),

    CONSTRAINT FK_Dispatch_Godown
    FOREIGN KEY (GodownID) REFERENCES dbo.Godown(GodownID)
);


CREATE TABLE dbo.InventoryMovement (
    MovementID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    FromGodownID INT NULL,
    ToGodownID INT NULL,
    Quantity INT NOT NULL,
    MovementType NVARCHAR(20) NOT NULL, 
    -- INWARD, OUTWARD, TRANSFER
    ReferenceID INT NULL, -- SalesOrderID / DispatchID
    MovementDate DATE NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Inventory_Product
    FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID),

    CONSTRAINT FK_Inventory_FromGodown
    FOREIGN KEY (FromGodownID) REFERENCES dbo.Godown(GodownID),

    CONSTRAINT FK_Inventory_ToGodown
    FOREIGN KEY (ToGodownID) REFERENCES dbo.Godown(GodownID),

    CONSTRAINT CK_Inventory_Quantity
    CHECK (Quantity > 0)
);


--Coming soon
CREATE TABLE dbo.Payment (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    DistributorID INT NOT NULL,
    PaymentDate DATE NOT NULL,
    AmountPaid DECIMAL(18,2) NOT NULL,
    PaymentMode NVARCHAR(30) NULL, -- Cash, Bank, UPI, Cheque
    ReferenceNumber NVARCHAR(50) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Payment_SalesOrder
    FOREIGN KEY (SalesOrderID) REFERENCES dbo.SalesOrder(SalesOrderID),

    CONSTRAINT FK_Payment_Distributor
    FOREIGN KEY (DistributorID) REFERENCES dbo.Distributor(DistributorID),

    CONSTRAINT CK_Payment_Amount
    CHECK (AmountPaid > 0)
);

SELECT * FROM dbo.Payment;

CREATE TABLE dbo.PriceList (
    PriceListID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    EffectiveFrom DATE NOT NULL,
    EffectiveTo DATE NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_PriceList_Product
    FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID)
);

CREATE TABLE dbo.Scheme (
    SchemeID INT IDENTITY(1,1) PRIMARY KEY,
    SchemeName NVARCHAR(100) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    IsActive BIT DEFAULT 1
);

CREATE TABLE dbo.SchemeSlab (
    SchemeSlabID INT IDENTITY(1,1) PRIMARY KEY,
    SchemeID INT NOT NULL,
    MinAmount DECIMAL(18,2) NOT NULL,
    DiscountPercent DECIMAL(5,2) NOT NULL,

    CONSTRAINT FK_SchemeSlab_Scheme
    FOREIGN KEY (SchemeID) REFERENCES dbo.Scheme(SchemeID)
);

-- CR/DR
SELECT 
    d.DistributorName,
    SUM(so.TotalAmount) AS TotalSales,
    ISNULL(SUM(p.AmountPaid),0) AS TotalPaid,
    SUM(so.TotalAmount) - ISNULL(SUM(p.AmountPaid),0) AS Outstanding
FROM dbo.Distributor d
LEFT JOIN dbo.SalesOrder so ON d.DistributorID = so.DistributorID
LEFT JOIN dbo.Payment p ON so.SalesOrderID = p.SalesOrderID
GROUP BY d.DistributorName;

ALTER TABLE dbo.Dispatch
ADD SalesOrderItemID INT NULL;

ALTER TABLE dbo.Dispatch
ADD CONSTRAINT FK_Dispatch_OrderItem
FOREIGN KEY (SalesOrderItemID)
REFERENCES dbo.SalesOrderItem(SalesOrderItemID);

CREATE TABLE dbo.PriceListHeader (
    PriceListID INT PRIMARY KEY,
    PriceListDate DATE NOT NULL,
    BranchID INT NOT NULL,
    Status NVARCHAR(30) NOT NULL,

    CONSTRAINT FK_PriceListHeader_Branch
    FOREIGN KEY (BranchID) REFERENCES dbo.Branch(BranchID)
);

CREATE TABLE dbo.ProductPriceHistory (
    PriceHistoryID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    EffectiveFromDate DATE NOT NULL,
    EffectiveToDate DATE NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    PriceListBranch NVARCHAR(50) NULL,

    CONSTRAINT FK_ProductPriceHistory_Product
    FOREIGN KEY (ProductID) REFERENCES dbo.Product(ProductID)
);
