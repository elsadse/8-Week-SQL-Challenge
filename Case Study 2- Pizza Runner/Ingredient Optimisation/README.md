You can inspect the entity relationship diagram and example data below.
[Pizza Runner Entity Relationship Diagram](./../../Images/Pizza%20Runner.png)

## Solutions of Case Study Questions Pizza Runner

### 1. What are the standard ingredients for each pizza?

Pour obtenir la liste des ingrédients standards pour chaque type de pizza, on transforme la liste d’ID (pizza_recipes.toppings) en noms d’ingrédients lisibles.

On convertit les chaine de pizza_recipes.toppings en tableau d’entiers grace à `string_to_array` et enfin on vérifie si chaque topping_id du tableau correspond à un ID dans pizza_toppings
```sql
select pizza_names.pizza_id, pizza_names.pizza_name, pizza_recipes.toppings, STRING_AGG(pizza_toppings.topping_name, ', ') AS standard_ingredients
from pizza_recipes
join pizza_names on pizza_recipes.pizza_id = pizza_names.pizza_id
join pizza_toppings on pizza_toppings.topping_id = ANY(string_to_array(pizza_recipes.toppings, ',')::int[])
group by pizza_names.pizza_id, pizza_names.pizza_name, pizza_recipes.toppings
;
```

### 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

alculer le temps moyen en minutes qu’il a fallu à chaque livreur pour arriver au Pizza Runner HQ et récupérer la commande; on a:

- Filtrer les commandes annulées 
-Calculer la différence entre le moment où la commande a été passée (order_time) et le moment où le livreur a récupéré la pizza (pickup_time)
- Convertir cette différence en minutes avec EXTRACT(EPOCH FROM (...)) / 60
- Calculer la moyenne par livreur en utilisant AVG()
```sql
select runner_orders.order_id,  avg(EXTRACT(EPOCH FROM (pickup_time::timestamp - order_time::timestamp)) / 60) as avg_minutes_to_pickup
from runner_orders
join customer_orders on runner_orders.order_id= customer_orders.order_id
where (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
group by runner_orders.order_id
order by  runner_orders.order_id asc;
```

### 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?

Pour savoir s’il y a une relation entre le nombre de pizzas commandées et le temps nécessaire pour préparer la commande, nous avons :

- Filtrer les commandes annulées 
- Compter le nombre de pizzas par commande avec COUNT(customer_orders.pizza_id)
- Convertir le champ duration (texte comme '32 minutes') en minutes numériques avec :
`CAST(REGEXP_REPLACE(runner_orders.duration, '[^0-9]', '', 'g') AS INTEGER)
`. Cela enlève tous les caractères non numériques et garde uniquement le chiffre (le nombre de minutes).
- Calculer la moyenne du temps de préparation par commande avec AVG()
- Grouper les résultats par order_id pour avoir une ligne par commande
- Trier par order_id pour une lecture claire
```sql
select customer_orders.order_id, count(customer_orders.pizza_id) as nb_pizza, AVG(CAST(REGEXP_REPLACE(runner_orders.duration, '[^0-9]', '', 'g') AS INTEGER)) as duration_minutes
from customer_orders
join runner_orders on customer_orders.order_id= runner_orders.order_id
where (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
group by customer_orders.order_id
order by  customer_orders.order_id asc;
```

### 4. What was the average distance travelled for each customer?

Pour savoir  le nombre total de pizzas de chaque type qui ont été  livrées; nous avons:

- Vérifier si la livraison a été effectuée en faisant une jointure entre les tables `customer_orders` et `runner_orders`
-  Obtenir le nom de la pizza et de gérer les pizzas non reconnues en faisant une jointure à gauche entre les tables `customer_orders` et `pizza_names`
- Filtrer les livraison qui n'ont pas été annulées
```sql
select customer_orders.customer_id, AVG(CAST(REGEXP_REPLACE(runner_orders.distance, '[^0-9]', '', 'g') AS NUMERIC)) as avg_distance
from customer_orders
join runner_orders on customer_orders.order_id= runner_orders.order_id
where (runner_orders.cancellation  = 'null' OR runner_orders.cancellation = '' OR runner_orders.cancellation is null)
group by customer_orders.customer_id
order by  customer_orders.customer_id asc;
```

### 5.How many Vegetarian and Meatlovers were ordered by each customer?

Pour savoir la distance moyenne parcourue pour livrer les commandes de chaque client, nous avons :

- Filtrer les commandes annulées (cancellation IS NULL ou vide ou 'null')
- Convertir le champ distance (texte comme '20km' ou '23.4 km') en valeur numérique avec `CAST(REGEXP_REPLACE(runner_orders.distance, '[^0-9]', '', 'g') AS NUMERIC)`. Cela enlève tous les caractères non numériques pour garder uniquement le chiffre (la distance en km)
- Calculer la moyenne de distance par client avec AVG()
- Grouper les résultats par customer_id pour avoir une ligne par client
- Trier par customer_id pour une lecture claire
```sql
SELECT customer_orders.customer_id, pizza_names.pizza_name, COUNT(customer_orders.pizza_id) AS nb_pizza_ordered
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id=pizza_names.pizza_id
WHERE pizza_name IN ('Vegetarian','Meatlovers')
GROUP BY customer_orders.customer_id, pizza_names.pizza_name;
```

### 6. What was the maximum number of pizzas delivered in a single order?

Pour savoir l’écart entre le temps de livraison le plus long et le plus court pour toutes les commandes livrées avec succès.

- Filtrer les commandes annulées (cancellation IS NULL, vide ou 'null')
- Extraire la valeur numérique du champ duration (qui contient un texte comme '32 minutes') avec `CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS INTEGER)`. Calculer la différence entre le temps maximum (MAX) et minimum (MIN) pour toutes les commandes
- Le résultat montre la plage des temps de livraison (en minutes)
```sql
SELECT (MAX(CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS INTEGER)) -MIN(CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS INTEGER))) AS delivery_time_range
FROM runner_orders
WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null';

```

### 7. What was the average speed for each runner for each delivery and do you notice any trend for these values?


```sql
SELECT runner_id, order_id, (CAST(REGEXP_REPLACE(distance, '[^0-9]', '', 'g') AS NUMERIC)/CAST(REGEXP_REPLACE(duration, '[^0-9]', '', 'g') AS NUMERIC)) AS avg_speed_km_per_minute
FROM runner_orders
WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null'
order by runner_id, order_id;
```
### 8. What is the successful delivery percentage for each runner?

 
```sql
WITH total AS (
    SELECT runner_id, COUNT(*) AS total_orders
    FROM runner_orders
    GROUP BY runner_id
),
success AS (
    SELECT runner_id, COUNT(*) AS successful_orders
    FROM runner_orders
    WHERE cancellation IS NULL OR cancellation = '' OR cancellation = 'null'
    GROUP BY runner_id
)
SELECT 
    total.runner_id,
    ROUND(success.successful_orders * 100.0 / total.total_orders, 2) AS success_rate
FROM total 
JOIN success  ON total.runner_id = success.runner_id;
```
