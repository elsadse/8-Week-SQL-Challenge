Using a single SQL query - create a new output table which has the following details:

- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?

```sql
-- Table de synthèse pour chaque produit
DROP TABLE IF EXISTS product_info;
CREATE TABLE product_info AS
WITH product_events AS (
  SELECT 
    e.visit_id,
    ph.page_name AS product_name,
    ph.product_category,

    -- Le produit a-t-il été vu dans cette visite ?
    CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END AS was_viewed,

    -- Le produit a-t-il été ajouté au panier dans cette visite ?
    CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END AS was_added_to_cart

  FROM clique_bait.events e

  -- Jointure pour avoir le nom  des produits
  JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
  WHERE ph.product_id IS NOT NULL -- Exclure les pages non-produits
),
purchase_events AS (
  -- Identifier les visites avec achat
  SELECT DISTINCT visit_id
  FROM clique_bait.events
  WHERE event_type = 3
)
SELECT 
  pe.product_name,
  pe.product_category,

  -- Nombre total de vues
  SUM(pe.was_viewed) AS views,

  -- Nombre total d'ajouts au panier
  SUM(pe.was_added_to_cart) AS cart_adds,

  -- Nombre d'abandons: ajouté au panier MAIS visite sans achat
  SUM(CASE WHEN pe.was_added_to_cart = 1 AND pv.visit_id IS NULL THEN 1 ELSE 0 END) AS abandoned,

  -- Nombre d'achats: ajouté au panier ET visite avec achat
  SUM(CASE WHEN pe.was_added_to_cart = 1 AND pv.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS purchases
FROM product_events pe

-- Jointure pour identifier les visites avec achat
LEFT JOIN purchase_events pv ON pe.visit_id = pv.visit_id

GROUP BY pe.product_name, pe.product_category;
```

Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
```sql
DROP TABLE IF EXISTS category_info;
CREATE TABLE category_info AS
SELECT 
  product_category,
  SUM(views) AS total_views,
  SUM(cart_adds) AS total_cart_adds,
  SUM(abandoned) AS total_abandoned,
  SUM(purchases) AS total_purchases
FROM product_info
GROUP BY product_category;
```

Use your 2 new output tables - answer the following questions:

Which product had the most views, cart adds and purchases?
Which product was most likely to be abandoned?
Which product had the highest view to purchase percentage?
What is the average conversion rate from view to cart add?
What is the average conversion rate from cart add to purchase?