-- What is the unique count and total amount for each transaction type?
SELECT 
    txn_type, 
    COUNT(*) AS unique_count, 
    SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
GROUP BY txn_type;

-- What is the average total historical deposit counts and amounts for all customers?
WITH customer_deposits AS (
    SELECT 
        customer_id, 
        COUNT(*) AS deposit_count, 
        AVG(txn_amount) AS avg_deposit_amount
    FROM data_bank.customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(deposit_count)) AS avg_total_deposits,
    ROUND(AVG(avg_deposit_amount), 2) AS avg_amount
FROM customer_deposits;

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH monthly_activity AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', txn_date) AS txn_month,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM data_bank.customer_transactions
    GROUP BY customer_id, txn_month
)
SELECT 
    txn_month,
    COUNT(customer_id) AS customer_count
FROM monthly_activity
WHERE deposit_count > 1 
  AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY txn_month
ORDER BY txn_month;

-- What is the closing balance for each customer at the end of the month?
WITH monthly_balances  AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', txn_date)::DATE AS txn_month,
        SUM(CASE
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS net_change
    FROM data_bank.customer_transactions
    GROUP BY customer_id, txn_month
)
SELECT 
    customer_id,
    txn_month,
    SUM(net_change) OVER (
        PARTITION BY customer_id 
        ORDER BY txn_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS closing_balance
FROM monthly_balances 
ORDER BY customer_id, txn_month;

-- What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_balances  AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', txn_date)::DATE AS txn_month,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS net_change
    FROM data_bank.customer_transactions
    GROUP BY customer_id, txn_month
),
monthly_closing_balances AS (
    SELECT 
    customer_id,
    txn_month,
    SUM(net_change) OVER ( PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance,
    MIN(txn_month) OVER (PARTITION BY customer_id) AS first_month,
    MAX(txn_month) OVER (PARTITION BY customer_id) AS last_month
FROM monthly_balances 
ORDER BY customer_id, txn_month
),
first_last_balance AS (
    SELECT
        customer_id,
        MAX(CASE WHEN txn_month = first_month THEN closing_balance END) AS initial_balance,
        MAX(CASE WHEN txn_month = last_month THEN closing_balance END) AS final_balance
    FROM monthly_closing_balances
    GROUP BY customer_id
    HAVING MIN(txn_month) != MAX(txn_month) 
)
SELECT 
    ROUND(
        100.0 * COUNT(CASE 
            WHEN final_balance > initial_balance * 1.05 AND initial_balance > 0 
            THEN 1 
        END) / COUNT(*), 
    2) AS customers_5pct
FROM first_last_balance;