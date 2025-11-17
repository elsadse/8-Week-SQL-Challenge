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