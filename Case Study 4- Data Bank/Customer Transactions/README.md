### 1.What is the unique count and total amount for each transaction type?

Pour avoir le nombre unique et le montant total pour chaque type de transaction. On groupe par ``txn_type`` (deposit, withdrawal, purchase). On compte le nombre de transactions, et on somme les montants avec ``SUM()``
```sql
SELECT 
    txn_type, 
    COUNT(*) AS unique_count, 
    SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
GROUP BY txn_type;
```

### 2.What is the average total historical deposit counts and amounts for all customers?

- CTE ``customer_deposits``: On calcule d'abord, pour chaque client, le nombre total de ses dépôts et la moyenne des montant déposée (en filtrant ``txn_type = 'deposit'``) 
- Ensuite, on calcule la moyenne de ces deux indicateurs sur l'ensemble des clients. ``ROUND()`` permet d'arrondir.

```sql
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
```

### 3.For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

- CTE ``monthly_activity``: On regroupe les données par client et par mois. On utilise des ``SUM(CASE WHEN ...)`` pour compter conditionnellement le nombre de dépôts, achats et retraits pour chaque client chaque mois
- on filtre ces résultats pour ne garder que les clients qui, pour un mois donné, ont plus d'un dépôt (``nb_depots > 1``) **ET** (au moins un achat **OU** au moins un retrait)

```sql
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
```

### 4.What is the closing balance for each customer at the end of the month?

Pour avoir le solde de clôture pour chaque client à la fin de chaque mois:
- CTE `monthly_balances`: On calcule d'abord la variation nette du solde pour chaque client et chaque mois. La somme conditionnelle ``SUM()`` transforme les dépôts en positif et les achats/retraits en négatif pour obtenir la variation
- on utilise une fonction de fenêtrage ``SUM(...) OVER (PARTITION BY ... ORDER BY ...)`` pour calculer le solde cumulé de chaque client mois après mois.``ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`` indique de cumuler depuis le premier mois jusqu'au mois courant
```sql
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
```

### 5.What is the percentage of customers who increase their closing balance by more than 5%?

Pour avoir le pourcentage de clients qui augmentent leur solde de clôture de plus de 5 %:
