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
    
    -- Initialisation des variables High Level Sales Analysis
    v_total_revenue_before_discount NUMERIC;
    v_total_discount_amount NUMERIC; 
    v_total_quantity_sold NUMERIC;
    
    -- Initialisation Variables Transaction Analysis
    v_unique_txns INT;
    v_avg_unique_prods_txn NUMERIC;
    v_p25 NUMERIC; v_p50 NUMERIC; v_p75 NUMERIC;
    v_avg_discount_txn NUMERIC;
    v_pct_member NUMERIC; v_pct_non_member NUMERIC;
    v_rev_member NUMERIC; v_rev_non_member NUMERIC;
BEGIN
    -- Remplissage des variables pour High Level Sales Analysis
    SELECT 
        SUM(qty),
        ROUND (SUM(qty * price), 2),
        ROUND (SUM(qty * price * discount / 100.0), 2)
    INTO v_total_quantity_sold, v_total_revenue_before_discount, v_total_discount_amount
    FROM balanced_tree.sales
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month 
      AND EXTRACT(YEAR FROM start_txn_time) = report_year;

    -- 1. Table report pour  High Level Sales Analysis
    DROP TABLE IF EXISTS final_report_sales_analysis;
    CREATE TABLE final_report_sales_analysis AS
    SELECT 
        report_month AS month,
        report_year AS year,
        v_total_quantity_sold AS total_quantity_sold,
        v_total_discount_amount AS total_discount_amount,
        v_total_revenue_before_discount AS total_revenue_before_discount;
        
   -- Base de données temporaire pour Transaction Analysis
    CREATE TEMP TABLE txn_metrics AS
    SELECT 
        txn_id, 
        member,
        COUNT(DISTINCT prod_id) AS prod_count,
        SUM((qty * price) * (1 - discount / 100)) AS revenue_after_discount_txn,
        SUM(qty * price * discount / 100.0) AS discount_amount_txn
    FROM balanced_tree.sales
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY txn_id, member;

    -- Calculs unitaires et remplissage de variables pour Transaction Analysis
    SELECT COUNT(txn_id) INTO v_unique_txns FROM txn_metrics;
    SELECT ROUND(AVG(prod_count), 2) INTO v_avg_unique_prods_txn FROM txn_metrics;
    SELECT ROUND(AVG(discount_amount_txn), 2) INTO v_avg_discount_txn FROM txn_metrics;
    
    -- Percentiles et remplissage de variables pour Transaction Analysis
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue_after_discount_txn),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue_after_discount_txn),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue_after_discount_txn)
    INTO v_p25, v_p50, v_p75 FROM txn_metrics;
    
    -- Split Members vs Non-Members (%) et remplissage de variables pour Transaction Analysis
    SELECT 
        ROUND(100.0 * COUNT(*) FILTER (WHERE member = true) / COUNT(*), 2),
        ROUND(100.0 * COUNT(*) FILTER (WHERE member = false) / COUNT(*), 2)
    INTO v_pct_member, v_pct_non_member FROM txn_metrics;
    
    -- Revenu moyen par type de membre et remplissage de variables pour Transaction Analysis
    SELECT ROUND(AVG(revenue_after_discount_txn), 2) INTO v_rev_member FROM txn_metrics WHERE member = true;
    SELECT ROUND(AVG(revenue_after_discount_txn), 2) INTO v_rev_non_member FROM txn_metrics WHERE member = false;
    
    -- 2. Table report pour Transaction Analysis
    DROP TABLE IF EXISTS final_report_transaction_analysis;
    CREATE TABLE final_report_transaction_analysis (question TEXT, answer TEXT);

    INSERT INTO final_report_transaction_analysis VALUES
    ('Total unique transactions', v_unique_txns::TEXT),
    ('Average unique products per txn', v_avg_unique_prods_txn::TEXT),
    ('Revenue Percentiles (25th, 50th, 75th)', v_p25 || ', ' || v_p50 || ', ' || v_p75),
    ('Average discount value per txn', v_avg_discount_txn::TEXT),
    ('Member vs Non-Member split (%)', v_pct_member || '% vs ' || v_pct_non_member || '%'),
    ('Avgerage Revenue: Member vs Non-Member', v_rev_member || ' vs ' || v_rev_non_member);
    
    -- Nettoyage
    DROP TABLE txn_metrics; 
    
    
END $$;
```