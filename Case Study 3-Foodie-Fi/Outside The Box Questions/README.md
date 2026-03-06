### 1. How would you calculate the rate of growth for Foodie-Fi?
```sql
SELECT
    DATE_TRUNC('month', payment_date) AS mois,
    SUM(amount) AS mrr
FROM payments
WHERE plan_id IN (1,2,3)
GROUP BY mois
ORDER BY mois;
```

### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

Je recommande une métrique qui prend en compte les upgrade, les downgrades et les churn

### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

#### a. Pourquoi annulez-vous votre abonnement Foodie-Fi aujourd’hui ?
#### b. Combien de fois par semaine utilisiez-vous Foodie-Fi ces derniers temps ?
#### c. Y a-t-il quelque chose que nous pourrions améliorer pour vous faire changer d’avis?

