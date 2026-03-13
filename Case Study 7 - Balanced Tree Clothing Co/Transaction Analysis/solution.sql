-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS total_unique_transactions
FROM balanced_tree.sales;


-- 2. What is the average unique products purchased in each transaction?
WITH txn_products AS (
  SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_products
  FROM balanced_tree.sales
  GROUP BY txn_id
)
SELECT ROUND(AVG(unique_products), 2) AS avg_unique_products_per_transaction
FROM txn_products;


-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH txn_revenue AS (
  SELECT txn_id, SUM((qty * price) * (1 - discount / 100)) AS revenue_after_discount
  FROM balanced_tree.sales
  GROUP BY txn_id
)
SELECT 
  percentile_cont(0.25) WITHIN GROUP (ORDER BY revenue_after_discount) AS p25,
  percentile_cont(0.5)  WITHIN GROUP (ORDER BY revenue_after_discount) AS p50,
  percentile_cont(0.75) WITHIN GROUP (ORDER BY revenue_after_discount) AS p75
FROM txn_revenue;



-- 4. What is the average discount value per transaction?
WITH txn_discount AS (
  SELECT txn_id, SUM(qty * price * discount / 100) AS total_discount
  FROM balanced_tree.sales
  GROUP BY txn_id
)
SELECT ROUND(AVG(total_discount), 2) AS avg_total_discount_per_transaction
FROM txn_discount;


-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT 
    member,
    COUNT(DISTINCT txn_id) AS txn_count,
    ROUND(100.0 * COUNT(DISTINCT txn_id) / SUM(COUNT(DISTINCT txn_id)) OVER(), 2) AS percentage
FROM balanced_tree.sales
GROUP BY member;


-- 6. What is the average revenue for member transactions and non-member transactions?
WITH txn_revenue AS (
    SELECT 
        member,
        txn_id,
        SUM((qty * price) * (1 - discount / 100)) AS revenue_after_discount
    FROM balanced_tree.sales
    GROUP BY member, txn_id
)
SELECT 
    member,
    ROUND(AVG(revenue_after_discount), 2) AS avg_revenue
FROM txn_revenue
GROUP BY member;
