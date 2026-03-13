-- 1. What was the total quantity sold for all products?
SELECT SUM(qty) AS total_quantity_sold
FROM balanced_tree.sales;

-- 2. What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) AS total_revenue_before_discount
FROM balanced_tree.sales;


-- 3. What was the total discount amount for all products?
SELECT SUM(qty * price * discount / 100) AS total_discount
FROM balanced_tree.sales;
