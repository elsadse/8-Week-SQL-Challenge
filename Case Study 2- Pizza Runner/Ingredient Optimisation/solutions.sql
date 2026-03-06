--What are the standard ingredients for each pizza?
select pizza_names.pizza_id, pizza_names.pizza_name, pizza_recipes.toppings, STRING_AGG(pizza_toppings.topping_name, ', ') AS standard_ingredients
from pizza_recipes
join pizza_names on pizza_recipes.pizza_id = pizza_names.pizza_id
join pizza_toppings on pizza_toppings.topping_id = ANY(string_to_array(pizza_recipes.toppings, ',')::int[])
group by pizza_names.pizza_id, pizza_names.pizza_name, pizza_recipes.toppings
;


--What was the most commonly added extra?
select pizza_toppings.topping_id, pizza_toppings.topping_name, count(pizza_toppings.topping_id) as nb_time_added
from pizza_toppings
join customer_orders on pizza_toppings.topping_id = ANY(string_to_array(customer_orders.extras, ',')::int[])
where  customer_orders.extras IS NOT NULL AND customer_orders.extras NOT IN ('', 'null')
group by pizza_toppings.topping_id, pizza_toppings.topping_name
order by nb_time_added desc
limit 1
;

--What was the most common exclusion?
select pizza_toppings.topping_id, pizza_toppings.topping_name, count(pizza_toppings.topping_id) as nb_time_added
from pizza_toppings
join customer_orders on pizza_toppings.topping_id = ANY(string_to_array(customer_orders.exclusions, ',')::int[])
where  customer_orders.exclusions IS NOT NULL AND customer_orders.exclusions NOT IN ('', 'null')
group by pizza_toppings.topping_id, pizza_toppings.topping_name
order by nb_time_added desc
limit 1
;


--Generate an order item for each record in the customers_orders table in the format of one of the following:
select distinct customer_orders.order_id, 
(pizza_names.pizza_name || 
case
when (customer_orders.exclusions IS NOT NULL AND customer_orders.exclusions <> '' AND customer_orders.exclusions <> 'null') 
 	then ' - Exclude ' || (
        select string_agg(pizza_toppings.topping_name, ', ' order by pizza_toppings.topping_name) 
        from pizza_toppings 
        where pizza_toppings.topping_id = any(string_to_array(customer_orders.exclusions, ',')::int[])
        ) 
else ''
end
 || 
case
when (customer_orders.extras IS NOT NULL AND customer_orders.extras <> '' AND customer_orders.extras <> 'null') 
 	then ' - Extra ' || (
        select string_agg(pizza_toppings.topping_name, ', ' order by pizza_toppings.topping_name) 
        from pizza_toppings 
        where pizza_toppings.topping_id = any(string_to_array(customer_orders.extras, ',')::int[])
        )
else ''
end
) as order_item
from customer_orders
JOIN pizza_names  ON customer_orders.pizza_id = pizza_names.pizza_id
where pizza_names.pizza_name= 'Meatlovers'
;


--Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
WITH base AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        pn.pizza_name,
        string_to_array(pr.toppings, ',')::int[] AS base_toppings,
        string_to_array(co.extras, ',')::int[] AS extra_toppings,
        string_to_array(co.exclusions, ',')::int[] AS excl_toppings
    FROM customer_orders co
    JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
)
SELECT 
    order_id,
    pizza_name || ': ' ||
    string_agg(
        CASE 
            WHEN t.topping_id = ANY(extra_toppings)
            THEN '2x' || t.topping_name
            ELSE t.topping_name
        END,
        ', ' ORDER BY t.topping_name
    ) AS ingredient_list
FROM base b
JOIN pizza_toppings t 
    ON t.topping_id = ANY(
        ARRAY(
            SELECT unnest(base_toppings)
            EXCEPT SELECT unnest(excl_toppings)
            UNION SELECT unnest(extra_toppings)
        )
    )
GROUP BY order_id, pizza_name
ORDER BY order_id;

--What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH delivered AS (
    SELECT *
    FROM runner_orders
    WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null'
),
base AS (
    SELECT 
        co.order_id,
        string_to_array(pr.toppings, ',')::int[] AS base_toppings,
        string_to_array(co.extras, ',')::int[] AS extra_toppings,
        string_to_array(co.exclusions, ',')::int[] AS excl_toppings
    FROM customer_orders co
    JOIN delivered d ON co.order_id = d.order_id
    JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
),
expanded AS (
    SELECT unnest(base_toppings) AS topping_id,
           extra_toppings,
           excl_toppings
    FROM base
)
SELECT 
    pt.topping_name,
    COUNT(*) +
    (
        SELECT COUNT(*)
        FROM expanded e2
        WHERE e2.extra_toppings @> ARRAY[pt.topping_id]
    ) AS total_used
FROM expanded e
JOIN pizza_toppings pt ON pt.topping_id = e.topping_id
WHERE NOT (excl_toppings @> ARRAY[pt.topping_id])
GROUP BY pt.topping_name
ORDER BY total_used DESC;
