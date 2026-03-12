## Problem

In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
- Add a new demographic column using the following mapping for the first letter in the segment values
- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

## Solution

```sql
-- Création de la table nettoyée
DROP TABLE IF EXISTS data_mart.clean_weekly_sales;

CREATE TABLE data_mart.clean_weekly_sales AS (
  SELECT 
    -- 1. Conversion de week_date en format DATE
    TO_DATE(week_date, 'DD/MM/YY') AS week_date,
    
    -- 2. Extraction du numéro de semaine
    EXTRACT(WEEK FROM TO_DATE(week_date, 'DD/MM/YY'))::INT AS week_number,
    
    -- 3. Extraction du mois
    EXTRACT(MONTH FROM TO_DATE(week_date, 'DD/MM/YY'))::INT AS month_number,
    
    -- 4. Extraction de l'année
    EXTRACT(YEAR FROM TO_DATE(week_date, 'DD/MM/YY'))::INT AS calendar_year,
    
    region,
    platform,
    
    -- 5. Gestion des segment NULL
    CASE 
      WHEN segment = 'null' OR segment IS NULL THEN 'unknown'
      ELSE segment 
    END AS segment,
    
    -- 6. Création de la colonne age_band
    CASE 
      WHEN segment LIKE '%1' THEN 'Young Adults'
      WHEN segment LIKE '%2' THEN 'Middle Aged'
      WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
      ELSE 'unknown'
    END AS age_band,
    
    -- 7. Création de la colonne demographic
    CASE 
      WHEN segment LIKE 'C%' THEN 'Couples'
      WHEN segment LIKE 'F%' THEN 'Families'
      ELSE 'unknown'
    END AS demographic,
    
    customer_type,
    transactions,
    sales,
    
    -- 8. Calcul de la transaction moyenne
    ROUND((sales/ transactions), 2) AS avg_transaction
    
  FROM data_mart.weekly_sales
);
```
