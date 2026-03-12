## Problem
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer

Using all of the data available - how much data would have been required for each option on a monthly basis?


## Understanding the problem
Data Bank veut allouer de l'espace de stockage de données à ses clients selon 3 options différentes :
- Option 1 : Basée sur le solde de fin de mois précédent
- Option 2 : Basée sur la moyenne des 30 derniers jours
- Option 3 : Mise à jour en temps réel

**Objectif** : Calculer pour chaque mois, pour chaque option, le volume total de données à provisionner.

### 1. Préparation des éléments de base

#### a. Solde courant après chaque transaction
- On crée une table temporaire pour réutiliser ces données
```sql
CREATE TEMP TABLE running_balance AS
WITH date_series AS (
    -- 1. Génère la liste des jours sans récursion
    SELECT 
        GENERATE_SERIES(
            (SELECT MIN(DATE_TRUNC('day', txn_date)) FROM data_bank.customer_transactions),
            (SELECT MAX(DATE_TRUNC('day', txn_date)) FROM data_bank.customer_transactions),
            '1 day'::INTERVAL
        )::DATE AS day
),
customer_grid AS (
    -- 2. Crée la matrice (tous les clients x tous les days)
    SELECT DISTINCT customer_id, ds.day
    FROM data_bank.customer_transactions
    CROSS JOIN date_series ds
),
transactions_per_day AS (
    -- 3.On groupe les transactions par jour (au cas où il y en a plusieurs le même jour)
    SELECT 
        customer_id,
        txn_date::DATE AS day,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM data_bank.customer_transactions
    GROUP BY customer_id, day
)
-- 4. Calcule le solde cumulé avec densification des données
SELECT 
    cg.customer_id,
    cg.day,
    SUM(COALESCE(tpd.net_change, 0)) OVER (PARTITION BY cg.customer_id  ORDER BY cg.day) AS running_balance
FROM customer_grid cg
LEFT JOIN transactions_per_day tpd ON cg.customer_id = tpd.customer_id AND cg.day = tpd.day;
```

#### b. Solde de fin de mois
- On crée une table temporaire pour réutiliser ces données
```sql
CREATE TEMP TABLE monthly_balances AS
WITH month_series AS (
    -- 1. Génère la liste des mois sans récursion
    SELECT 
        GENERATE_SERIES(
            (SELECT MIN(DATE_TRUNC('month', txn_date)) FROM data_bank.customer_transactions),
            (SELECT MAX(DATE_TRUNC('month', txn_date)) FROM data_bank.customer_transactions),
            '1 month'::INTERVAL
        )::DATE AS month
),
customer_grid AS (
    -- 2. Crée la matrice (tous les clients x tous les mois)
    SELECT DISTINCT customer_id, ms.month
    FROM data_bank.customer_transactions
    CROSS JOIN month_series ms
),
monthly_changes AS (
    -- 3. Calcule les flux monétaires réels par mois
    SELECT 
        customer_id,
        DATE_TRUNC('month', txn_date)::DATE AS month,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM data_bank.customer_transactions
    GROUP BY customer_id, month
)
-- 4. Calcule le solde cumulé avec densification des données
SELECT 
    cg.customer_id,
    cg.month,
    SUM(COALESCE(mc.net_change, 0)) OVER (PARTITION BY cg.customer_id ORDER BY cg.month) AS closing_balance
FROM customer_grid cg
LEFT JOIN monthly_changes mc 
    ON cg.customer_id = mc.customer_id 
    AND cg.month = mc.month;
```

#### c. Min, Moyenne et Max du solde par client
À partir du solde courant, on calcule les stats pour chaque client
```sql
CREATE TEMP TABLE customer_stats AS
SELECT 
    customer_id,
    MIN(running_balance) AS min_balance,
    ROUND(AVG(running_balance), 2) AS avg_balance,
    MAX(running_balance) AS max_balance
FROM running_balance
GROUP BY customer_id;
```

### 2. Calcul de l'allocation mensuelle par Option

#### **Option 1** : Allocation basée sur le solde à la fin du mois précédent
- On utilise ``LAG()`` pour récupérer le solde du mois précédent
- L'allocation du mois M est basée sur le solde de fin du mois M-1
- On somme pour tous les clients pour obtenir le total mensuel
- On ignore le premier mois (pas de mois précédent)

```sql
WITH previous_month_balance AS (
    SELECT 
        customer_id,
        month,
        closing_balance,
        LAG(closing_balance) OVER ( PARTITION BY customer_id  ORDER BY month) AS prev_month_balance
    FROM monthly_balances
)
SELECT 
    month,
    ROUND(SUM(prev_month_balance)) AS total_allocation_option1
FROM previous_month_balance
WHERE prev_month_balance IS NOT NULL
GROUP BY month
ORDER BY month;
```

#### **Option 2**:  Allocation basée sur les 30 jours précédents

```sql
WITH daily_avg_30 AS (
    SELECT 
        customer_id,
        day,
        running_balance,
        -- Moyenne sur les 30 derniers jours (incluant le jour courant)
        AVG(running_balance) OVER (
            PARTITION BY customer_id 
            ORDER BY day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS avg_30_days
    FROM running_balance
),

-- 3. Pour chaque mois, prendre la dernière moyenne disponible
monthly_avg AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', day)::DATE AS month,
        FIRST_VALUE(avg_30_days) OVER (
            PARTITION BY customer_id, DATE_TRUNC('month', day)
            ORDER BY day DESC
        ) AS month_avg_balance
    FROM daily_avg_30
)

-- 4. Calculer l'allocation totale par mois
SELECT 
    month,
    ROUND(SUM(month_avg_balance)) AS total_allocation_option2,
FROM monthly_avg
WHERE month_avg_balance IS NOT NULL
GROUP BY month
ORDER BY month;
```

#### **Option 3** : Mise à jour en temps réel
On doit trouver le solde maximum atteint pendant le mois; on calcule d'abord le max par jour (``daily_max``), puis le max par mois. La somme par mois donne l'allocation totale nécessaire
```sql
WITH daily_max AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', day)::DATE AS month,
        -- Prendre le solde maximum de chaque jour
        MAX(running_balance) AS daily_max_balance
    FROM running_balance
    GROUP BY customer_id, month, day
),
monthly_real_time AS (
    SELECT 
        customer_id,
        month,
        -- Pour l'option temps réel, on prend le maximum du mois
        MAX(daily_max_balance) AS max_monthly_balance
    FROM daily_max
    GROUP BY customer_id, month
)
SELECT 
    month,
    ROUND(SUM(max_monthly_balance)) AS total_allocation_option3
FROM monthly_real_time
GROUP BY month
ORDER BY month;
```


