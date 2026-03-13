### 1. How many unique transactions were there?
```sql
SELECT COUNT(DISTINCT txn_id) AS total_unique_transactions
FROM balanced_tree.sales;
```

### 2. What is the average unique products purchased in each transaction?
On compte les produits distincts par ``txn_id``, puis on fait la moyenne ``AVG()``
```sql
WITH txn_products AS (
  SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_products
  FROM balanced_tree.sales
  GROUP BY txn_id
)
SELECT ROUND(AVG(unique_products), 2) AS avg_unique_products_per_transaction
FROM txn_products;
```

### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
On calcule d'abord le revenu total après remise pour chaque transaction. Ensuite, on utilise la fonction de fenêtrage ``PERCENTILE_CONT`` pour trouver les percentiles.
```sql
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

```

### 4. What is the average discount value per transaction?
On calcule la somme des remises par ``txn_id``, puis on fait la moyenne ``AVG()``
```sql
WITH txn_discount AS (
  SELECT txn_id, SUM(qty * price * discount / 100) AS total_discount
  FROM balanced_tree.sales
  GROUP BY txn_id
)
SELECT ROUND(AVG(total_discount), 2) AS avg_total_discount_per_transaction
FROM txn_discount;
```

### 5. What is the percentage split of all transactions for members vs non-members?
- On compte le nombre unique de transactions
- On groupe par ``member`` (colonne booléenne)
- On calcule le pourcentage de transaction par groupe de ``member``. `SUM(...) OVER()` permet à avoir la somme totale de toutes les transactions
```sql
SELECT 
    member,
    COUNT(DISTINCT txn_id) AS txn_count,
    ROUND(100.0 * COUNT(DISTINCT txn_id) / SUM(COUNT(DISTINCT txn_id)) OVER(), 2) AS percentage
FROM balanced_tree.sales
GROUP BY member;
```

### 6. What is the average revenue for member transactions and non-member transactions?
- On calcule le total des revenues après remise pour chaque transaction et par groupe de membre
- On calcule la moyenne de ces revenu par groupe de membre
```sql
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
```