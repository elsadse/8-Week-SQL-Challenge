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
On calcule le revenu total par catégorie, puis on le divise par le revenu global ``SUM(SUM(...)) OVER()``
```sql
SELECT 
    pd.category_name,
    SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
    ROUND(100.0 * SUM((s.qty * s.price) * (1 - s.discount / 100)) / SUM(SUM((s.qty * s.price) * (1 - s.discount / 100))) OVER (), 2) AS pct_of_category_revenue
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
GROUP BY pd.category_name;
```

### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
- CTE `total_txns`: on trouve le nombre unique de transactions
- On joint ``sales`` et ``product_details`` pour avoir le nom du produit
- On joint ``sales`` et ``total_txns`` pour avoir le produit cartesien des deux tables
- On calcule le pourcentage de pénétration. 
```sql
WITH total_txns AS (
    SELECT COUNT(DISTINCT txn_id) AS total FROM balanced_tree.sales
)
SELECT
	pd.product_id,
    pd.product_name,
    ROUND(100.0 * COUNT(DISTINCT s.txn_id) / tt.total, 2) AS penetration_percentage
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
CROSS JOIN total_txns tt
GROUP BY pd.product_name, pd.product_id, tt.total
ORDER BY penetration_percentage DESC;
```

### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
L'objectif est de trouver le triplet le plus fréquent de produit différent.
- CTE ``unique_products_per_txn``: créer une liste propre des produits achetés dans chaque transaction, sans doublon
- CTE ``product_combinations``: c'est un auto-jointure double de `unique_products_per_txn`. La première jointure assure qu'on prend deux produits de la même transaction et que les produit ``prod1`` et ``prod2`` son différent tout en éliminant les doublons (**(A,B) et (B,A) sont des doublons**). La deuxième jointure ajoute un troisième produit de la même transaction, en s'assurant qu'il est différent et plus grand que le deuxième. Cela nous donne un triplet unique et ordonné (``prod1 < prod2 < prod3``) pour chaque combinaison de 3 produits distincts dans une transaction
- CTE `top_combination`: Pour chaque triplet unique, on compte combien de fois il apparaît. Puis on le met en ordre décroissant et on sélectionne le prémier de la liste
- On joint trois fois la table ``product_details`` pour remplacer les identifiants de produits (``prod1``, ``prod2``, ``prod3``) par leur nom
```sql
WITH unique_products_per_txn AS (
    SELECT DISTINCT txn_id, prod_id
    FROM balanced_tree.sales
),
product_combinations AS (
    SELECT 
        u1.prod_id AS prod1,
        u2.prod_id AS prod2,
        u3.prod_id AS prod3
    FROM unique_products_per_txn u1
    JOIN unique_products_per_txn u2 ON u1.txn_id = u2.txn_id AND u1.prod_id < u2.prod_id
    JOIN unique_products_per_txn u3 ON u2.txn_id = u3.txn_id AND u2.prod_id < u3.prod_id
),
top_combination AS (
    SELECT 
        prod1, prod2, prod3,
        COUNT(*) AS combination_count
    FROM product_combinations
    GROUP BY prod1, prod2, prod3
    ORDER BY combination_count DESC
    LIMIT 1
)
SELECT 
    pd1.product_name AS product_1,
    pd2.product_name AS product_2,
    pd3.product_name AS product_3,
    tc.combination_count
FROM top_combination tc
JOIN balanced_tree.product_details pd1 ON tc.prod1 = pd1.product_id
JOIN balanced_tree.product_details pd2 ON tc.prod2 = pd2.product_id
JOIN balanced_tree.product_details pd3 ON tc.prod3 = pd3.product_id;
```