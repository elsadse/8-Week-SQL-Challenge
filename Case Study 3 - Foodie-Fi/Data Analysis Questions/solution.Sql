--How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM foodie_fi.subscriptions;


--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
    DATE_TRUNC('month', start_date) AS mois_debut,
    COUNT(*) AS nb_trials
FROM foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY mois_debut;


--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
    p.plan_name,
    COUNT(*) AS nb_evenements
FROM foodie_fi.subscriptions s
    JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_name
ORDER BY nb_evenements DESC;


--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
    p.plan_name,
    COUNT(*) AS nb_evenements
FROM foodie_fi.subscriptions s
    JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_name
ORDER BY nb_evenements DESC;


--How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH
    last_plan
    AS
    (
        SELECT
            customer_id,
            plan_id,
            start_date,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
        FROM foodie_fi.subscriptions
    )
SELECT
    COUNT(*) FILTER
(WHERE plan_id = 4) AS nb_churn,
    COUNT
(*) AS total_customers,
    ROUND
(100.0 * COUNT
(*) FILTER
(WHERE plan_id = 4) / COUNT
(*), 1) AS pct_churn
FROM last_plan
WHERE rn = 1;


--What is the number and percentage of customer plans after their initial free trial?


--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH
    ranked
    AS
    (
        SELECT
            s.customer_id,
            s.plan_id,
            p.plan_name,
            s.start_date,
            LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date,
            ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.start_date DESC) AS rn
        FROM foodie_fi.subscriptions s
            JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
    )
SELECT
    plan_name,
    COUNT(*) AS nb_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM ranked
WHERE '2020-12-31' >= start_date
    AND ('2020-12-31' < next_date OR next_date IS NULL)
GROUP BY plan_name, plan_id
ORDER BY plan_id;


--How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS nb_annual_2020
FROM foodie_fi.subscriptions s
    JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE p.plan_id = 3
    AND s.start_date BETWEEN '2020-01-01' AND '2020-12-31';


--How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH
    inscription
    AS
    (
        SELECT
            customer_id,
            MIN(start_date) AS date_inscription
        FROM foodie_fi.subscriptions
        GROUP BY customer_id
    ),
    annual
    AS
    (
        SELECT
            s.customer_id,
            s.start_date AS date_annual,
            i.date_inscription
        FROM foodie_fi.subscriptions s
            JOIN inscription i ON s.customer_id = i.customer_id
        WHERE s.plan_id = 3
        -- pro annual
    )
SELECT
    ROUND(AVG(date_annual - date_inscription), 1) AS jours_moyens_vers_annual
FROM annual;



--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH
    inscription
    AS
    (
        SELECT
            customer_id,
            MIN(start_date) AS date_inscription
        FROM foodie_fi.subscriptions
        GROUP BY customer_id
    ),
    annual
    AS
    (
        SELECT
            s.customer_id,
            s.start_date AS date_annual,
            i.date_inscription,
            (s.start_date - i.date_inscription) AS jours
        FROM foodie_fi.subscriptions s
            JOIN inscription i ON s.customer_id = i.customer_id
        WHERE s.plan_id = 3
    ),
    tranches
    AS
    (
        SELECT
            customer_id,
            CASE 
            WHEN jours <= 30                THEN '0-30 jours'
            WHEN jours <= 60                THEN '31-60 jours'
            WHEN jours <= 90                THEN '61-90 jours'
            WHEN jours <= 120               THEN '91-120 jours'
            WHEN jours <= 150               THEN '121-150 jours'
            WHEN jours <= 180               THEN '151-180 jours'
            ELSE 'Plus de 180 jours'
        END AS tranche
        FROM annual
    )
SELECT
    tranche,
    COUNT(*) AS nb_clients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_clients
FROM tranches
GROUP BY tranche
ORDER BY 
    MIN(CASE tranche
        WHEN '0-30 jours'      THEN 1
        WHEN '31-60 jours'     THEN 2
        WHEN '61-90 jours'     THEN 3
        WHEN '91-120 jours'    THEN 4
        WHEN '121-150 jours'   THEN 5
        WHEN '151-180 jours'   THEN 6
        ELSE 7 END);


--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT
    COUNT(DISTINCT s1.customer_id) AS nb_downgrades_2020
FROM foodie_fi.subscriptions s1
    JOIN foodie_fi.subscriptions s2
    ON s1.customer_id = s2.customer_id
        AND s1.start_date > s2.start_date
        AND s1.plan_id = 1
        AND s2.plan_id = 2
WHERE s1.start_date BETWEEN '2020-01-01' AND '2020-12-31'
    AND NOT EXISTS (                   
      SELECT 1
    FROM foodie_fi.subscriptions s_mid
    WHERE s_mid.customer_id = s1.customer_id
        AND s_mid.start_date > s2.start_date
        AND s_mid.start_date < s1.start_date
  );