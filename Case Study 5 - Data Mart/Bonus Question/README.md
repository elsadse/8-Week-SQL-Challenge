## Context
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region
- platform
- age_band
- demographic
- customer_type


## Solution
L'entreprise veut savoir : "Quels segments précis ont été les plus touchés par cette baisse?"
L'idée est de décomposer l'impact par region, platform, age_band, demographic et customer_type.

### Raisonnement
Pour cette analyse, nous devons :
- Calculer les ventes avant/après (12 semaines) .
- Ajouter une clause ``GROUP BY`` sur l'impact spécifique.
- Identifier là où la baisse est la plus importante.

### Requête 
Pour analyser chaque impact, remplacer ``region`` par l'impact que vous souhaiter analyser (region, platform, age_band, demographic et customer_type)
```sql
WITH impact_analysis  AS (
  SELECT
    region AS dimension_value, -- impact region
    SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales END) AS before_sales,
    SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales END) AS after_sales
  FROM data_mart.clean_weekly_sales
  WHERE calendar_year = 2020
  GROUP BY dimension_value
)
SELECT
  dimension_value,
  before_sales,
  after_sales,
  (after_sales - before_sales) AS variance,
  ROUND(100 * (after_sales - before_sales) / before_sales, 2) AS percentage_change
FROM impact_analysis 
ORDER BY percentage_change ASC; -- Les plus impactés en premier
```
