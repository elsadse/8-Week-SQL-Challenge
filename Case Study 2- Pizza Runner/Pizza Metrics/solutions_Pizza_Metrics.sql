--1. How many pizzas were ordered?
SELECT COUNT(pizza_id) AS nb_pizza
FROM customer_orders;


-- 2.How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id) AS nb_customer
FROM customer_orders;


-- 3.How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS nb_runner
FROM runner_orders
WHERE runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null
GROUP BY runner_id;


--4. How many of each type of pizza was delivered?
SELECT customer_orders.pizza_id, (CASE 
                                  	WHEN pizza_names.pizza_name is null THEN 'unrecognized type'
                                  	ELSE pizza_names.pizza_name
                                  END) AS pizza_type, COUNT(*) AS nb_pizza_delivered
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
LEFT JOIN pizza_names ON  customer_orders.pizza_id=pizza_names.pizza_id
WHERE  runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null
GROUP BY customer_orders.pizza_id, pizza_type;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_orders.customer_id, pizza_names.pizza_name, COUNT(customer_orders.pizza_id) AS nb_pizza_ordered
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id=pizza_names.pizza_id
WHERE pizza_name IN ('Vegetarian','Meatlovers')
GROUP BY customer_orders.customer_id, pizza_names.pizza_name;


-- 6.What was the maximum number of pizzas delivered in a single order?
WITH 
delivered AS (SELECT customer_orders.order_id, COUNT(customer_orders.   pizza_id) AS nb_pizza_delivered
				FROM customer_orders
				JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
				WHERE  runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null
				GROUP BY customer_orders.order_id)
SELECT delivered.order_id, delivered.nb_pizza_delivered
FROM delivered
WHERE delivered.nb_pizza_delivered IN(
    SELECT MAX(delivered.nb_pizza_delivered) 
    FROM delivered);


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_orders.customer_id, SUM(CASE
                                            WHEN (customer_orders.exclusions IN('', 'null') OR customer_orders.exclusions is null) AND (customer_orders.extras IN('', 'null') OR customer_orders.extras is null) THEN 1
                                            ELSE 0
                                        END) AS nb_pizza_delivered_not_change, 
        SUM(CASE
                WHEN  (customer_orders.exclusions IN('', 'null') OR customer_orders.exclusions is null) AND (customer_orders.extras IN('', 'null') OR customer_orders.extras is null) THEN 0
                ELSE 1
            END) AS nb_pizza_delivered_change        
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
WHERE (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null) 
GROUP BY customer_orders.customer_id;


-- 8.How many pizzas were delivered that had both exclusions and extras?
SELECT SUM(CASE
                WHEN  (customer_orders.exclusions not IN('', 'null') AND customer_orders.exclusions is not null) AND (customer_orders.extras not IN('', 'null') AND customer_orders.extras is not null) THEN 1
                ELSE 0
            END) AS nb_pizza_delivered_change      
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
WHERE (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null);


-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATE(order_time) AS order_date,
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(customer_orders.pizza_id) AS nb_pizza_ordered
FROM customer_orders
GROUP BY order_date, order_hour
ORDER BY order_date, order_hour;


-- 10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time, 'Month') AS order_month, 
    EXTRACT(WEEK FROM order_time) AS order_week,
    TO_CHAR(order_time, 'Day') AS day_of_week,
    COUNT(pizza_id) AS nb_pizza_ordered
FROM customer_orders
GROUP BY order_month, order_week, day_of_week
ORDER BY order_month, order_week, day_of_week DESC;