-- How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

--What is the number of nodes per region?
SELECT r.region_id,
    r.region_name,
    COUNT(DISTINCT cn.node_id) AS nodes_per_region
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name;

--How many customers are allocated to each region?
SELECT r.region_id,
    r.region_name,
    COUNT(DISTINCT cn.customer_id) AS unique_customers
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name;

--How many days on average are customers reallocated to a different node?
SELECT 
    ROUND(AVG(end_date - start_date)) AS avg_reallocation_days
FROM data_bank.customer_nodes
WHERE end_date != '9999-12-31'
  AND end_date >= start_date; 

--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH reallocation_durations AS (
    SELECT 
        r.region_name,
        (cn.end_date - cn.start_date) AS duration
    FROM data_bank.customer_nodes cn
    JOIN data_bank.regions r ON cn.region_id = r.region_id
    WHERE cn.end_date != '9999-12-31' AND end_date >= start_date
)
SELECT 
    region_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY duration) AS percentile_50,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY duration) AS percentile_80,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration) AS percentile_95
FROM reallocation_durations
GROUP BY region_name;