-- 1. What is the total amount each customer spent at the restaurant?

select
    sales.customer_id
    , sum(
        case
            when menu.price is null then 0
            else menu.price
        end
    ) as total_amount
from sales
left join menu
	on menu.product_id = sales.product_id
group by sales.customer_id
;

-- 2. How many days has each customer visited the restaurant?

select
    sales.customer_id
    , count(distinct sales.order_date) as number_of_dates
from sales
group by sales.customer_id
;

-- 3. What was the first item from the menu purchased by each customer?

WITH
cte1 AS (SELECT customer_id, MIN(order_date) AS o_date
			FROM sales
			GROUP BY customer_id),
cte2 AS (SELECT sales.product_id, menu.product_name, sales.customer_id, sales.order_date
			FROM sales
			JOIN menu ON sales.product_id= menu.product_id)
SELECT cte1.customer_id, cte2.product_name, cte2.product_id
FROM cte1
JOIN cte2 ON cte1.customer_id= cte2.customer_id AND cte1.o_date=cte2.order_date;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH
cte1 AS (SELECT product_id, COUNT(product_id) as nb_time 
         FROM sales 
         GROUP BY product_id),
cte2 AS (SELECT product_id, product_name 
         FROM menu)
SELECT cte1.product_id, cte2.product_name, cte1.nb_time
FROM cte1  
JOIN cte2 ON cte1.product_id = cte2.product_id
ORDER BY cte1.nb_time DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?

WITH 
cte AS (
  SELECT customer_id, product_id, COUNT(product_id) as nb_time 
  FROM sales 
  GROUP BY customer_id, product_id),
cte2 AS (
  SELECT customer_id , MAX(nb_time) as max_nb_time
  FROM cte
  GROUP BY customer_id)
SELECT cte2.customer_id, cte.product_id, menu.product_name, cte2.max_nb_time
FROM cte
JOIN cte2 ON cte.customer_id= cte2.customer_id AND cte.nb_time= cte2.max_nb_time
JOIN menu ON menu.product_id= cte.product_id;


-- 6. Which item was purchased first by the customer after they became a member?

WITH 
cte AS (SELECT sales.customer_id, menu.product_name, sales.product_id,
	ROW_NUMBER() OVER ( PARTITION BY sales.customer_id
                       ORDER BY sales.order_date ASC ) AS rn
	FROM sales
	JOIN members ON sales.customer_id=members.customer_id
	JOIN menu ON sales.product_id= menu.product_id
	WHERE order_date>=join_date)
 
SELECT  cte.customer_id, cte.product_name, cte.product_id
FROM cte 
WHERE cte.rn=1;


-- 7. Which item was purchased just before the customer became a member?

WITH 
cte AS (SELECT sales.customer_id, menu.product_name, sales.product_id, sales.order_date,
	ROW_NUMBER() OVER ( PARTITION BY sales.customer_id
                       ORDER BY sales.order_date DESC ) AS rn
	FROM sales
	JOIN members ON sales.customer_id=members.customer_id
	JOIN menu ON sales.product_id= menu.product_id
	WHERE order_date<=join_date)
 
SELECT  cte.customer_id, cte.product_name, cte.product_id
FROM cte 
WHERE cte.rn=1;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT sales.customer_id,
COUNT(sales.product_id) AS total_item,
SUM(menu.price) AS total_amount
FROM sales
JOIN members ON sales.customer_id=members.customer_id
JOIN menu ON sales.product_id= menu.product_id
WHERE order_date<=join_date OR join_date is null
GROUP BY sales.customer_id;


-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT sales.customer_id, SUM (CASE menu.product_id
				                    WHEN 1 THEN menu.price*2*10
				                    ELSE menu.price*10
                                END) AS points
FROM sales
JOIN menu ON sales.product_id= menu.product_id
GROUP BY sales.customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT sales.customer_id, SUM (CASE 
				                WHEN sales.order_date>=members.join_date + INTERVAL '6 days' THEN menu.price*2*10
                                WHEN menu.product_id=1 THEN menu.price*2*10
				                ELSE menu.price*10
                            END) AS points
FROM sales
JOIN members ON sales.customer_id=members.customer_id
JOIN menu ON sales.product_id= menu.product_id
WHERE sales.order_date<= '2021-01-31' AND sales.order_date>= '2021-01-01' AND (sales.customer_id='A'OR sales.customer_id='B')
GROUP BY sales.customer_id;


