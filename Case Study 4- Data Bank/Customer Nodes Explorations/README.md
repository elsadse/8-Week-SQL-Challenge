### 1.How many unique nodes are there on the Data Bank system?

Pour savoir combien de nœuds uniques existent dans tout le système Data Bank, il suffit de compter les valeurs distinctes de `node_id` dans la table `node_id`.
```sql
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;
```

### 2. What is the number of nodes per region?

Pour obtenir le nombre de nœuds par région, on joint la table `customer_nodes` avec `regions`, on compte les `node_id` distincts par région et on groupe par nom de région.
```sql
SELECT r.region_id,
    r.region_name,
    COUNT(DISTINCT cn.node_id) AS nodes_per_region
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name;
```

### 3. How many customers are allocated to each region?

Pour avoir le nombre de clients uniques par région. On joint ``customer_nodes`` et `regions`, on compte les ``customer_id`` distincts et on groupe par région.
```sql
SELECT r.region_id,
    r.region_name,
    COUNT(DISTINCT cn.customer_id) AS unique_customers
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name;
```

### 4.How many days on average are customers reallocated to a different node?

Pour avoir le nombre de jours en moyenne les clients sont réalloués à un nœud différent:
- On calcule d'abord la durée (en jours) pour chaque période où un client est assigné à un nœud spécifique (``end_date - start_date``)
- On filtre avec ``WHERE end_date != '9999-12-31' AND end_date >= start_date`` pour ne prendre en compte que les périodes terminées et éviter les valeurs aberrantes (comme les dates de fin par défaut qui pourraient indiquer une affectation actuelle)
- on calcule la moyenne de ces durées avec ``AVG()`` et on l'arrondit avec ``ROUND()``.

```sql
SELECT 
    ROUND(AVG(end_date - start_date)) AS avg_reallocation_days
FROM data_bank.customer_nodes
WHERE end_date != '9999-12-31'
  AND end_date >= start_date;  
```

### 5.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?