SELECT 
    s.customer_id,
    s.plan_id,
    p.plan_name,
    s.start_date,
    p.price
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY s.customer_id, s.start_date;