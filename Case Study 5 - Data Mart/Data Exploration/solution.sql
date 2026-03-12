-- What day of the week is used for each week_date value?
SELECT DISTINCT 
  TO_CHAR(week_date, 'Day') AS day_of_week,
  EXTRACT(DOW FROM week_date) AS day_number
FROM data_mart.clean_weekly_sales
ORDER BY day_number;

-- What range of week numbers are missing from the dataset?
WITH all_weeks AS (
  SELECT generate_series(1, 52) AS week_number
)
SELECT 
  a.week_number AS missing_week_number
FROM all_weeks a
LEFT JOIN (
  SELECT DISTINCT week_number 
  FROM data_mart.clean_weekly_sales
) c ON a.week_number = c.week_number
WHERE c.week_number IS NULL
ORDER BY missing_week_number;

-- How many total transactions were there for each year in the dataset?
SELECT 
  calendar_year, 
  SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

-- What is the total sales for each region for each month?
SELECT 
  region, 
  month_number, 
  SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

-- What is the total count of transactions for each platform
SELECT 
  platform, 
  SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform;

-- What is the percentage of sales for Retail vs Shopify for each month?
WITH platform_sales AS (
  SELECT 
    platform, 
    SUM(sales) AS total_sales
  FROM data_mart.clean_weekly_sales
  GROUP BY platform
)
SELECT 
  platform, 
  total_sales,
  ROUND(100 * total_sales / SUM(total_sales) OVER(), 2) AS percentage
FROM platform_sales;

-- What is the percentage of sales by demographic for each year in the dataset?
SELECT
  calendar_year,
  demographic,
  SUM(sales) AS yearly_demographic_sales,
  ROUND(
    100 * SUM(sales) / 
    SUM(SUM(sales)) OVER (PARTITION BY calendar_year), 
    2
  ) AS percentage_contribution
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, demographic
ORDER BY calendar_year, percentage_contribution DESC;

-- Which age_band and demographic values contribute the most to Retail sales?
SELECT 
  age_band, 
  demographic, 
  SUM(sales) AS total_retail_sales,
  ROUND(
    100 * SUM(sales) / 
    SUM(SUM(sales)) OVER (), 
    2
  ) AS contribution_percentage
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_retail_sales DESC;

-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT 
  calendar_year, 
  platform, 
  SUM(sales) AS total_sales, 
  SUM(transactions) AS total_transactions,
  -- Calcul correct de la taille moyenne des transactions pour chaque année 
  ROUND(SUM(sales) / SUM(transactions), 2) AS avg_transaction_size
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;