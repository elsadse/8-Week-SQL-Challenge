### 1. What are the top 3 products by total revenue before discount?
On joint les ventes aux détails du produit pour obtenir le nom. On calcule le revenu ``SUM(qty * s.price)``, on classe par odre décroissant et on prend les 3 premiers
```sql
SELECT 
  p.product_id,
  p.product_name,
  SUM(s.qty * s.price) AS total_revenue_before_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue_before_discount DESC
LIMIT 3;
```

### 2. What is the total quantity, revenue and discount for each segment?
On groupe par ``segment_name`` et on applique les fonctions d'agrégation ``SUM()`` pour la quantité, le revenu après remise, et le montant total de la remise.
```sql
SELECT
    pd.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2) AS total_discount_amount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
GROUP BY pd.segment_name;
```

### 3. What is the top selling product for each segment?
On calcule la quantité par produit, puis on découpe les données par segment. Dans chaque segment, on donne le rang 1 au produit ayant la plus grosse quantité
```sql
WITH product_revenue AS (
    SELECT 
        pd.segment_name,
        pd.product_name,
        SUM(s.qty ) AS total_quantity,
        RANK() OVER (PARTITION BY pd.segment_name ORDER BY SUM(s.qty) DESC) AS rn
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
)
SELECT segment_name, product_name, total_quantity
FROM product_revenue
WHERE rn = 1;
```

### 4. What is the total quantity, revenue and discount for each category?
Même raisonnement que le **2** mais en groupant par `category_name`
```sql
SELECT
	pd.category_id,
    pd.category_name,
    SUM(s.qty) AS total_quantity,
    SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2) AS total_discount_amount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
GROUP BY pd.category_id, pd.category_name;
```

### 5. What is the top selling product for each category?
Même raisonnement que le **3** mais en groupant par `category_name`
```sql
WITH product_revenue AS (
    SELECT 
        pd.category_name,
        pd.product_name,
        SUM(s.qty ) AS total_quantity,
        RANK() OVER (PARTITION BY pd.category_name ORDER BY SUM(s.qty) DESC) AS rn
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    GROUP BY pd.category_name, pd.product_name
)
SELECT category_name, product_name, total_quantity
FROM product_revenue
WHERE rn = 1;
```

### 6. What is the percentage split of revenue by product for each segment?
``SUM(SUM(...)) OVER (PARTITION BY segment)`` calcule le total des revenues du segment pour chaque ligne de produit,
```sql
SELECT 
    pd.segment_name,
    pd.product_name,
    SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
    ROUND(100.0 * SUM((s.qty * s.price) * (1 - s.discount / 100)) / SUM(SUM((s.qty * s.price) * (1 - s.discount / 100))) OVER (PARTITION BY pd.segment_name), 2) AS pct_of_segment_revenue
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
GROUP BY pd.segment_name, pd.product_name;
```

### 7. What is the percentage split of revenue by segment for each category?
Même logique que le pécédent sauf qu'on partitionne par ``category_name``
```sql
SELECT 
    pd.segment_name,
    pd.category_name,
    SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
    ROUND(100.0 * SUM((s.qty * s.price) * (1 - s.discount / 100)) / SUM(SUM((s.qty * s.price) * (1 - s.discount / 100))) OVER (PARTITION BY pd.category_name), 2) AS pct_of_segment_revenue
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
GROUP BY pd.category_name, pd.segment_name;
```

### 8. What is the percentage split of total revenue by category?
```sql
```

### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
```sql
```

### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
```sql
```