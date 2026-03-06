--If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT
    SUM(
        CASE WHEN pizza_names.pizza_name = 'MeatLovers' THEN 12
             WHEN pizza_names.pizza_name = 'Vegetarian' THEN 10
        END
    ) AS total_revenue
FROM customer_orders 
JOIN pizza_names  ON customer_orders.pizza_id = pizza_names.pizza_id
JOIN runner_orders  ON customer_orders.order_id = runner_orders.order_id
WHERE (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
;


--hat if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra
SELECT
    SUM(
        CASE 
            WHEN pizza_names.pizza_name = 'MeatLovers' THEN 12
            WHEN pizza_names.pizza_name = 'Vegetarian' THEN 10
        END
        + COALESCE(array_length(string_to_array(extras, ','), 1), 0) * 1
    ) AS total_revenue
FROM customer_orders 
JOIN pizza_names  ON customer_orders.pizza_id = pizza_names.pizza_id
JOIN runner_orders  ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL 
      OR runner_orders.cancellation = '' 
      OR runner_orders.cancellation = 'null'
;


--The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE TABLE runner_ratings (
    rating_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    runner_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    rating_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comments TEXT,
    FOREIGN KEY (order_id) REFERENCES runner_orders(order_id),
    FOREIGN KEY (runner_id) REFERENCES runners(runner_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
INSERT INTO runner_ratings (order_id, runner_id, customer_id, rating, comments)
VALUES
(1, 1, 1, 5, 'Fast and friendly'),
(2, 1, 1, 4, 'Good delivery'),
(3, 2, 2, 3, 'Average service'),
(4, 3, 3, 5, 'Perfect timing'),
(5, 3, 4, 4, 'Quick and warm delivery'),
(7, 2, 1, 2, 'Late arrival, pizza was cold'),
(8, 2, 2, 5, 'Excellent experience');


--If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH delivered_pizzas AS (
    SELECT customer_orders.order_id,
           pizza_names.pizza_name,
           CASE 
                WHEN pizza_names.pizza_name = 'Meat Lovers' THEN 12
                WHEN pizza_names.pizza_name = 'Vegetarian' THEN 10
           END AS pizza_price
    FROM customer_orders 
    JOIN pizza_names  ON customer_orders.pizza_id = pizza_names.pizza_id
    JOIN runner_orders r ON customer_orders.order_id = runner_orders.order_id
    WHERE runner_orders.cancellation IS NULL OR runner_orders.cancellation = '' OR runner_orders.cancellation = 'null'
),
delivered_distance AS (
    SELECT order_id,
           CAST(REGEXP_REPLACE(distance, '[^0-9\.]', '', 'g') AS NUMERIC) AS km
    FROM runner_orders
    WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null'
)
SELECT 
    SUM(pizza_price) - SUM(km * 0.30) AS net_profit
FROM delivered_pizzas
JOIN delivered_distance USING (order_id)
;


--Bonus
--If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
-- inserer une pizza supreme
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');
-- inserer la recettte avec tous les topping
INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1,2,3,4,5,6,7,8,9,10,11,12');


