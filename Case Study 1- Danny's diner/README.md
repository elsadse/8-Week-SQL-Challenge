# Case Study 1 - Danny's Diner

## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

- `sales`
- `menu`
- `members`

You can inspect the entity relationship diagram and example data below.

![Danny's Diner Entity Relationship Diagram](./../Images/Danny's%20Diner.png)

## Solutions of Case Study Questions

### 1.What is the total amount each customer spent at the restaurant?

Pour obtenir le montant total dépensé par chaque client au restaurant, je dois d'abord récupérer toutes les ventes à partir de la table `ventes`et obtenir le prix de chaque vente à partir de la table `menu` à l'aide d'une jointure gauche. Ensuite, j'agrégé le prix en appliquant la fonction sum() pour obtenir le montant total dépensé par chaque client.

Si, lors de la jointure, un produit vendu n'a pas de prix dans la table `menu`, je le définis à 0.

```sql
select
    sales.customer_id
    , sum(
        case
            when menu.price is null then 0
            else menu.price
        end
    ) as total_amount
from sales
left join menu
	on menu.product_id = sales.product_id
group by sales.customer_id
;
```

### 2. How many days has each customer visited the restaurant?

Pour obtenir le nombre de jours pendant lesquels chaque client s'est rendu au restaurant, nous récupérons la date de vente dans le tableau des ventes et comptons le nombre de dates distinctes (car un client peut se rendre au restaurant plusieurs fois par jour) pour chaque client.
```sql
select
    sales.customer_id
    , count(distinct sales.order_date) as number_of_dates
from sales
group by sales.customer_id
;
```

### 3. What was the first item from the menu purchased by each customer?

Pour déterminer le premier plat acheté par chaque client, nous avons :

- Identifier la première date d'achat de chaque client en aggrégeant `sales.order_date` avec la fonction `min()` 
- Rassembler toutes les ventes avec les noms des produit en faisant une jointure sur les tables `menu` et `sales`
- Afficher le nom du plat acheté lors de cette première visite.
On utilise deux CTE (Common Table Expressions) pour structurer la solution :
```sql
WITH
cte1 AS (SELECT customer_id, MIN(order_date) AS o_date
			FROM sales
			GROUP BY customer_id),
cte2 AS (SELECT sales.product_id, menu.product_name, sales.customer_id, sales.order_date
			FROM sales
			JOIN menu ON sales.product_id= menu.product_id)
SELECT cte1.customer_id, cte2.product_name, cte2.product_id
FROM cte1
JOIN cte2 ON cte1.customer_id= cte2.customer_id AND cte1.o_date=cte2.order_date;
```

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

Pour savoir quel produit a été acheté le plus de fois et combien de fois, nous avons:

- Compter le nombre de fois que chaque produit a été acheté en aggrégeant `sales.produit_id` avec la fonction count()
- Récupérer les noms des produits dans la table `menu`
- afficher le produit le plus populaire et son nombre d’achats.
```sql
WITH
cte1 AS (SELECT product_id, COUNT(product_id) as nb_time 
         FROM sales 
         GROUP BY product_id),
cte2 AS (SELECT product_id, product_name 
         FROM menu)
SELECT cte1.product_id, cte2.product_name, cte1.nb_time
FROM cte1  
JOIN cte2 ON cte1.product_id = cte2.product_id
ORDER BY cte1.nb_time DESC
LIMIT 1;
```

### 5. Which item was the most popular for each customer?

Pour savoir pour chaque client, quel produit a été acheté le plus de fois; nous avons:

- Compter le nombre d’achats pour chaque produit par client. avec la fonction `count()` 
- Trouver le nombre maximal d’achats par client en utilisant la fonction `max()` sur le nombre d’achats pour chaque produit par client
- Sélectionner le produit correspondant au maximum d’achats
```sql
WITH 
cte AS (
  SELECT customer_id, product_id, COUNT(product_id) as nb_time 
  FROM sales 
  GROUP BY customer_id, product_id),
cte2 AS (
  SELECT customer_id , MAX(nb_time) as max_nb_time
  FROM cte
  GROUP BY customer_id)
SELECT cte2.customer_id, cte.product_id, menu.product_name, cte2.max_nb_time
FROM cte
JOIN cte2 ON cte.customer_id= cte2.customer_id AND cte.nb_time= cte2.max_nb_time
JOIN menu ON menu.product_id= cte.product_id;
```

### 6. Which item was purchased first by the customer after they became a member?

savoir quel produit chaque client a acheté en premier après être devenu membre; nous avons:

- Filtrer les achats après la date d’adhésion
- Récupérer le nom du produit en faisant une jointure des tables `menu` et `sales`
- Classer les achats par date pour chaque client avec la fonction de fenêtrage `row_number()`
- Sélectionner uniquement le premier achat avec `rn=1`
```sql
WITH 
cte AS (SELECT sales.customer_id, menu.product_name, sales.product_id,
	ROW_NUMBER() OVER ( PARTITION BY sales.customer_id
                       ORDER BY sales.order_date ASC ) AS rn
	FROM sales
	JOIN members ON sales.customer_id=members.customer_id
	JOIN menu ON sales.product_id= menu.product_id
	WHERE order_date>=join_date)
 
SELECT  cte.customer_id, cte.product_name, cte.product_id
FROM cte 
WHERE cte.rn=1;
```

###7. Which item was purchased just before the customer became a member?

Pour savoir quel produit chaque client a acheté juste avant sa date d’adhésion; c'est le même principe que la commande précédente sauf que nous allons filtrer les achats avant (ou le jour de) la date d’adhésion et classer les achats par date décroissante pour chaque client avec `row_number()`
```sql
WITH 
cte AS (SELECT sales.customer_id, menu.product_name, sales.product_id, sales.order_date,
	ROW_NUMBER() OVER ( PARTITION BY sales.customer_id
                       ORDER BY sales.order_date DESC ) AS rn
	FROM sales
	JOIN members ON sales.customer_id=members.customer_id
	JOIN menu ON sales.product_id= menu.product_id
	WHERE order_date<=join_date)
 
SELECT  cte.customer_id, cte.product_name, cte.product_id
FROM cte 
WHERE cte.rn=1;
```

### 8. What is the total items and amount spent for each member before they became a member?

Pour savoir combien d’articles chaque client membre a acheté avant de devenir membre, et le montant total dépensé; nous avons:

- Récupérer le prix des articles vendus en faisant une jointure entre les tables `sales` et `menu`
- Filtrer uniquement les achats avant l’adhésion
- Compter les articles avec la fonction `count()` et sommer le montant avec la fonction `sum()`
```sql
SELECT sales.customer_id,
COUNT(sales.product_id) AS total_item,
SUM(menu.price) AS total_amount
FROM sales
JOIN members ON sales.customer_id=members.customer_id
JOIN menu ON sales.product_id= menu.product_id
WHERE order_date<=join_date
GROUP BY sales.customer_id;
```

### 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

Pour savoir combien de points chaque client a accumulé selon les règles, nous avons:

- Récupérer le prix de chaque produit en faisant une jointure des tables `sales` et `menu`
- Calculer les points en faisant un `sum()` sur les points . Si menu.product_id=1 alors on double les points(`menu.price*10`)
```sql
SELECT sales.customer_id, SUM (CASE menu.product_id
				                    WHEN 1 THEN menu.price*2*10
				                    ELSE menu.price*10
                                END) AS points
FROM sales
JOIN menu ON sales.product_id= menu.product_id
GROUP BY sales.customer_id;
```

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

Pour savoir combien de points les clients A et B ont accumulé en janvier; nous avons:

- Filtrer les achats effectués en janvier et les clients A et B
- Récupérer la date d’adhésion et le prix de chaque produit
- Calculer les points avec sum(). Au cours de la prémière semaine on double les points; si on commande le produit avec le produit_id 1, on double les points
```sql
SELECT sales.customer_id, SUM (CASE 
				                WHEN sales.order_date>=members.join_date + INTERVAL '6 days' THEN menu.price*2*10
                                WHEN menu.product_id=1 THEN menu.price*2*10
				                ELSE menu.price*10
                            END) AS points
FROM sales
JOIN members ON sales.customer_id=members.customer_id
JOIN menu ON sales.product_id= menu.product_id
WHERE sales.order_date<= '2021-01-31' AND sales.order_date>= '2021-01-01' AND (sales.customer_id='A'OR sales.customer_id='B')
GROUP BY sales.customer_id;
```
