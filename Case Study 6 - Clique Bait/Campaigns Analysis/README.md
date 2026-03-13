Generate a table that has 1 single row for every unique visit_id record and has the following columns:

- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

```sql
DROP TABLE IF EXISTS visit_info;
CREATE TABLE visit_info AS
SELECT 
  e.visit_id,
  u.user_id,

  -- Heure de debut de la visite
  MIN(e.event_time) AS visit_start_time,

  -- Nombre de page vues
  COUNT(CASE WHEN e.event_type = 1 THEN 1 END) AS page_views,

  -- Nombre d'ajout au panier
  COUNT(CASE WHEN e.event_type = 2 THEN 1 END) AS cart_adds,

  -- L'évènement est elle l'achat?
  MAX(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchase,

  ca.campaign_name,

  -- Nombre de Ad Impression
  COUNT(CASE WHEN e.event_type = 4 THEN 1 END) AS ad_impression,

  -- Nombre de Ad Click
  COUNT(CASE WHEN e.event_type = 5 THEN 1  END) AS ad_click,

  -- Liste des produits ajoutés au panier dans l'ordre chronologique
  STRING_AGG(
      CASE 
        WHEN e.event_type = 2 THEN ph.page_name 
        ELSE NULL 
      END, 
      ', ' ORDER BY e.sequence_number
    ) AS cart_products

FROM clique_bait.events e

-- Jointure pour avoir le nom du produit
JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id

-- Jointure pour avoir le user_id
JOIN clique_bait.users u ON e.cookie_id = u.cookie_id

-- Jointure pour avoir event_time entre start_date et end_date
LEFT JOIN clique_bait.campaign_identifier ca 
  ON e.event_time BETWEEN ca.start_date AND ca.end_date

GROUP BY e.visit_id, u.user_id, ca.campaign_name;
```

Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

Some ideas you might want to investigate further include:

- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
- Does clicking on an impression lead to higher purchase rates?
- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? - - What if we compare them with users who just an impression but do not click?
- What metrics can you use to quantify the success or failure of each campaign compared to eachother?