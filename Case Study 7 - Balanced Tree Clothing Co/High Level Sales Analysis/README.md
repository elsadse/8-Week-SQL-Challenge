### 1. What was the total quantity sold for all products?
On fait la somme ``SUM()`` de la colonne ``qty`` dans la table ``sales``
```sql
SELECT SUM(qty) AS total_quantity_sold
FROM balanced_tree.sales;
```
### 2. What is the total generated revenue for all products before discounts?
On fait la somme ``SUM()`` du prix unitaire ``price`` par la quantité ``qty`` dans la table ``sales``
```sql
SELECT SUM(qty * price) AS total_revenue_before_discount
FROM balanced_tree.sales;
```

### 3. What was the total discount amount for all products?
On calcule le montant de la remise ``(qty * price) * (discount / 100)``; et ensuite on somme le tout
```sql
SELECT SUM(qty * price * discount / 100) AS total_discount
FROM balanced_tree.sales;
```