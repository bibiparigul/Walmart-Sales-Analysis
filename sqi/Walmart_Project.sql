/*============================================================
 STEP 1
 Create a staging table.
 Everything is stored as text so SQL Server cannot fail.
============================================================*/

USE WalmartDB;
GO

DROP TABLE IF EXISTS Walmart_Stage;
GO

CREATE TABLE Walmart_Stage
(
    Store           VARCHAR(20),
    [Date]          VARCHAR(20),
    Weekly_Sales    VARCHAR(50),
    Holiday_Flag    VARCHAR(10),
    Temperature     VARCHAR(20),
    Fuel_Price      VARCHAR(20),
    CPI             VARCHAR(20),
    Unemployment    VARCHAR(20)
);
GO

/*============================================================
 STEP 2
 Import the CSV into the staging table
============================================================*/

BULK INSERT Walmart_Stage
FROM 'D:\project\walmart\Walmart_Sales.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0A',
    CODEPAGE = '65001'
);
GO

/*============================================================
 STEP 3
 View the first 10 rows of the imported data
============================================================*/

SELECT TOP (10) *
FROM Walmart_Stage;
GO

/*============================================================
  STEP 4.1
  DATASET OVERVIEW

  Purpose:
  Display the total number of records currently loaded
  into the staging table.
=============================================================*/

SELECT
    COUNT(*) AS Total_Records
FROM Walmart_Stage;

/*============================================================
  STEP 4.2
  PREVIEW DATA

  Purpose:
  Display the first 10 records to verify that
  the dataset imported correctly.
=============================================================*/

SELECT TOP (10) *
FROM Walmart_Stage;

/*============================================================
  STEP 4.3
  COLUMN INFORMATION

  Purpose:
  Display the table schema, data types,
  and column definitions.
=============================================================*/

EXEC sp_help 'Walmart_Stage';

/*============================================================
  STEP 4.4
  CHECK FOR MISSING VALUES

  Purpose:
  Count the number of NULL or empty values
  in each column.
=============================================================*/

SELECT
    SUM(CASE WHEN Store IS NULL OR Store = '' THEN 1 ELSE 0 END) AS Missing_Store,

    SUM(CASE WHEN [Date] IS NULL OR [Date] = '' THEN 1 ELSE 0 END) AS Missing_Date,

    SUM(CASE WHEN Weekly_Sales IS NULL OR Weekly_Sales = '' THEN 1 ELSE 0 END) AS Missing_Weekly_Sales,

    SUM(CASE WHEN Holiday_Flag IS NULL OR Holiday_Flag = '' THEN 1 ELSE 0 END) AS Missing_Holiday_Flag,

    SUM(CASE WHEN Temperature IS NULL OR Temperature = '' THEN 1 ELSE 0 END) AS Missing_Temperature,

    SUM(CASE WHEN Fuel_Price IS NULL OR Fuel_Price = '' THEN 1 ELSE 0 END) AS Missing_Fuel_Price,

    SUM(CASE WHEN CPI IS NULL OR CPI = '' THEN 1 ELSE 0 END) AS Missing_CPI,

    SUM(CASE WHEN Unemployment IS NULL OR Unemployment = '' THEN 1 ELSE 0 END) AS Missing_Unemployment
FROM Walmart_Stage;



/*============================================================
  STEP 4.5
  CHECK FOR DUPLICATE RECORDS

  Purpose:
  Identify duplicate rows based on all columns.
=============================================================*/

SELECT
    Store,
    [Date],
    Weekly_Sales,
    Holiday_Flag,
    Temperature,
    Fuel_Price,
    CPI,
    Unemployment,
    COUNT(*) AS Duplicate_Count
FROM Walmart_Stage
GROUP BY
    Store,
    [Date],
    Weekly_Sales,
    Holiday_Flag,
    Temperature,
    Fuel_Price,
    CPI,
    Unemployment
HAVING COUNT(*) > 1;

/*============================================================
  STEP 4.6
  DATE FORMAT VALIDATION

  Purpose:
  Preview the original date values and test
  conversion into SQL Server DATE format.
=============================================================*/

SELECT TOP (20)
    [Date] AS Original_Date,
    TRY_CONVERT(date, [Date], 103) AS Converted_Date
FROM Walmart_Stage;

/*============================================================
  STEP 4.7
  VALIDATE NUMERIC COLUMNS

  Purpose:
  Ensure all numeric columns contain
  valid numeric values.
=============================================================*/

SELECT
    SUM(CASE WHEN TRY_CONVERT(decimal(18,2), Weekly_Sales) IS NULL THEN 1 ELSE 0 END) AS Invalid_WeeklySales,

    SUM(CASE WHEN TRY_CONVERT(float, Temperature) IS NULL THEN 1 ELSE 0 END) AS Invalid_Temperature,

    SUM(CASE WHEN TRY_CONVERT(float, Fuel_Price) IS NULL THEN 1 ELSE 0 END) AS Invalid_FuelPrice,

    SUM(CASE WHEN TRY_CONVERT(float, CPI) IS NULL THEN 1 ELSE 0 END) AS Invalid_CPI,

    SUM(CASE WHEN TRY_CONVERT(float, Unemployment) IS NULL THEN 1 ELSE 0 END) AS Invalid_Unemployment
FROM Walmart_Stage;

/*============================================================
  STEP 4.8
  VALIDATE HOLIDAY FLAG

  Purpose:
  Verify that Holiday_Flag only
  contains valid values (0 or 1).
=============================================================*/

SELECT DISTINCT Holiday_Flag
FROM Walmart_Stage;

--==========================================================
-- STEP 5
-- Create the cleaned table
--==========================================================

DROP TABLE IF EXISTS Walmart_Clean;
GO

CREATE TABLE Walmart_Clean
(
    Store INT,
    [Date] DATE,
    Weekly_Sales FLOAT,
    Holiday_Flag BIT,
    Temperature FLOAT,
    Fuel_Price FLOAT,
    CPI FLOAT,
    Unemployment FLOAT
);
GO

--==========================================================
-- STEP 5.2
-- Load Clean Data into the Final Analysis Table
--==========================================================
INSERT INTO Walmart_Clean
(Store,[Date],Weekly_Sales,Holiday_Flag,Temperature,Fuel_Price,CPI,Unemployment)
SELECT
CAST(Store AS INT),
TRY_CONVERT(DATE,[Date],103),
CAST(Weekly_Sales AS FLOAT),
CAST(Holiday_Flag AS BIT),
CAST(Temperature AS FLOAT),
CAST(Fuel_Price AS FLOAT),
CAST(CPI AS FLOAT),
CAST(LTRIM(RTRIM(REPLACE(Unemployment,CHAR(13),''))) AS FLOAT)
FROM Walmart_Stage;
GO

SELECT COUNT(*) AS Total_Records
FROM Walmart_Clean;
GO

SELECT TOP 10 *
FROM Walmart_Clean;
GO


--=========================================================
-- STEP 6.1
-- Dataset Overview
--=========================================================

SELECT
COUNT(*) AS Total_Records,
COUNT(DISTINCT Store) AS Total_Stores,
MIN(Date) AS Start_Date,
MAX(Date) AS End_Date,
SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales,
MAX(Weekly_Sales) AS Highest_Weekly_Sale,
MIN(Weekly_Sales) AS Lowest_Weekly_Sale
FROM Walmart_Clean;
GO

--=========================================================
-- STEP 6.2
-- Number of Records per Store
--=========================================================

SELECT
Store,
COUNT(*) AS Total_Records
FROM Walmart_Clean
GROUP BY Store
ORDER BY Store;
GO

--=========================================================
-- STEP 6.3
-- Weekly Sales Statistics
--=========================================================

SELECT
AVG(Weekly_Sales) AS Average_Sales,
MIN(Weekly_Sales) AS Minimum_Sales,
MAX(Weekly_Sales) AS Maximum_Sales,
STDEV(Weekly_Sales) AS Standard_Deviation
FROM Walmart_Clean;
GO

--=========================================================
-- STEP 6.4
-- Holiday Distribution
--=========================================================

SELECT
Holiday_Flag,
COUNT(*) AS Total_Weeks
FROM Walmart_Clean
GROUP BY Holiday_Flag;
GO

--=========================================================
-- STEP 7.1
-- Top 10 Stores by Total Sales
--=========================================================

SELECT TOP 10
Store,
SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales,
MIN(Weekly_Sales) AS Lowest_Weekly_Sale,
MAX(Weekly_Sales) AS Highest_Weekly_Sale
FROM Walmart_Clean
GROUP BY Store
ORDER BY Total_Sales DESC;
GO

-- Top 10 Stores
SELECT TOP 10
    Store,
    SUM(Weekly_Sales) AS TotalSales
FROM Walmart_Clean
GROUP BY Store
ORDER BY TotalSales DESC;

--=========================================================
-- STEP 7.2
-- Bottom 10 Stores by Total Sales
--=========================================================

SELECT TOP 10
Store,
SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales,
MIN(Weekly_Sales) AS Lowest_Weekly_Sale,
MAX(Weekly_Sales) AS Highest_Weekly_Sale
FROM Walmart_Clean
GROUP BY Store
ORDER BY Total_Sales ASC;
GO

-- Bottom 10 Stores
SELECT TOP 10
    Store,
    SUM(Weekly_Sales) AS TotalSales
FROM Walmart_Clean
GROUP BY Store
ORDER BY TotalSales ASC;
--=========================================================
-- STEP 7.3
-- Complete Store Performance Ranking
--=========================================================

SELECT
Store,
SUM(Weekly_Sales) AS Total_Sales,
RANK() OVER (ORDER BY SUM(Weekly_Sales) DESC) AS Sales_Rank
FROM Walmart_Clean
GROUP BY Store
ORDER BY Sales_Rank;
GO

--=========================================================
-- STEP 7.4
-- Store Contribution to Total Sales
--=========================================================

SELECT
Store,
SUM(Weekly_Sales) AS Total_Sales,
ROUND(
100.0 * SUM(Weekly_Sales) /
(SUM(SUM(Weekly_Sales)) OVER()),
2) AS Sales_Percentage
FROM Walmart_Clean
GROUP BY Store
ORDER BY Total_Sales DESC;
GO


--=========================================================
-- STEP 8.1
-- Holiday vs Non-Holiday Sales
--=========================================================

SELECT
Holiday_Flag,
COUNT(*) AS Total_Weeks,
SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales,
MIN(Weekly_Sales) AS Lowest_Sale,
MAX(Weekly_Sales) AS Highest_Sale
FROM Walmart_Clean
GROUP BY Holiday_Flag;
GO

--=========================================================
-- STEP 8.2
-- Holiday Sales by Store
--=========================================================
SELECT
Store,
Holiday_Flag,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM Walmart_Clean
GROUP BY Store, Holiday_Flag
ORDER BY Store, Holiday_Flag;
GO

--=========================================================
-- STEP 8.3
-- Temperature and Weekly Sales
--=========================================================

SELECT
Temperature,
Weekly_Sales
FROM Walmart_Clean
ORDER BY Temperature;
GO

--=========================================================
-- STEP 8.4
-- Fuel Price and Weekly Sales
--=========================================================

SELECT
Fuel_Price,
Weekly_Sales
FROM Walmart_Clean
ORDER BY Fuel_Price;
GO

--=========================================================
-- STEP 8.5
-- CPI and Weekly Sales
--=========================================================

SELECT
CPI,
Weekly_Sales
FROM Walmart_Clean
ORDER BY CPI;
GO

--=========================================================
-- STEP 8.6
-- Unemployment and Weekly Sales
--=========================================================

SELECT
Unemployment,
Weekly_Sales
FROM Walmart_Clean
ORDER BY Unemployment;
GO

--=========================================================
-- STEP 9.1
-- Total Sales by Year
--=========================================================

SELECT
YEAR(Date) AS Sales_Year,
SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM Walmart_Clean
GROUP BY YEAR(Date)
ORDER BY Sales_Year;
GO


--=========================================================
-- STEP 9.2
-- Monthly Sales Trend
--=========================================================

SELECT
MONTH(Date) AS Sales_Month,
DATENAME(MONTH, Date) AS Month_Name,
SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM Walmart_Clean
GROUP BY
MONTH(Date),
DATENAME(MONTH, Date)
ORDER BY Sales_Month;
GO

--=========================================================
-- STEP 9.3
-- Quarterly Sales
--=========================================================

SELECT
DATEPART(QUARTER, Date) AS Quarter,
SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM Walmart_Clean
GROUP BY DATEPART(QUARTER, Date)
ORDER BY Quarter;
GO


--=========================================================
-- STEP 9.4
-- Monthly Sales by Year
--=========================================================

SELECT
YEAR(Date) AS Sales_Year,
MONTH(Date) AS Sales_Month,
DATENAME(MONTH, Date) AS Month_Name,
SUM(Weekly_Sales) AS Total_Sales
FROM Walmart_Clean
GROUP BY
YEAR(Date),
MONTH(Date),
DATENAME(MONTH, Date)
ORDER BY
Sales_Year,
Sales_Month;
GO

--=========================================================
-- STEP 9.5
-- Best and Worst Sales Weeks
--=========================================================

SELECT TOP 10
Date,
SUM(Weekly_Sales) AS Total_Weekly_Sales
FROM Walmart_Clean
GROUP BY Date
ORDER BY Total_Weekly_Sales DESC;
GO

SELECT TOP 10
Date,
SUM(Weekly_Sales) AS Total_Weekly_Sales
FROM Walmart_Clean
GROUP BY Date
ORDER BY Total_Weekly_Sales ASC;
GO