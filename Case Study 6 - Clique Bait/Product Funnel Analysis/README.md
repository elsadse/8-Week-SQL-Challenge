Using a single SQL query - create a new output table which has the following details:

- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?

```sql
-- Table de synthèse pour chaque produit
DROP TABLE IF EXISTS product_summary;
CREATE TABLE product_summary AS

WITH product_journey AS (
  -- Étape 1: Identifier toutes les interactions produit par visite
  SELECT 
    ph.product_id,
    ph.page_name AS product_name,
    e.visit_id,
    
    -- Le produit a-t-il été vu dans cette visite ?
    MAX(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS was_viewed,
    
    -- Le produit a-t-il été ajouté au panier dans cette visite ?
    MAX(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS was_added_to_cart,
    
    -- La visite s'est-elle terminée par un achat ?
    MAX(CASE WHEN purchase_events.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS visit_had_purchase
    
  FROM clique_bait.page_hierarchy ph

   -- jointure pour avoir le nom du produit
  LEFT JOIN clique_bait.events e ON ph.page_id = e.page_id
  
  -- jointure pour identifier les visites avec achat
  LEFT JOIN (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3
  ) purchase_events ON e.visit_id = purchase_events.visit_id
  
  WHERE ph.product_id IS NOT NULL  -- Exclure les pages non-produits
  GROUP BY ph.product_id, ph.page_name, e.visit_id
)

-- Étape 2: Agréger au niveau produit
SELECT
  product_name,
  
  -- Nombre total de vues (somme  was_viewed)
  SUM(was_viewed) AS total_views,
  
  -- Nombre total d'ajouts au panier
  SUM(was_added_to_cart) AS total_cart_adds,
  
  -- Nombre d'abandons: ajouté au panier MAIS visite sans achat
  SUM(CASE WHEN was_added_to_cart = 1 AND visit_had_purchase = 0 THEN 1 ELSE 0 END) AS total_abandoned,
  
  -- Nombre d'achats: ajouté au panier ET visite avec achat
  SUM(CASE WHEN was_added_to_cart = 1 AND visit_had_purchase = 1 THEN 1 ELSE 0 END) AS total_purchases

FROM product_journey
GROUP BY product_name
ORDER BY product_name;
```

Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

Use your 2 new output tables - answer the following questions:

Which product had the most views, cart adds and purchases?
Which product was most likely to be abandoned?
Which product had the highest view to purchase percentage?
What is the average conversion rate from view to cart add?
What is the average conversion rate from cart add to purchase?