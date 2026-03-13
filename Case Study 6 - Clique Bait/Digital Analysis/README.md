### 1. How many users are there?
On utilise ``COUNT(DISTINCT ..)`` pour compter uniquement les valeurs uniques de ``user_id`` et éviter les doublons si un utilisateur apparaît plusieurs fois
```sql
SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.users;
```

### 2. How many cookies does each user have on average?
- CTE ``cookie_count`` : On calcule d'abord, pour chaque user_id, le nombre total de ``cookie_id`` qui lui sont associés.
- On fait la moyenne de ces totaux avec ``AVG()`` et on l'arrondit avec ``ROUND()``
```sql
WITH cookie_count AS (
  SELECT
    user_id,
    COUNT(cookie_id) AS total_cookies
  FROM clique_bait.users
  GROUP BY user_id
)
SELECT ROUND(AVG(total_cookies), 2) AS avg_cookies_per_user
FROM cookie_count;
```

### 3. What is the unique number of visits by all users per month?
- ``EXTRACT(MONTH FROM event_time)`` permet d'isoler le mois de la date de l'événement
- On groupe par mois `GROUP BY` et on compte chaque visite unique ``COUNT(DISTINCT visit_id)``
```sql
SELECT
  EXTRACT(MONTH FROM event_time) AS month_number,
  COUNT(DISTINCT visit_id) AS  total_visits
FROM clique_bait.events 
GROUP BY month_number
ORDER BY month_number;
```

### 4. What is the number of events for each event type?
- On joint ``events`` à ``event_identifier`` pour avoir le nom lisible de l'événement
- On groupe par ``event_name`` et ``event_type`` et on compte le nombre de lignes pour chaque type
```sql
SELECT
  ei.event_type,
  ei.event_name,
  COUNT(*) AS event_count
FROM clique_bait.events e
JOIN clique_bait.event_identifier ei ON e.event_type = ei.event_type
GROUP BY ei.event_type, ei.event_name;
```

### 5. What is the percentage of visits which have a purchase event?
- On compter le nombre total de visites uniques.
- On compter le nombre de visites ayant l'événement 'Purchase' (type 3).
- On fait le calcul du pourcentage.
```sql
SELECT 
  ROUND(
    100.0 * 
    COUNT(DISTINCT CASE WHEN event_type = 3 THEN visit_id END) / 
    COUNT(DISTINCT visit_id), 
  2) AS purchase_visit_percentage
FROM clique_bait.events;
```

### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```sql
```

### 7. What are the top 3 pages by number of views?
```sql
```

### 8. What is the number of views and cart adds for each product category?
```sql
```

### 9. What are the top 3 products by purchases?
```sql
```