--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select DATE_TRUNC('week', registration_date)::date AS registration_week, count(runner_id) as nb_runner
from runners 
group by registration_week
order by registration_week DESC;


--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_orders.order_id,  avg(EXTRACT(EPOCH FROM (pickup_time::timestamp - order_time::timestamp)) / 60) as avg_minutes_to_pickup
from runner_orders
join customer_orders on runner_orders.order_id= customer_orders.order_id
where (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
group by runner_orders.order_id
order by  runner_orders.order_id asc;



--Is there any relationship between the number of pizzas and how long the order takes to prepare?
select customer_orders.order_id, count(customer_orders.pizza_id) as nb_pizza, AVG(CAST(REGEXP_REPLACE(runner_orders.duration, '[^0-9]', '', 'g') AS INTEGER)) as duration_minutes
from customer_orders
join runner_orders on customer_orders.order_id= runner_orders.order_id
where (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
group by customer_orders.order_id
order by  customer_orders.order_id asc;


--What was the average distance travelled for each customer?
select customer_orders.customer_id, AVG(CAST(REGEXP_REPLACE(runner_orders.distance, '[^0-9]', '', 'g') AS NUMERIC)) as avg_distance
from customer_orders
join runner_orders on customer_orders.order_id= runner_orders.order_id
where (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
group by customer_orders.customer_id
order by  customer_orders.customer_id asc;


--What was the difference between the longest and shortest delivery times for all orders?
SELECT (MAX(CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS INTEGER)) -MIN(CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS INTEGER))) AS delivery_time_range
FROM runner_orders
WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null';


--What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, (CAST(REGEXP_REPLACE(distance, '[^0-9]', '', 'g') AS NUMERIC)/CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS NUMERIC)) AS avg_speed_km_per_minute
FROM runner_orders
WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null'
order by runner_id, order_id;


--What is the successful delivery percentage for each runner?
WITH total AS (
    SELECT runner_id, COUNT(*) AS total_orders
    FROM runner_orders
    GROUP BY runner_id
),
success AS (
    SELECT runner_id, COUNT(*) AS successful_orders
    FROM runner_orders
    WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null'
    GROUP BY runner_id
)
SELECT 
    total.runner_id,
    ROUND(success.successful_orders * 100.0 / total.total_orders, 2) AS success_rate
FROM total 
JOIN success  ON total.runner_id = success.runner_id;
