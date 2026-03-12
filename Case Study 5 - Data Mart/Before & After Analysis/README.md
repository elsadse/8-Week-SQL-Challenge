## Context
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

## Solution

### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
- CTE ``sales_periods`` : On isole uniquement l'année 2020 et les 8 semaines qui nous intéressent (4 avant, 4 après).
- CTE ``aggregated_sales`` : Calcule la somme des ventes pour les 4 semaines avant et après le ``2020-06-15``
- percentage_change : On calcule la différence relative. Si le chiffre est négatif, le nouveau packaging a eu un impact négatif immédiat sur les ventes.
```sql
WITH sales_periods AS (
  SELECT
    week_date,
    week_number,
    SUM(sales) AS total_sales
  FROM data_mart.clean_weekly_sales
  WHERE calendar_year = 2020
    AND week_number BETWEEN (25 - 4) AND (25 + 3) -- Semaines 21 à 28
  GROUP BY week_date, week_number
),
aggregated_sales AS (
  SELECT
    SUM(CASE WHEN week_number < 25 THEN total_sales END) AS before_sales,
    SUM(CASE WHEN week_number >= 25 THEN total_sales END) AS after_sales
  FROM sales_periods
)
SELECT
  before_sales,
  after_sales,
  (after_sales - before_sales) AS sales_variance,
  ROUND(100 * (after_sales - before_sales) / before_sales, 2) AS percentage_change
FROM aggregated_sales;
```

### 2. What about the entire 12 weeks before and after?
Même raisonnement que précédemment sauf qu'on va prendre les 24 semaines qui nous intéressent
```sql

WITH sales_periods AS (
  SELECT
    week_date,
    week_number,
    SUM(sales) AS total_sales
  FROM data_mart.clean_weekly_sales
  WHERE calendar_year = 2020
    AND week_number BETWEEN (25 - 12) AND (25 + 11) 
  GROUP BY week_date, week_number
),
aggregated_sales AS (
  SELECT
    SUM(CASE WHEN week_number < 25 THEN total_sales END) AS before_sales,
    SUM(CASE WHEN week_number >= 25 THEN total_sales END) AS after_sales
  FROM sales_periods
)
SELECT
  before_sales,
  after_sales,
  (after_sales - before_sales) AS sales_variance,
  ROUND(100 * (after_sales - before_sales) / before_sales, 2) AS percentage_change
FROM aggregated_sales;
```

### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
Pour valider l'impact, nous devons répéter l'analyse "Before & After" (4 semaines avant et après la semaine 25) pour les années 2018 et 2019.
- Si 2018 et 2019 montrent une croissance à la semaine 25 alors que 2020 montre une baisse, alors le changement de packaging est très probablement le coupable.
- Si toutes les années montrent une baisse, alors c'est un facteur saisonnier externe.
```sql
Si 2018 et 2019 montrent une croissance à la semaine 25 alors que 2020 montre une baisse, alors le changement de packaging est très probablement le coupable.

Si toutes les années montrent une baisse, alors c'est un facteur saisonnier externe.
```
