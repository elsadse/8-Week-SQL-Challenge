## Context
Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks

Pour exécuter et avoir le rapport pour un autre mois ou année, il faut remplacer les valeur de `report_month` par le mois que vous le souhaitez (2 pour février,...) et `report_year` par l'année voulu

```sql
DO $$ 
DECLARE 
    report_month INT := 1;  -- 1 pour le mois de janvier
    report_year  INT := 2021; -- 2021 pour l'année 2021
    -- Initialisation des variables
    v_total_revenue_before_discount NUMERIC;
    v_total_discount_amount NUMERIC; 
    v_total_revenue_after_discount NUMERIC;
    v_total_quantity_sold NUMERIC;
BEGIN
    -- Calcul et stockage des valeurs dans les variables
    SELECT 
        SUM(qty),
        ROUND (SUM(qty * price), 2),
        ROUND (SUM(qty * price * discount / 100.0), 2)
    INTO 
        v_total_quantity_sold, 
        v_total_revenue_before_discount, 
        v_total_discount_amount
    FROM balanced_tree.sales
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month 
      AND EXTRACT(YEAR FROM start_txn_time) = report_year;

    -- 1. High Level Sales Analysis
    DROP TABLE IF EXISTS final_report_sales_analysis;
    CREATE TABLE final_report_sales_analysis AS
    SELECT 
        report_month AS month,
        report_year AS year,
        v_total_quantity_sold AS total_quantity_sold,
        v_total_discount_amount AS total_discount_amount,
        v_total_revenue_before_discount AS total_revenue_before_discount;
END $$;

-- Vérification du résultat
SELECT * FROM final_report_sales_analysis;

```