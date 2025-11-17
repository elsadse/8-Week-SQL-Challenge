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

[Danny's Diner Entity Relationship Diagram](./../Images/Danny's%20Diner.png)

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