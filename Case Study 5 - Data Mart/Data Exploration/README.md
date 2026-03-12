### 1. What day of the week is used for each week_date value?
- ``TO_CHAR(week_date, 'Day')`` : Convertit la date en nom du jour (Lundi, Mardi, etc.)
- ``EXTRACT(DOW FROM week_date)``: Donne le numéro du jour (0=Dimanche, 1=Lundi, ..., 6=Samedi)
```sql
SELECT DISTINCT 
  TO_CHAR(week_date, 'Day') AS day_of_week,
  EXTRACT(DOW FROM week_date) AS day_number
FROM data_mart.clean_weekly_sales
ORDER BY day_number;
```

### 2. What range of week numbers are missing from the dataset?
- ``generate_series(1, 52) ``: Crée une séquence de 1 à 52 (toutes les semaines possibles)
- ``LEFT JOIN`` : Identifie les semaines présentes dans nos données
- ``WHERE c.week_number IS NULL`` : Filtre pour ne garder que les semaines absentes
```sql
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
```

### 3. How many total transactions were there for each year in the dataset?
On fait la somme ``SUM()`` de toute les transactions en groupant ``GROUP BY`` par année
```sql
SELECT 
  calendar_year, 
  SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```

### 4. What is the total sales for each region for each month?
On fait la somme ``SUM()`` de toute les ventes en groupant ``GROUP BY`` par region et par mois
```sql
SELECT 
  region, 
  month_number, 
  SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;
```

### 5. What is the total count of transactions for each platform
On fait la somme ``SUM()`` de toute les transactions en groupant ``GROUP BY`` par plateforme
```sql
SELECT 
  platform, 
  SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform;
```

### 6. What is the percentage of sales for Retail vs Shopify for each month?
- CTE ``platform_sales``: on trouve la somme total des ventes pour chaque plateforme
- On calcule le pourcentage des ventes pour chaque plateforme. `SUM(total_sales) OVER()` calcule la somme globale des ventes de toutes les plateformes
```sql
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
```

### 7. What is the percentage of sales by demographic for each year in the dataset?
- Grouper les ventes par ``calendar_year`` et ``demographic``
- Calculer le total ``SUM(sales)`` des ventes pour chaque groupe
- On calcule le pourcentage des ventes pour chaque groupe. ` SUM(SUM(sales)) OVER (PARTITION BY calendar_year)` calcule la somme globale des ventes pour chaque année
```sql
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
```

### 8. Which age_band and demographic values contribute the most to Retail sales?
- Filtrer les ventes au détail `WHERE platform = 'Retail'`
- Grouper les ventes par ``age_band`` et ``demographic``
- Calculer le total ``SUM(sales)`` des ventes pour chaque groupe
- On calcule le pourcentage des ventes pour chaque groupe. ` SUM(SUM(sales)) OVER ()` calcule la somme globale des ventes
```sql
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
```

### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
```sql
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
```