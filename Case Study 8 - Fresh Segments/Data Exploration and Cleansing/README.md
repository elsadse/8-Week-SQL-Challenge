### 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
```sql
ALTER TABLE fresh_segments.interest_metrics 
ALTER COLUMN month_year TYPE DATE 
USING TO_DATE(month_year, 'MM-YYYY');
```

### 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
On utilise ``ORDER BY ... NULLS FIRST`` pour répondre à la contrainte
```sql
SELECT 
  month_year, 
  COUNT(*) as record_count
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year ASC NULLS FIRST;
```

### 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
Il faut les supprimer ou les ignorer.
```sql
DELETE FROM fresh_segments.interest_metrics
WHERE month_year IS NULL;

-- Ou

SELECT *
FROM fresh_segments.interest_metrics
WHERE month_year IS NOT NULL;
```

### 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
On vérifie si tous les IDs de la table de métriques existent dans la table de référence (map) et inversement

- Metrics vers Map:
```sql
SELECT COUNT(DISTINCT interest_id)
FROM fresh_segments.interest_metrics
WHERE interest_id::INTEGER NOT IN (SELECT id FROM fresh_segments.interest_map);
```

- Maps vers Metrics:
```sql
SELECT COUNT(DISTINCT map.id) AS orphan_map_ids
FROM fresh_segments.interest_map map
LEFT JOIN fresh_segments.interest_metrics metrics ON map.id = metrics.interest_id::INTEGER
WHERE metrics.interest_id IS NULL;
```

### 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
On vérifie s'il y a des doublons d'IDs dans la table de référence
```sql
SELECT 
  COUNT(*) as total_records,
  COUNT(DISTINCT id) as unique_ids
FROM fresh_segments.interest_map;
```

### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
Un ``INNER JOIN`` est le plus approprié pour l'analyse. Parce que nous voulons analyser les performances (``interest_metrics``) d'intérêts que nous pouvons nommer et décrire (``interest_map``). Si un ``interest_id`` n'a pas de nom, l'information est incomplète et difficile à interpréter. L'``INNER JOIN`` agit comme un filtre supplémentaire pour ne garder que les données de qualité
```sql
SELECT 
  me.*, 
  ma.interest_name, 
  ma.interest_summary, 
  ma.created_at, 
  ma.last_modified
FROM fresh_segments.interest_metrics me
INNER JOIN fresh_segments.interest_map ma ON me.interest_id::INTEGER = ma.id
WHERE me.interest_id::INTEGER = 21246;
```

### 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
```sql
SELECT 
  COUNT(*) 
FROM fresh_segments.interest_metrics me
JOIN fresh_segments.interest_map ma ON me.interest_id::INTEGER = ma.id
WHERE me.month_year <  ma.created_at::DATE
	AND me.month_year IS NOT NULL;
```
#### Validité:
Du point de vue metier ces données sont valides. La date ``created_at`` est souvent l'heure exacte de l'enregistrement en base de données, tandis que ``month_year`` représente l'ensemble du mois. Si un intérêt a été créé le ``15 juillet``, il est normal d'avoir des données pour le mois de "Juillet" ``(2019-07-01)``