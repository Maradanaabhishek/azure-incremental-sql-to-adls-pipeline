-- =====================================================
-- OnPremDW setup (cleaned from Vision Board scripts)
-- Run in SSMS. Heading lines that were not valid SQL are commented out.
-- Logic of the original scripts is unchanged.
-- =====================================================
CREATE DATABASE OnPremDW;
GO
USE OnPremDW;
GO

GO
-- ---------- DIM ----------
-- ==================Create Dimension Tables==========================================
-- 1..DimCustomer[dbo].[DimCustomer]

CREATE TABLE DimCustomer (
CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
CustomerID INT,
FirstName VARCHAR(50),
LastName VARCHAR(50),
Email VARCHAR(100),
City VARCHAR(50),
Country VARCHAR(50),
StartDate DATE,
EndDate DATE,
IsCurrent BIT
);

-- 2 DimProduct[dbo].[DimProduct]
CREATE TABLE DimProduct (
ProductKey INT IDENTITY(1,1) PRIMARY KEY,
ProductID INT,
ProductName VARCHAR(100),
Category VARCHAR(50),
Price DECIMAL(10,2)
);

-- 3 DimStore [dbo].[DimStore]
CREATE TABLE DimStore (
StoreKey INT IDENTITY(1,1) PRIMARY KEY,
StoreID INT,
StoreName VARCHAR(100),
City VARCHAR(50),
Region VARCHAR(50)
);

-- 4 DimEmployee[dbo].[DimEmployee]
CREATE TABLE DimEmployee (
EmployeeKey INT IDENTITY PRIMARY KEY,
EmployeeID INT,
EmployeeName VARCHAR(100),
Role VARCHAR(50),
StoreID INT
);

-- 5 DimPromotion [dbo].[DimPromotion]
CREATE TABLE DimPromotion (
PromotionKey INT IDENTITY PRIMARY KEY,
PromotionName VARCHAR(100),
DiscountPercent DECIMAL(5,2),
StartDate DATE,
EndDate DATE
)
-- 6  DimRegion [dbo].[DimRegion]
CREATE TABLE DimRegion (
RegionKey INT IDENTITY PRIMARY KEY,
RegionName VARCHAR(100),
Country VARCHAR(50)
);
-- 7 ) DimCategory [dbo].[DimCategory]
CREATE TABLE DimCategory (
CategoryKey INT IDENTITY PRIMARY KEY,
CategoryName VARCHAR(100)
);

-- 8)DimPaymentMethod [dbo].[DimPaymentMethod]
CREATE TABLE DimPaymentMethod (
PaymentMethodKey INT IDENTITY PRIMARY KEY,
PaymentMethodName VARCHAR(50)
);
-- 9 )
-- DimSupplier [dbo].[DimSupplier]
CREATE TABLE DimSupplier (
SupplierKey INT IDENTITY PRIMARY KEY,
SupplierID INT,
SupplierName VARCHAR(100),
City VARCHAR(50),
Country VARCHAR(50)
);
-- 10)DimDate[dbo].[DimDate]
CREATE TABLE DimDate (
DateKey INT PRIMARY KEY,
FullDate DATE,
Year INT,
Quarter INT,
Month INT,
Day INT
);



GO
-- ---------- FACT ----------
-- ===============Create Fact Tables===========================================

-- 1 FactSales [dbo].[FactSales]
CREATE TABLE FactSales (
SalesKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
CustomerKey INT,
ProductKey INT,
StoreKey INT,
Quantity INT,
SalesAmount DECIMAL(10,2),
DiscountAmount DECIMAL(10,2)
);
-- 2 FactOrders  [dbo].[FactOrders]
CREATE TABLE FactOrders (
OrderKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
CustomerKey INT,
StoreKey INT,
OrderAmount DECIMAL(10,2)
);
-- 3 FactPayments  [dbo].[FactPayments]
CREATE TABLE FactPayments (
PaymentKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
CustomerKey INT,
PaymentMethodKey INT,
Amount DECIMAL(10,2)
);
-- 4 FactInventory [dbo].[FactInventory]
CREATE TABLE FactInventory (
InventoryKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
ProductKey INT,
StoreKey INT,
StockLevel INT
);
-- 5 FactReturns [dbo].[FactReturns]
CREATE TABLE FactReturns (
ReturnKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
CustomerKey INT,
ProductKey INT,
ReturnAmount DECIMAL(10,2)
);
-- 6 FactShipment [dbo].[FactShipment]
CREATE TABLE FactShipment (
ShipmentKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
StoreKey INT,
SupplierKey INT,
ShipmentQuantity INT
);
-- 7 FactStoreSales [dbo].[FactStoreSales]
CREATE TABLE FactStoreSales (
StoreSalesKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
StoreKey INT,
TotalSales DECIMAL(10,2)
);
-- 8 FactCustomerActivity [dbo].[FactCustomerActivity]
CREATE TABLE FactCustomerActivity (
ActivityKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
CustomerKey INT,
ActivityType VARCHAR(50)
);
-- 9 FactProductPerformance [dbo].[FactProductPerformance]
CREATE TABLE FactProductPerformance (
PerformanceKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
ProductKey INT,
UnitsSold INT,
Revenue DECIMAL(10,2)
);
-- 10 FactDiscounts [dbo].[FactDiscounts]
CREATE TABLE FactDiscounts (
DiscountKey BIGINT IDENTITY PRIMARY KEY,
DateKey INT,
PromotionKey INT,
ProductKey INT,
DiscountAmount DECIMAL(10,2)
);


GO
-- ---------- WM ----------
CREATE TABLE dbo.ADF_Watermark_Table (
    TableSchema   VARCHAR(50)  NULL,
   TableName       VARCHAR(200) NULL,
   WatermarkColumn VARCHAR(100) NULL,
   LastLoadValue   BIGINT       NULL
);

INSERT INTO dbo.ADF_Watermark_Table (TableSchema, TableName, WatermarkColumn, LastLoadValue)
 VALUES
 -- Dimension Tables
 ('dbo','DimCustomer','CustomerKey',0),
 ('dbo','DimProduct','ProductKey',0),
 ('dbo','DimStore','StoreKey',0), 
('dbo','DimEmployee','EmployeeKey',0),
 ('dbo','DimPromotion','PromotionKey',0), 
('dbo','DimRegion','RegionKey',0),
 ('dbo','DimCategory','CategoryKey',0), 
('dbo','DimPaymentMethod','PaymentMethodKey',0), 
('dbo','DimSupplier','SupplierKey',0),
 ('dbo','DimDate','DateKey',0), 
-- Fact Tables
 ('dbo','FactSales','SalesKey',0), 
('dbo','FactOrders','OrderKey',0),
 ('dbo','FactPayments','PaymentKey',0), 
('dbo','FactInventory','InventoryKey',0),
 ('dbo','FactReturns','ReturnKey',0),
 ('dbo','FactShipment','ShipmentKey',0),
 ('dbo','FactStoreSales','StoreSalesKey',0),
 ('dbo','FactCustomerActivity','ActivityKey',0), ('dbo','FactProductPerformance','PerformanceKey',0),
 ('dbo','FactDiscounts','DiscountKey',0);

GO
-- ---------- SP ----------
CREATE OR ALTER PROCEDURE dbo.UpdateWatermark --(change name for Sp if required)--
    @TableSchema VARCHAR(50),
    @TableName VARCHAR(100),
    @WatermarkColumn VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @MaxValue BIGINT;

    -- Dynamic query to get max value------

    SET @SQL =
    'SELECT @MaxVal = MAX(' + QUOTENAME(@WatermarkColumn) + ')
     FROM ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName);

    EXEC sp_executesql
        @SQL,
        N'@MaxVal BIGINT OUTPUT',
        @MaxVal = @MaxValue OUTPUT;

    -- Handle NULL (empty table case)

    SET @MaxValue = ISNULL(@MaxValue, 0);

    -- UPSERT ----

    IF EXISTS (
        SELECT 1 
        FROM dbo.ADF_Watermark_Table
        WHERE TableName = @TableName
          AND TableSchema = @TableSchema
    )
    BEGIN
        UPDATE dbo.ADF_Watermark_Table
        SET LastLoadValue = @MaxValue
        WHERE TableName = @TableName
          AND TableSchema = @TableSchema;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.ADF_Watermark_Table
        (TableSchema, TableName, WatermarkColumn, LastLoadValue)
        VALUES
        (@TableSchema, @TableName, @WatermarkColumn, @MaxValue);
    END
END;

GO
-- ---------- POPULATE ----------
-- =====================================================================
-- =======================Populate DIM tables =======================
-- =====================================================================
-- 1. DimCustomer
INSERT INTO DimCustomer
(CustomerID, FirstName, LastName, Email, City, Country, StartDate, EndDate, IsCurrent)
SELECT TOP 10000
ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),
'First'+CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR),
'Last'+CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR),
'customer'+CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR)+'@mail.com',
'City'+CAST(ABS(CHECKSUM(NEWID()))%200 AS VARCHAR),
'INDIA',
DATEADD(YEAR,-ABS(CHECKSUM(NEWID()))%5,GETDATE()),
NULL,
1
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------
-- 2. DimProduct
INSERT INTO DimProduct
(ProductID, ProductName, Category, Price)
SELECT TOP 1000
ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),
'Product'+CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR),
CASE 
WHEN ROW_NUMBER() OVER(ORDER BY (SELECT NULL))%5=0 THEN 'Electronics'
WHEN ROW_NUMBER() OVER(ORDER BY (SELECT NULL))%5=1 THEN 'Clothing'
WHEN ROW_NUMBER() OVER(ORDER BY (SELECT NULL))%5=2 THEN 'Home'
WHEN ROW_NUMBER() OVER(ORDER BY (SELECT NULL))%5=3 THEN 'Sports'
ELSE 'Toys'
END,
ABS(CHECKSUM(NEWID()))%1000 + 10
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------
-- 3. DimStore
INSERT INTO DimStore
(StoreID, StoreName, City, Region)
SELECT TOP 50
ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),
'Store'+CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR),
'City'+CAST(ABS(CHECKSUM(NEWID()))%100 AS VARCHAR),
'Region'+CAST(ABS(CHECKSUM(NEWID()))%10 AS VARCHAR)
FROM sys.objects;
-------------------------------------------------------------------------------------
-- 4. DimEmployee
INSERT INTO DimEmployee
(EmployeeID, EmployeeName, Role, StoreID)
SELECT TOP 200
ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),
'Employee'+CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR),
'Sales',
ABS(CHECKSUM(NEWID()))%50 + 1
FROM sys.objects;
-------------------------------------------------------------------------------------

-- 5. DimPromotion
INSERT INTO DimPromotion
(PromotionName, DiscountPercent, StartDate, EndDate)
VALUES
('NewYearSale',10,'2024-01-01','2024-01-31'),
('FestivalSale',20,'2024-10-01','2024-10-31'),
('SummerSale',15,'2024-04-01','2024-04-30'),
('Clearance',30,'2024-12-01','2024-12-31');
-------------------------------------------------------------------------------------
-- 6. DIMregion
INSERT INTO DimRegion (RegionName, Country)
VALUES
('North','India'),
('South','India'),
('East','India'),
('West','India'),
('Central','India');
-------------------------------------------------------------------------------------
-- 7. DimCategory
INSERT INTO DimCategory (CategoryName)
VALUES ('Electronics'),('Clothing'),('Home'),('Sports'),('Toys');
-------------------------------------------------------------------------------------
-- 8. DimPaymentMethod
INSERT INTO DimPaymentMethod (PaymentMethodName)
VALUES
('Credit Card'),
('Debit Card'),
('Cash'),
('UPI'),
('Online');
-------------------------------------------------------------------------------------
-- 9. DimSupplier
INSERT INTO DimSupplier
(SupplierID, SupplierName, City, Country)
SELECT TOP 100
ROW_NUMBER() OVER(ORDER BY (SELECT NULL)),
'Supplier'+CAST(ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS VARCHAR),
'City'+CAST(ABS(CHECKSUM(NEWID()))%50 AS VARCHAR),
'USA'
FROM sys.objects;
-------------------------------------------------------------------------------------
-- 10. DimDate
DECLARE @StartDate DATE='2020-01-01'
DECLARE @EndDate DATE='2024-12-31'

WHILE @StartDate<=@EndDate
BEGIN

INSERT INTO DimDate
(DateKey, FullDate, Year, Quarter, Month, Day)
VALUES
(
CONVERT(INT,FORMAT(@StartDate,'yyyyMMdd')),
@StartDate,
YEAR(@StartDate),
DATEPART(QUARTER,@StartDate),
MONTH(@StartDate),
DAY(@StartDate)
)

SET @StartDate=DATEADD(DAY,1,@StartDate)

END
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- ==========     FACT TBLES ====================================================

-- 1.FactSales
INSERT INTO FactSales
(DateKey, CustomerKey, ProductKey, StoreKey, Quantity, SalesAmount, DiscountAmount)
SELECT TOP 500000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID()))%5000 + 1,
ABS(CHECKSUM(NEWID()))%1000 + 1,
ABS(CHECKSUM(NEWID()))%50 + 1,
ABS(CHECKSUM(NEWID()))%5 + 1,
ABS(CHECKSUM(NEWID()))%1000 + 50,
ABS(CHECKSUM(NEWID()))%100
FROM sys.objects a CROSS JOIN sys.objects b CROSS JOIN sys.objects c;
-------------------------------------------------------------------------------------
-- 2.FactOrders
INSERT INTO FactOrders
(DateKey, CustomerKey, StoreKey, OrderAmount)
SELECT TOP 300000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID()))%5000 + 1,
ABS(CHECKSUM(NEWID()))%50 + 1,
ABS(CHECKSUM(NEWID()))%1000 + 100
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------
-- 3.FactPayments
INSERT INTO FactPayments
(DateKey, CustomerKey, PaymentMethodKey, Amount)
SELECT TOP 200000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID()))%5000 + 1,
ABS(CHECKSUM(NEWID()))%5 + 1,
ABS(CHECKSUM(NEWID()))%2000
FROM sys.objects a CROSS JOIN sys.objects b;

-------------------------------------------------------------------------------------
-- 4.FactInventory
INSERT INTO FactInventory
(DateKey, ProductKey, StoreKey, StockLevel)
SELECT TOP 100000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID()))%1000 + 1,
ABS(CHECKSUM(NEWID()))%50 + 1,
ABS(CHECKSUM(NEWID()))%500
FROM sys.objects a CROSS JOIN sys.objects b;

-------------------------------------------------------------------------------------
-- 5.FactReturns
INSERT INTO FactReturns
(DateKey, CustomerKey, ProductKey, ReturnAmount)
SELECT TOP 50000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID()))%5000 + 1,
ABS(CHECKSUM(NEWID()))%1000 + 1,
ABS(CHECKSUM(NEWID()))%300
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------
-- 6.FactShipment
INSERT INTO FactShipment
(DateKey, StoreKey, SupplierKey, ShipmentQuantity)
SELECT TOP 150000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID()))%50 + 1,
ABS(CHECKSUM(NEWID()))%100 + 1,
ABS(CHECKSUM(NEWID()))%500
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------
-- 7.FactStoreSales
INSERT INTO FactStoreSales
(DateKey, StoreKey, TotalSales)
SELECT TOP 100000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID())) % 50 + 1,
ABS(CHECKSUM(NEWID())) % 5000 + 500
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------
-- 8..FactCustomerActivity
INSERT INTO FactCustomerActivity
(DateKey, CustomerKey, ActivityType)
SELECT TOP 100000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID())) % 5000 + 1,
CASE 
    WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN 'Login'
    WHEN ABS(CHECKSUM(NEWID())) % 3 = 1 THEN 'Purchase'
    ELSE 'Browse'
END
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------
-- 9.FactProductPerformance
INSERT INTO FactProductPerformance
(DateKey, ProductKey, UnitsSold, Revenue)

SELECT TOP 100000
d.DateKey,
ABS(CHECKSUM(NEWID())) % 1000 + 1,
ABS(CHECKSUM(NEWID())) % 50 + 1,
ABS(CHECKSUM(NEWID())) % 5000 + 100

FROM DimDate d
CROSS JOIN sys.objects a;
-------------------------------------------------------------------------------------
-- 10.FactDiscounts
INSERT INTO FactDiscounts
(DateKey, PromotionKey, ProductKey, DiscountAmount)
SELECT TOP 50000
(SELECT TOP 1 DateKey FROM DimDate ORDER BY NEWID()),
ABS(CHECKSUM(NEWID()))%4 + 1,
ABS(CHECKSUM(NEWID()))%1000 + 1,
ABS(CHECKSUM(NEWID()))%200
FROM sys.objects a CROSS JOIN sys.objects b;
-------------------------------------------------------------------------------------

GO
-- ---------- SANITY CHECK: row counts ----------
SELECT 'DimCustomer' AS TableName, COUNT(*) AS Cnt FROM DimCustomer UNION ALL
SELECT 'DimProduct', COUNT(*) FROM DimProduct UNION ALL
SELECT 'DimDate', COUNT(*) FROM DimDate UNION ALL
SELECT 'FactSales', COUNT(*) FROM FactSales UNION ALL
SELECT 'FactOrders', COUNT(*) FROM FactOrders UNION ALL
SELECT 'FactPayments', COUNT(*) FROM FactPayments UNION ALL
SELECT 'FactInventory', COUNT(*) FROM FactInventory UNION ALL
SELECT 'FactReturns', COUNT(*) FROM FactReturns UNION ALL
SELECT 'FactShipment', COUNT(*) FROM FactShipment UNION ALL
SELECT 'FactStoreSales', COUNT(*) FROM FactStoreSales UNION ALL
SELECT 'FactCustomerActivity', COUNT(*) FROM FactCustomerActivity UNION ALL
SELECT 'FactProductPerformance', COUNT(*) FROM FactProductPerformance UNION ALL
SELECT 'FactDiscounts', COUNT(*) FROM FactDiscounts;
SELECT * FROM dbo.ADF_Watermark_Table;
