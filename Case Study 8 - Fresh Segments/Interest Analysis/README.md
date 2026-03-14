Pour repondre à nos questions, nous allons utilisé `filtered_metrics` à la place de `interest_metrics` pour filtrer les données où ``month_year`` n'est pas null car nous ne voulons pas modifier le dataset
```sql
CREATE TABLE filtered_metrics AS
SELECT *
FROM fresh_segments.interest_metrics
WHERE month_year IS NOT NULL;
```

### 1. Which interests have been present in all month_year dates in our dataset?
On calcule d'abord le nombre de mois où chaque intérêt apparaît (`interest_month_count`). Ensuite, on compare ce nombre au nombre total de mois uniques dans le dataset. La jointure c'est pour avoir le nom de l'intérêt
```sql
WITH interest_month_count AS (
    SELECT 
        interest_id,
        COUNT(DISTINCT month_year) as month_count
    FROM filtered_metrics
    GROUP BY interest_id
)
SELECT 
    interest_id,
    map.interest_name,
    imc.month_count
FROM interest_month_count imc
INNER JOIN fresh_segments.interest_map map ON imc.interest_id::INTEGER = map.id
WHERE imc.month_count = (SELECT COUNT(DISTINCT month_year) FROM filtered_metrics);
```

### 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
- Créer une table qui compte le nombre d'intérêt par `total_months` (`frequency_cte`).
- Utiliser une fonction de fenêtre (``SUM OVER``) pour calculer le total cumulé.
- Calculer le pourcentage par rapport au total global.
```sql
WITH interest_counts AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) AS total_months
  FROM filtered_metrics
  GROUP BY interest_id
),
frequency_cte AS (
  SELECT 
    total_months,
    COUNT(*) AS num_interests
  FROM interest_counts
  GROUP BY total_months
)
SELECT 
  total_months,
  num_interests,
  ROUND(100 * SUM(num_interests) OVER (ORDER BY total_months DESC) / 
    SUM(num_interests) OVER (), 2) AS cumulative_percentage
FROM frequency_cte
ORDER BY total_months DESC;
```

### 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
```sql
WITH interest_counts AS (
  SELECT 
    interest_id, 
    COUNT(DISTINCT month_year) as months_count
  FROM filtered_metrics
  GROUP BY interest_id
)
SELECT COUNT(*) as removed_rows
FROM filtered_metrics
WHERE interest_id IN (
  SELECT interest_id FROM interest_counts WHERE months_count < 6 -- Seuil trouvé à la question 2 
);
```

### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
- **Oui**. Les intérêts qui n'apparaissent que quelques mois sont soit très saisonniers (ex: "Acheteurs de décorations de Noël"), soit temporaires, soit peu fiables. Les exclure nous permet de nous concentrer sur les centres d'intérêt "core business" du client, ceux qui sont suivis de manière constante
- **Exemple** : Imaginez un intérêt "Acheteurs de voitures de luxe" présent 14 mois. On a un historique complet. On peut voir la saisonnalité, les tendances de fond. Un intérêt "Fans de la Coupe du Monde 2018". Ce segment apparaît en juillet, puis disparaît

### 5. After removing these interests - how many unique interests are there for each month?
- On recupère les intérêts filtrés `valid_interests`
- On compte les intérêts uniques présent dans les intérêts filtrés
```sql
WITH valid_interests AS (
  SELECT interest_id
  FROM filtered_metrics
  GROUP BY interest_id
  HAVING COUNT(DISTINCT month_year) >= 6 --Seuil 
)
SELECT 
  month_year,
  COUNT(DISTINCT interest_id) as unique_interest_count
FROM filtered_metrics
WHERE interest_id IN (SELECT interest_id FROM valid_interests)
GROUP BY month_year
ORDER BY month_year;
```