-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.users;


-- 2. How many cookies does each user have on average?
WITH cookie_count AS (
  SELECT
    user_id,
    COUNT(cookie_id) AS total_cookies
  FROM clique_bait.users
  GROUP BY user_id
)
SELECT ROUND(AVG(total_cookies), 2) AS avg_cookies_per_user
FROM cookie_count;


-- 3. What is the unique number of visits by all users per month?
SELECT
  EXTRACT(MONTH FROM event_time) AS month_number,
  COUNT(DISTINCT visit_id) AS  total_visits
FROM clique_bait.events 
GROUP BY month_number
ORDER BY month_number;


-- 4. What is the number of events for each event type?
SELECT
  ei.event_type,
  ei.event_name,
  COUNT(*) AS event_count
FROM clique_bait.events e
JOIN clique_bait.event_identifier ei ON e.event_type = ei.event_type
GROUP BY ei.event_type, ei.event_name;


-- 5. What is the percentage of visits which have a purchase event?
SELECT 
  ROUND(
    100.0 * 
    COUNT(DISTINCT CASE WHEN event_type = 3 THEN visit_id END) / 
    COUNT(DISTINCT visit_id), 
  2) AS purchase_visit_percentage
FROM clique_bait.events;


-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
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


-- 7. What are the top 3 pages by number of views?
SELECT 
  ph.page_name,
  COUNT(*) AS total_views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = 1
GROUP BY ph.page_name
ORDER BY total_views DESC
LIMIT 3;


-- 8. What is the number of views and cart adds for each product category?
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


-- 9. What are the top 3 products by purchases?
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
