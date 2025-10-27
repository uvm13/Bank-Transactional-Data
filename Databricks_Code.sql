-- Checking the table 
SELECT * 
FROM case_study.bank.sales
LIMIT 10;

-- The columsn indicate - Each record contains the:
-- •Date = The day on which the sales occurred
-- •Sales = Total Rand value of the sales that occurred
-- •Cost of Sales = Total Rand value of the cost of sales that occurred
-- •Quantity Sold = Total number of units that have been sold

-- 1. What is the daily sales price per unit?
SELECT
  Date,
  Sales / `Quantity Sold` AS SalesPricePerUnit
FROM case_study.bank.sales;

--------------------------------------------------------------------------------------------------------
-- 2. What is the average unit sales price of this product?
SELECT SUM(Sales) / SUM(`Quantity Sold`) AS AvgUnitSalesPrice
FROM case_study.bank.sales;

--------------------------------------------------------------------------------------------------------
-- 3. What is the daily % gross profit?
SELECT
  Date,
  (Sales - `Cost of Sales`) / Sales * 100 AS GrossProfitPct
FROM case_study.bank.sales;

--------------------------------------------------------------------------------------------------------
-- 4. What is the daily % gross profit per unit?

SELECT
  Date,
  (Sales - `Cost of Sales`) / `Quantity Sold` AS GrossProfitPerUnit,
  Sales / `Quantity Sold` AS SalesPricePerUnit,
  ((Sales - `Cost of Sales`) / `Quantity Sold`) / (Sales / `Quantity Sold`) * 100 AS GrossProfitPercentPerUnit
FROM case_study.bank.sales;

--------------------------------------------------------------------------------------------------------
-- 5. Pick any 3 periods during which this product was on promotion/special: What was the Price Elasticity of Demand during each of these periods? In your opinion, does this product perform better or worse when sold at a promotional price?

--Step 1: Identify Promotion Periods (Significant Price Drops) - You’d first need to calculate the daily sales price per unit and compare it to the previous day. In SQL, you can use window functions (if supported) to get the previous day’s price:
SELECT
    Date,
    Sales,
    `Quantity Sold`,
    Sales / `Quantity Sold` AS SalesPricePerUnit,
    LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) AS PrevDayPrice
FROM case_study.bank.sales;


-- Step 2: Find Days with Significant Price Drops - You can filter for days where the price drops by more than 1 Rand:
SELECT *,
       (Sales / `Quantity Sold`) - PrevDayPrice AS PriceDrop
FROM (
    SELECT
        Date,
        Sales,
        `Quantity Sold`,
        Sales / `Quantity Sold` AS SalesPricePerUnit,
        LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) AS PrevDayPrice
    FROM case_study.bank.sales
) t
WHERE ((Sales / `Quantity Sold`) - PrevDayPrice) < -1
ORDER BY PriceDrop ASC;

-- Step 3: Calculate Price Elasticity of Demand - For each promotion day, you’d compare the % change in price and quantity sold to the previous day:
SELECT
    Date,
    Sales / `Quantity Sold` AS SalesPricePerUnit,
    `Quantity Sold`,
    PrevDayPrice,
    PrevDayQty,
    ((Sales / `Quantity Sold`) - PrevDayPrice) / PrevDayPrice * 100 AS PctChangePrice,
    (`Quantity Sold` - PrevDayQty) / PrevDayQty * 100 AS PctChangeQty,
    CASE
        WHEN ((Sales / `Quantity Sold`) - PrevDayPrice) <> 0
        THEN ((`Quantity Sold` - PrevDayQty) / PrevDayQty * 100) /
             (((Sales / `Quantity Sold`) - PrevDayPrice) / PrevDayPrice * 100)
        ELSE NULL
    END AS Elasticity,
    (Sales / `Quantity Sold`) - PrevDayPrice AS PriceDrop
FROM (
    SELECT
        Date,
        Sales,
        `Quantity Sold`,
        Sales / `Quantity Sold` AS SalesPricePerUnit,
        LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) AS PrevDayPrice,
        LAG(`Quantity Sold`) OVER (ORDER BY Date) AS PrevDayQty
    FROM case_study.bank.sales
) t
WHERE ((Sales / `Quantity Sold`) - PrevDayPrice) < -1
ORDER BY PriceDrop ASC;


-- Interpretation: A negative elasticity means that as price decreases, quantity sold increases (which is expected).
-- The large negative values (e.g., -10.36, -53.35, -20.07) indicate that demand is highly elastic during these promotions: a small decrease in price leads to a large increase in quantity sold.

-- Step 4: Does the product perform better or worse during promotions?
-- Better: During promotions, the quantity sold increases dramatically, even for small price drops. This suggests that the product is very price-sensitive and performs much better (in terms of units sold) when on promotion.


--------------------------------------------------------------------------------------------------------------------------------------------
-- Combined Query:
SELECT
  Date,
  Sales,
  `Cost of Sales`,
  `Quantity Sold`,
  -- 1. Daily sales price per unit
  Sales / `Quantity Sold` AS SalesPricePerUnit,
  -- 3. Daily % gross profit
  (Sales - `Cost of Sales`) / Sales * 100 AS GrossProfitPct,
  -- 4. Daily gross profit per unit
  (Sales - `Cost of Sales`) / `Quantity Sold` AS GrossProfitPerUnit,
  -- 4. Daily % gross profit per unit
  ((Sales - `Cost of Sales`) / `Quantity Sold`) / (Sales / `Quantity Sold`) * 100 AS GrossProfitPercentPerUnit,
  -- 5. Previous day's price and quantity (for elasticity analysis)
  LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) AS PrevDayPrice,
  LAG(`Quantity Sold`) OVER (ORDER BY Date) AS PrevDayQty,
  -- 5. Price drop from previous day
  (Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) AS PriceDrop,
  -- 5. % change in price
  ((Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date)) / LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) * 100 AS PctChangePrice,
  -- 5. % change in quantity sold
  (`Quantity Sold` - LAG(`Quantity Sold`) OVER (ORDER BY Date)) / LAG(`Quantity Sold`) OVER (ORDER BY Date) * 100 AS PctChangeQty,
  -- 5. Price elasticity of demand
  CASE
    WHEN ((Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date)) <> 0
    THEN
      ((`Quantity Sold` - LAG(`Quantity Sold`) OVER (ORDER BY Date)) / LAG(`Quantity Sold`) OVER (ORDER BY Date) * 100) /
      (((Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date)) / LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) * 100)
    ELSE NULL
  END AS Elasticity
FROM case_study.bank.sales
ORDER BY Date;

----------
SELECT
  Date,
  Sales,
  `Cost of Sales`,
  `Quantity Sold`,
  Sales / `Quantity Sold` AS SalesPricePerUnit,
  SUM(Sales) / SUM(`Quantity Sold`) AS AvgUnitSalesPrice,
  (Sales - `Cost of Sales`) / Sales * 100 AS GrossProfitPct,
  (Sales - `Cost of Sales`) / `Quantity Sold` AS GrossProfitPerUnit,
  ((Sales - `Cost of Sales`) / `Quantity Sold`) / (Sales / `Quantity Sold`) * 100 AS GrossProfitPercentPerUnit,
  LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) AS PrevDayPrice,
  LAG(`Quantity Sold`) OVER (ORDER BY Date) AS PrevDayQty,
  (Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) AS PriceDrop,
  ((Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date)) / LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) * 100 AS PctChangePrice,
  (`Quantity Sold` - LAG(`Quantity Sold`) OVER (ORDER BY Date)) / LAG(`Quantity Sold`) OVER (ORDER BY Date) * 100 AS PctChangeQty,
  CASE
    WHEN ((Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date)) <> 0
    THEN
      ((`Quantity Sold` - LAG(`Quantity Sold`) OVER (ORDER BY Date)) / LAG(`Quantity Sold`) OVER (ORDER BY Date) * 100) /
      (((Sales / `Quantity Sold`) - LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date)) / LAG(Sales / `Quantity Sold`) OVER (ORDER BY Date) * 100)
    ELSE NULL
  END AS Elasticity
FROM case_study.bank.sales
GROUP BY
  Date,
  Sales,
  `Cost of Sales`,
  `Quantity Sold`
ORDER BY Date;
