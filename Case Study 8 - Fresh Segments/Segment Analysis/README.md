```sql
CREATE TABLE filtered_metrics AS
SELECT *
FROM fresh_segments.interest_metrics
WHERE month_year IS NOT NULL;
```

### 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
- On filtre d'abord les intérêts ayant moins de 6 mois de données `filtered_interests`
- Pour chaque ``interest_id`` filtré (`WHERE t1.interest_id IN (SELECT interest_id FROM filtered_interests)`), on cherche sa valeur de composition maximale (``RANK() OVER(ORDER BY...)``)
- On recupère le mois et le nom associé

```sql
WITH filtered_interests AS (
  SELECT interest_id
  FROM filtered_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
),
max_composition_per_interest AS (
  SELECT 
    t1.month_year,
    t2.interest_name,
    t1.composition,
    RANK() OVER (ORDER BY t1.composition DESC) as top_rank,
    RANK() OVER (ORDER BY t1.composition ASC) as bottom_rank
  FROM fresh_segments.interest_metrics t1
  JOIN fresh_segments.interest_map t2 ON t1.interest_id::INTEGER = t2.id
  WHERE t1.interest_id IN (SELECT interest_id FROM filtered_interests)
)
(SELECT 'Top 10' as category, interest_name, month_year, composition 
 FROM max_composition_per_interest WHERE top_rank <= 10)
UNION ALL
(SELECT 'Bottom 10' as category, interest_name, month_year, composition 
 FROM max_composition_per_interest WHERE bottom_rank <= 10)
ORDER BY category DESC, composition DESC;
```

### 2. Which 5 interests had the lowest average ranking value?
Pour chaque intérêt filtré, on calcule la moyenne ``AVG()`` de ``ranking``. On range en ordre croissant et on selectionne les 5 premiers
```sql
WITH filtered_interests AS (
  SELECT interest_id
  FROM filtered_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT 
  t1.interest_id,
  t2.interest_name,
  ROUND(AVG(t1.ranking), 2) as avg_ranking
FROM filtered_metrics t1
JOIN fresh_segments.interest_map t2 ON t1.interest_id::INTEGER = t2.id
WHERE t1.interest_id IN (SELECT interest_id FROM filtered_interests)
GROUP BY t2.interest_name, t1.interest_id
ORDER BY avg_ranking ASC
LIMIT 5;
```

### 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
Pour chaque intérêt filtré, on calcule l'écart type `STDDEV()` de `percentile_ranking`. On range en ordre décroissant et on selectionne les 5 premiers
```sql
WITH filtered_interests AS (
  SELECT interest_id
  FROM filtered_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT 
  t2.interest_name,
  ROUND(STDDEV(t1.percentile_ranking)::NUMERIC, 2) as stddev_ranking
FROM filtered_metrics t1
JOIN fresh_segments.interest_map t2 ON t1.interest_id::INTEGER = t2.id
WHERE t1.interest_id IN (SELECT interest_id FROM filtered_interests)
GROUP BY t2.interest_name
ORDER BY stddev_ranking DESC
LIMIT 5;
```

### 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
Pour répondre à cette question, je dois d'abord identifier les 5 intérêts ayant la plus grande volatilité (plus grand écart-type sur ``percentile_ranking``).
Ensuite, pour chacun de ces 5 intérêts, je récupère (`final_extremes`) :
- la valeur minimale de ``percentile_ranking`` + le ``month_year`` correspondant (le plus ancien en cas d'égalité),
- la valeur maximale de ``percentile_ranking`` + le ``month_year`` correspondant (le plus récent en cas d'égalité).
```sql
WITH filtered_interests AS (
  SELECT interest_id
  FROM filtered_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6
),
volatile_interests AS (
  SELECT 
    interest_id,
    ROUND(STDDEV(percentile_ranking)::numeric, 2) AS stddev_percentile
  FROM filtered_metrics
  WHERE interest_id IN (SELECT interest_id FROM filtered_interests)
  GROUP BY interest_id
  ORDER BY stddev_percentile DESC
  LIMIT 5
),
ranked_metrics AS (
  SELECT 
    fm.interest_id,
    fm.percentile_ranking,
    fm.month_year,
    ROW_NUMBER() OVER (PARTITION BY fm.percentile_ranking ORDER BY fm.month_year ASC) AS rn_min,   -- pour min
    ROW_NUMBER() OVER (PARTITION BY fm.percentile_ranking ORDER BY fm.month_year DESC) AS rn_max -- pour max 
  FROM filtered_metrics fm
  JOIN volatile_interests vi ON fm.interest_id = vi.interest_id
),

extremes AS (
  SELECT 
    interest_id,
    MIN(percentile_ranking) AS min_percentile,
    MAX(percentile_ranking) AS max_percentile
  FROM filtered_metrics
  WHERE interest_id IN (SELECT interest_id FROM volatile_interests)
  GROUP BY interest_id
),

final_extremes AS (
  SELECT 
    e.interest_id,
    e.min_percentile,
    rm_min.month_year AS month_year_min,
    e.max_percentile,
    rm_max.month_year AS month_year_max,
    vi.stddev_percentile
  FROM extremes e
  JOIN volatile_interests vi ON e.interest_id = vi.interest_id

  -- Pour le min : on prend la première occurrence (rn_min = 1)
  LEFT JOIN ranked_metrics rm_min 
    ON rm_min.interest_id = e.interest_id 
    AND rm_min.percentile_ranking = e.min_percentile 
    AND rm_min.rn_min = 1

  -- Pour le max : on prend la première occurrence dans l'ordre descendant (rn_max = 1)
  LEFT JOIN ranked_metrics rm_max 
    ON rm_max.interest_id = e.interest_id 
    AND rm_max.percentile_ranking = e.max_percentile 
    AND rm_max.rn_max = 1
)

SELECT 
  im.interest_name,
  fe.min_percentile,
  fe.month_year_min,
  fe.max_percentile,
  fe.month_year_max,
  fe.stddev_percentile
FROM final_extremes fe
JOIN fresh_segments.interest_map im ON fe.interest_id::INTEGER = im.id
ORDER BY fe.stddev_percentile DESC;
```

### 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?
- ``composition`` repond à cette question: Quels sont les intérêts qui touchent la plus grande partie de la base client ?
- ``ranking/index_value`` : Pour quels intérêts notre client est-il surreprésenté par rapport à la moyenne des clients ?
- Décision marketing : On devrait montrer des produits/services liés aux intérêts avec une forte composition et un bon index value. On devrait éviter des intérêts à faible composition et/ou à index value bas, car ils ne sont pas représentatifs de la base client