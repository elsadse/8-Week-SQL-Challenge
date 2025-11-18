You can inspect the entity relationship diagram and example data below.
[Pizza Runner Entity Relationship Diagram](./../../Images/Pizza%20Runner.png)

## Solutions of Case Study Questions Pizza Runner

### 1. How many pizzas were ordered?

Pour savoir le nombre total de pizzas commandées; nous allons compter les pizzas avec `count()`
```sql
SELECT COUNT(pizza_id) AS nb_pizza
FROM customer_orders;
```

### 2.How many unique customer orders were made?

Pour savoir combien de clients uniques ont passé des commandes; nous avons compter le nombre de client (avec `count()`) en récupérant un client une seule fois même si un client a passé plusieurs commande (grâce à `DISTINCT`) 
```sql
SELECT COUNT(DISTINCT customer_id) AS nb_customer
FROM customer_orders;
```

###3.How many successful orders were delivered by each runner?

Pour savoir le nombre de commandes réussies livrées par chaque livreur; nous avons

- Filtrer les commandes annulées
- Compter les commandes par runner en utilisant `count()`
```sql
SELECT runner_id, COUNT(order_id) AS nb_runner
FROM runner_orders
WHERE runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null
GROUP BY runner_id;
```

###4. How many of each type of pizza was delivered?

Pour savoir  le nombre total de pizzas de chaque type qui ont été  livrées; nous avons:

- Vérifier si la livraison a été effectuée en faisant une jointure entre les tables `customer_orders` et `runner_orders`
-  Obtenir le nom de la pizza et de gérer les pizzas non reconnues en faisant une jointure à gauche entre les tables `customer_orders` et `pizza_names`
- Filtrer les livraison qui n'ont pas été annulées
```sql
SELECT customer_orders.pizza_id, (CASE 
                                  	WHEN pizza_names.pizza_name is null THEN 'unrecognized type'
                                  	ELSE pizza_names.pizza_name
                                  END) AS pizza_type, COUNT(*) AS nb_pizza_delivered
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
LEFT JOIN pizza_names ON  customer_orders.pizza_id=pizza_names.pizza_id
WHERE  (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
GROUP BY customer_orders.pizza_id, pizza_type;
```

###5.How many Vegetarian and Meatlovers were ordered by each customer?

Pour avoir le nombre de pizzas Meatlovers et Vegetarian que chaque client a commandées; nous avons:

- Récupérer le type de pizza en faisant une jointure des tables `customer_orders` et `pizza_names`
- Filtrer le type de pizza Meatlovers ou Vegetarian
- Compter le nombre de type de pizza pour chaque client par type de pizza avec la fonction `count()`
```sql
SELECT customer_orders.customer_id, pizza_names.pizza_name, COUNT(customer_orders.pizza_id) AS nb_pizza_ordered
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id=pizza_names.pizza_id
WHERE pizza_name IN ('Vegetarian','Meatlovers')
GROUP BY customer_orders.customer_id, pizza_names.pizza_name;
```

### 6.What was the maximum number of pizzas delivered in a single order?

Pour avoir le nombre maximum de pizzas livrées dans une seule commande; nous avons:

- Vérifier si la livraison a été effectuée en faisant une jointure entre les tables `customer_orders` et `runner_orders`
- Compter le nombre de pizzas par commande avec `count()`
- Trouver la commande avec le plus grand nombre de pizzas en utilisant `max()` 
- Récupère la ou les commandes correspondant à ce maximum.
```sql
WITH 
delivered AS (SELECT customer_orders.order_id, COUNT(customer_orders.   pizza_id) AS nb_pizza_delivered
				FROM customer_orders
				JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
				WHERE  runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null
				GROUP BY customer_orders.order_id)
SELECT delivered.order_id, delivered.nb_pizza_delivered
FROM delivered
WHERE delivered.nb_pizza_delivered IN(
    SELECT MAX(delivered.nb_pizza_delivered) 
    FROM delivered)
```

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

Pour le nombre de pizzas livrées ayant aucun changement et le nombre de pizzas livrées avec  au moins un changement pour chaque client; nous avons:

- Vérifier si la livraison a été effectuée en faisant une jointure entre les tables `customer_orders` et `runner_orders`
- Vérifier si une pizza a un changement ou pas
- Compter les pizzas sans changement(`nb_pizza_delivered_not_change`) en utlisant `sum()`. Une pizza n'est pas modifiée s'il ya ni exclusions ni extras
- Compter les pizzas avec changement(`nb_pizza_delivered_change`) en utlisant `sum()`. Une pizza est  modifiée s'il ya soit une exclusions soit un  extras
```sql
SELECT customer_orders.customer_id, SUM(CASE
                                            WHEN (customer_orders.exclusions IN('', 'null') OR customer_orders.exclusions is null) AND (customer_orders.extras IN('', 'null') OR customer_orders.extras is null) THEN 1
                                            ELSE 0
                                        END) AS nb_pizza_delivered_not_change, 
        SUM(CASE
                WHEN  (customer_orders.exclusions IN('', 'null') OR customer_orders.exclusions is null) AND (customer_orders.extras IN('', 'null') OR customer_orders.extras is null) THEN 0
                ELSE 1
            END) AS nb_pizza_delivered_change        
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
WHERE (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null) 
GROUP BY customer_orders.customer_id;
```
### 8. How many pizzas were delivered that had both exclusions and extras?

Pour savoir le nombre total de pizzas livrées qui ont à la fois des exclusions et des extras; nous avons:

- Vérifier si la livraison a été effectuée en faisant une jointure entre les tables `customer_orders` et `runner_orders`
- Compter les pizzas avec exclusions et  extra(`nb_pizza_delivered_change`) en utlisant `sum()`. 
```sql
SELECT SUM(CASE
                WHEN  (customer_orders.exclusions not IN('', 'null') AND customer_orders.exclusions is not null) AND (customer_orders.extras not IN('', 'null') AND customer_orders.extras is not null) THEN 1
                ELSE 0
            END) AS nb_pizza_delivered_change      
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id= runner_orders.order_id
WHERE (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null);
```

### 9. What was the total volume of pizzas ordered for each hour of the day?

Pour avoir combien de pizzas ont été commandées à chaque heure de chaque jour; nous avons:

- Récupère seulement la date en ignorant l’heure et les minutes en utilisant `date()`
- récupèrer l’heure ( de 0 à 23) de la commande avec `extract()`
- Compter le nombre total de pizzas commandées à cette date et à cette heure
```sql
SELECT DATE(order_time) AS order_date,
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(customer_orders.pizza_id) AS nb_pizza_ordered
FROM customer_orders
GROUP BY order_date, order_hour
ORDER BY order_date, order_hour;
```

### 10. What was the volume of orders for each day of the week?

Pour savoir  combien de pizzas ont été commandées pour chaque jour de la semaine, en distinguant le mois et la semaine du mois; nous avons:

- récupèrer le mois de la commande avec `to_chart()`
- récupèrer la semaine ( de 1 à 4) de la commande avec `extract()`
- récupèrer le jour de la commande avec `to_chart()`
- compter le nombre de pizzas commandées avec `count()`
```sql
SELECT TO_CHAR(order_time, 'Month') AS order_month, 
    EXTRACT(WEEK FROM order_time) AS order_week,
    TO_CHAR(order_time, 'Day') AS day_of_week,
    COUNT(pizza_id) AS nb_pizza_ordered
FROM customer_orders
GROUP BY order_month, order_week, day_of_week
ORDER BY order_month, order_week, day_of_week DESC;
```