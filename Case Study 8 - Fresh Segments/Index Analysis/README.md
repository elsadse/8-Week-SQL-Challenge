
The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

```sql
CREATE TABLE filtered_metrics AS
SELECT *
FROM fresh_segments.interest_metrics
WHERE month_year IS NOT NULL;

CREATE TABLE filtered_interests AS
SELECT interest_id
FROM filtered_metrics
GROUP BY interest_id
HAVING COUNT(DISTINCT month_year) >= 6
```

### 1. What is the top 10 interests by the average composition for each month?
Pour chaque ``month_year``, on calcule ``avg_composition = ROUND(composition / index_value, 2)``, on classe les intérêts par cette valeur (DESC), et on garde uniquement le top 10. ``RANK()`` permet d'avoir le rang dans le classement 
```sql
WITH avg_composition AS (
    SELECT 
        month_year,
        interest_id,
        ROUND((composition / index_value)::NUMERIC, 2) AS avg_composition
    FROM filtered_metrics
  	WHERE interest_id IN (SELECT interest_id FROM filtered_interests)
),
ranked AS (
    SELECT 
        month_year,
        interest_id,
        avg_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS rank_in_month
    FROM avg_composition
)
SELECT 
    rn.month_year,
    im.interest_name,
    rn.avg_composition,
    rn.rank_in_month
FROM ranked rn
JOIN fresh_segments.interest_map im ON rn.interest_id::INTEGER = im.id
WHERE rank_in_month <= 10
ORDER BY month_year, rank_in_month;
```

### 2. For all of these top 10 interests - which interest appears the most often?
On réutilise le top 10 de la question 1, on compte le nombre d’apparitions par intérêt sur tous les mois, et on trie par nombre décroissant
```sql
WITH avg_composition AS (
    SELECT 
        month_year,
        interest_id,
        ROUND((composition / index_value)::NUMERIC, 2) AS avg_composition
    FROM filtered_metrics
  	WHERE interest_id IN (SELECT interest_id FROM filtered_interests)
),
ranked AS (
    SELECT 
        month_year,
        interest_id,
        avg_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS rank_in_month
    FROM avg_composition
)
SELECT 
    im.interest_name,
    COUNT(rn.interest_id) AS times_in_top10
FROM ranked rn
JOIN fresh_segments.interest_map im ON rn.interest_id::INTEGER = im.id
WHERE rank_in_month <= 10
GROUP BY im.interest_name
ORDER BY times_in_top10 DESC;
```

### 3. What is the average of the average composition for the top 10 interests for each month?
On réutilise le top 10 de la question 1, on compte la moyenne ``AVG()`` de la moyenne des composition `ROUND((composition / index_value)::NUMERIC, 2)` pour chaque mois.
```sql
WITH avg_composition AS (
    SELECT 
        month_year,
        interest_id,
        ROUND((composition / index_value)::NUMERIC, 2) AS avg_composition
    FROM filtered_metrics
  	WHERE interest_id IN (SELECT interest_id FROM filtered_interests)
),
ranked AS (
    SELECT 
        month_year,
        interest_id,
        avg_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS rank_in_month
    FROM avg_composition
)
SELECT 
    rn.month_year,
    ROUND(AVG(rn.avg_composition),2) AS avg_of_avg_composition
FROM ranked rn
WHERE rank_in_month <= 10
GROUP BY rn.month_year
ORDER BY rn.month_year;
```

### 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
- On réutilise le top 10 de la question 1 mais on garde le max de ``avg_composition`` (`WHERE rank_in_month=1`)
- On calcule la moyenne sur 3 mois avec `AVG() OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`
- On utilise ``LAG()`` pour récupérer le top intérêt `interest_name` et sa valeur `max_avg_composition` du mois précédent et d’il y a 2 mois
- On filtre entre septembre 2018 et août 2019 `WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01'`
```sql
WITH avg_composition AS (
    SELECT 
        month_year,
        interest_id,
        ROUND((composition / index_value)::NUMERIC, 2) AS avg_composition
    FROM filtered_metrics
  	WHERE interest_id IN (SELECT interest_id FROM filtered_interests)
),
ranked AS (
    SELECT 
        month_year,
        interest_id,
        avg_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) AS rank_in_month
    FROM avg_composition
),
monthly_max_avg_comp AS(
  SELECT 
      rn.month_year,
      im.interest_name,
      rn.avg_composition AS max_avg_composition,
  	  rn.rank_in_month
  FROM ranked rn
  JOIN fresh_segments.interest_map im ON rn.interest_id::INTEGER = im.id
  WHERE rank_in_month=1
  ORDER BY rn.month_year
),
month_avg_with_previous AS (
  SELECT 
    month_year,
    interest_name,
    max_avg_composition AS max_index_composition,
    ROUND(AVG(max_avg_composition) OVER (ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS "3_month_moving_avg",
    LAG(interest_name || ': ' || max_avg_composition, 1) OVER (ORDER BY month_year) AS "1_month_ago",
    LAG(interest_name || ': ' || max_avg_composition, 2) OVER (ORDER BY month_year) AS "2_months_ago"
  FROM monthly_max_avg_comp
)
SELECT *
FROM month_avg_with_previous
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';
```

### 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments? raisonnement et psql