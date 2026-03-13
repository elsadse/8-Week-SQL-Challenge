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
Pour trouver le pourcentage de visites qui consultent la page de paiement sans qu'un achat soit effectué :
- CTE ``visit_checkout_purchase`` : On vérifie pour chaque visite si elle a vu la page Checkout (``page_id = 12``) et si elle a acheté (``made_purchase=1``). Si elle a vu checkout alors ``saw_checkout=1 ``
- On fait le calcul du pourcentage
```sql
WITH visit_checkout_purchase  AS (
  SELECT 
    visit_id,
    MAX(CASE WHEN page_id = 12 THEN 1 ELSE 0 END) AS saw_checkout,
    MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS made_purchase
  FROM clique_bait.events
  GROUP BY visit_id
)
SELECT 
  ROUND(
    100.0 * SUM(CASE WHEN saw_checkout = 1 AND made_purchase = 0 THEN 1 ELSE 0 END) 
    / SUM(saw_checkout), 
  2) AS pct_checkout_abandonment
FROM visit_checkout_purchase;
```

### 7. What are the top 3 pages by number of views?
- On ne garde que les événements de type 'Page View' (``event_type = 1``)
- On joint à ``page_hierarchy`` pour avoir le nom de la page
- On groupe par ``page_name``, on compte les occurrences et on prend les 3 premières avec ``LIMIT 3``
```sql
SELECT 
  ph.page_name,
  COUNT(*) AS total_views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = 1
GROUP BY ph.page_name
ORDER BY total_views DESC
LIMIT 3;
```

### 8. What is the number of views and cart adds for each product category?
- On joint ``events`` et ``page_hierarchy``. On exclut les pages qui n'ont pas de catégorie de produit avec ``WHERE ph.product_category IS NOT NULL``
- 0n utilise ``SUM(CASE...)`` pour avoir, pour chaque catégorie, le nombre total d'événements de type 'Page View' (``event_type = 1``) et de type 'Add to Cart' (``event_type = 2``)
```sql
SELECT 
  ph.product_category,
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS total_views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS total_cart_adds
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph 
  ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY total_views DESC;
```

### 9. What are the top 3 products by purchases?
- CTE ``purchase_sessions``: on identifie toute les visites avec pour but l'achat
- On joint `events` avec `page_hierarchy` pour avoir le nom du produit et avec `purchase_sessions` pour avoir les visites avec pour but l'achat
- On filtre que les produits ajoutés au panier `WHERE e.event_type = 2 `
- On groupe par nom de produit et prendre les 3 premiers
```sql
WITH purchase_sessions AS (
  SELECT DISTINCT visit_id
  FROM clique_bait.events
  WHERE event_type = 3 
)
SELECT 
  ph.page_name AS product_name,
  COUNT(*) AS total_purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
JOIN purchase_sessions ps ON e.visit_id = ps.visit_id
WHERE e.event_type = 2 
  AND ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY total_purchases DESC
LIMIT 3;
```