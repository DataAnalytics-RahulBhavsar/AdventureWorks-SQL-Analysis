-- AdventureWorks SQL Portfolio
-- Author: Rahul Bhavsar
-- Total Queries: 18
-- Sections:
    -- 1. Sales Analysis
    -- 2. Customer Analysis
    -- 3. Product Analysis
    -- 4. Territory Analysis
    -- 5. Advance SQL

-- SECTION 1 : Sales & Revenue Analysis 

-- 1]Total Revanue by Year (With Grand Total using ROLLUP)
SELECT  
    ISNULL(CAST(D.CalendarYear AS varchar), 'Grand_Total') AS Calander_Year, 
    CAST(SUM(F.SalesAmount) AS Int) AS Total_Sales 
FROM FactInternetSales AS F 
JOIN DimDate AS D 
    ON F. OrderDateKey = D. DateKey
GROUP BY ROLLUP (D.CalendarYear)  
ORDER BY D.CalendarYear DESC 

--2] Monthly Revanue 
SELECT 
    D.EnglishMonthName AS Months,
    CAST(SUM(F.SalesAmount) AS int) AS Total_Sales
FROM FactInternetSales AS F JOIN DimDate AS D 
ON F.OrderDateKey = D.DateKey
GROUP BY D.EnglishMonthName,
         D.MonthNumberOfYear
ORDER BY D.MonthNumberOfYear ASC 

-- 3] Top 10 Products by Revanue And profit (Used Top and Cast)
SELECT TOP 10 
    D.EnglishProductName,
    CAST(SUM(F.SalesAmount)AS int) AS Total_Revanue,
    CAST(SUM(F.SalesAmount - F.TotalProductCost) AS int) AS Total_Profit
FROM FactInternetSales AS F 
JOIN DimProduct AS D
ON F.ProductKey = D.ProductKey 
GROUP BY D. EnglishProductName
ORDER BY Total_Revanue DESC

SELECT * FROM FactInternetSales

-- 4] Revanue by Product Category (% Contribution)
SELECT 
    C.EnglishProductCategoryName AS Category,
    CAST(SUM(F.SalesAmount) AS INT) AS Total_Revenue,
    CAST(SUM(F.SalesAmount) * 100.0/ SUM(SUM(F.SalesAmount)) OVER()
    AS DECIMAL(10,2)) AS Revenue_Percentage
FROM FactInternetSales F
JOIN DimProduct P ON F.ProductKey = P.ProductKey
JOIN DimProductSubcategory S ON P.ProductSubcategoryKey = S.ProductSubcategoryKey
JOIN DimProductCategory C ON S.ProductCategoryKey = C.ProductCategoryKey
GROUP BY C.EnglishProductCategoryName
ORDER BY Total_Revenue DESC;

-- 5] Products Total_Sales with it's Rank (Used Dense_Rank())
SELECT D.EnglishProductName,
       SUM(F.SalesAmount) AS Total_Sales,
       DENSE_RANK() OVER (ORDER BY SUM(F.SalesAmount) DESC) AS Sales_Rank
FROM FactInternetSales AS F
JOIN DimProduct AS D
ON F.ProductKey = D.ProductKey
GROUP BY D.EnglishProductName
ORDER BY Total_Sales DESC;


-- SECTION 2 Customer Analysis

-- 1] Top 10 Customer by lifetime Revanue (Used CONCAT)
SELECT TOP 10 
    CONCAT(D.FirstName,SPACE(1),D.LastName) AS Customer ,
    SUM(F.SalesAmount) AS Total_Sales 
FROM FactInternetSales AS F 
JOIN DimCustomer AS D
ON F.CustomerKey = D. CustomerKey
GROUP BY CONCAT(D.FirstName,SPACE(1),D. LastName)
ORDER BY Total_Sales DESC

-- 2] Repeat Customer (Used DISTINCT)
SELECT 
    D.CustomerKey, 
    D.FirstName,
    COUNT(DISTINCT F.SalesOrderNumber) AS Order_Count
FROM FactInternetSales F
JOIN DimCustomer D
ON F.CustomerKey = D.CustomerKey
GROUP BY D.CustomerKey, D.FirstName
ORDER BY Order_Count DESC

-- 3] Top 10 Average Order Value 
SELECT TOP 10 
    SalesOrderNumber, 
    AVG(SalesAmount) AS Average_Sales 
FROM FactInternetSales
GROUP BY SalesOrderNumber
ORDER BY Average_Sales DESC

-- 4] Inactive Customers from (last 12 months) (Used DATEADD and GETDATE())
SELECT 
    Dc.CustomerKey,
    Dc.FirstName,
    Dc.LastName,
    MAX(D.FullDateAlternateKey) AS Last_Purchase_Date
FROM FactInternetSales AS F JOIN DimDate AS D
ON F.OrderDateKey = D.DateKey
JOIN DimCustomer AS Dc
ON F.CustomerKey = Dc.CustomerKey
GROUP BY Dc.CustomerKey, Dc.FirstName, Dc.LastName
HAVING MAX(D.FullDateAlternateKey) < DATEADD(MONTH, -12, GETDATE());

-- 5] Customer Spending Above Average (Subquery)
SELECT 
    C.FirstName,
    C.LastName,
    SUM(F.SalesAmount) AS Total_Purchase
FROM FactInternetSales AS F
JOIN DimCustomer AS C
    ON F.CustomerKey = C.CustomerKey
GROUP BY C.FirstName, C.LastName
HAVING SUM(F.SalesAmount) >
(SELECT AVG(Customer_Total) FROM(
        SELECT SUM(SalesAmount) AS Customer_Total
        FROM FactInternetSales
        GROUP BY CustomerKey
    ) AS AvgTable
)
ORDER BY Total_Purchase DESC;

-- SECTION 3 - Product & Profit Aanalysis 

-- 1] Profit per product 
SELECT 
    D.ProductKey, 
    D.EnglishProductName,
    SUM(F.SalesAmount) AS Total_Sales,
    SUM(F.TotalProductCost) AS Total_Cost,
    SUM(F.SalesAmount - F.TotalProductCost) AS Profit_Value,
    CAST((SUM(F.SalesAmount - F.TotalProductCost) * 100.0) 
        / NULLIF(SUM(F.SalesAmount), 0) AS DECIMAL(10,2)) AS Profit_Margin_Percentage
FROM FactInternetSales AS F
JOIN DimProduct AS D
    ON F.ProductKey = D.ProductKey
GROUP BY D.ProductKey, D.EnglishProductName
ORDER BY Profit_Value DESC;


-- 2] Product With Zero Sales (Left Join)
SELECT 
    D.ProductKey, 
    D.EnglishProductName
FROM DimProduct AS D
LEFT JOIN FactInternetSales AS F
    ON D.ProductKey = F.ProductKey
WHERE F.ProductKey IS NULL;
 

 -- 3] Most Frequently Purchased Product (Used COUNT and DISTINCT)
 SELECT 
       D.EnglishProductName, 
       COUNT(DISTINCT F.SalesOrderNumber) AS Count_of_Orders
 FROM FactInternetSales AS F 
 JOIN DimProduct AS D
 ON F.ProductKey = D.ProductKey
 GROUP BY D.EnglishProductName
 ORDER BY Count_of_Orders DESC 

 -- SECTION 4: Territory Analysis 

-- 1] Revanue by Territory
SELECT 
    Dt.SalesTerritoryRegion, 
    SUM(F.SalesAmount) AS Total_Sales
FROM FactInternetSales AS F JOIN 
DimSalesTerritory AS Dt 
ON F.SalesTerritoryKey = Dt. SalesTerritoryKey
GROUP BY Dt.SalesTerritoryRegion 

-- 2] Territory wise Annual Growth
SELECT 
    D.CalendarYear, 
    Dt.SalesTerritoryRegion, 
    SUM(F.SalesAmount) AS Total_Sales 
FROM FactInternetSales AS F JOIN DimDate AS D
ON F.OrderDateKey = D.DateKey
JOIN DimSalesTerritory AS Dt
ON F.SalesTerritoryKey = Dt.SalesTerritoryKey
GROUP BY D.CalendarYear ,Dt.SalesTerritoryRegion
ORDER BY D.CalendarYear DESC

-- SECTION 5 : Advance SQL 

-- 1] Top Product in Each Category (Used CTE, RANK() and PARTITION BY)
WITH ProductSales
AS (
SELECT 
    Dc.EnglishProductCategoryName, 
    D.EnglishProductName, 
    CAST(SUM(F.SalesAmount) AS int) AS Total_Sales,
    RANK() OVER(PARTITION BY Dc.englishproductcategoryName Order by SUM(F.SalesAmount) DESC) AS [Rank]
FROM FactInternetSales AS F JOIN DimProduct AS D 
ON F.ProductKey = D.ProductKey JOIN DimProductSubcategory AS Ds
ON D.ProductSubcategoryKey = Ds.ProductSubcategoryKey JOIN DimProductCategory AS Dc
ON Ds.ProductCategoryKey = Dc.ProductCategoryKey 
GROUP BY Dc.EnglishProductCategoryName, D.EnglishProductName
) SELECT * FROM ProductSales 
WHERE [Rank] = 1

-- 2] Revanue by Customer Gender 
SELECT 
    D.Gender, 
    CAST(SUM(F.SalesAmount) AS int) AS Total_Sales 
FROM FactInternetSales AS F JOIN DimCustomer AS D
ON F.CustomerKey = D.CustomerKey
GROUP BY D.Gender


-- 3] Top Products in each department 
WITH ProductSales AS
(
SELECT 
    Dc.EnglishProductCategoryName,
    D.EnglishProductName,
    SUM(F.SalesAmount) AS Total_Sales,
ROW_NUMBER() OVER(
PARTITION BY Dc.EnglishProductCategoryName
ORDER BY SUM(F.SalesAmount) DESC) AS Rank_Product
FROM FactInternetSales AS F
JOIN DimProduct AS D
ON F.ProductKey = D.ProductKey
JOIN DimProductSubcategory AS Ds ON D.ProductSubcategoryKey = Ds.ProductSubcategoryKey
JOIN DimProductCategory AS Dc ON Ds.ProductCategoryKey = Dc.ProductCategoryKey
GROUP BY 
    Dc.EnglishProductCategoryName,
    D.EnglishProductName
)
SELECT 
    EnglishProductCategoryName,
    EnglishProductName,
    Total_Sales
FROM ProductSales
WHERE Rank_Product = 1
ORDER BY Total_Sales DESC


