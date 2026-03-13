DO $$ 
DECLARE 
    report_month INT := 1;  -- 1 pour le mois de janvier
    report_year  INT := 2021; -- 2021 pour l'année 2021
    
    -- Variables High Level Sales Analysis
    v_total_revenue_before_discount NUMERIC;
    v_total_discount_amount NUMERIC; 
    v_total_quantity_sold NUMERIC;
    
    -- Variables Transaction Analysis
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
        
   -- 2. Base de données temporaire pour Transaction Analysis
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
    
    -- 3. Table report pour Transaction Analysis
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
    
    -- Tables pour Product Analysis 
    
    -- 1
    DROP TABLE IF EXISTS product_analysis_1;
    CREATE TABLE product_analysis_1 AS
    SELECT 
    	p.product_id,
      	p.product_name,
      	SUM(s.qty * s.price) AS total_revenue_before_discount
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY p.product_id, p.product_name
    ORDER BY total_revenue_before_discount DESC
    LIMIT 3;
    
    -- 2
    DROP TABLE IF EXISTS product_analysis_2;
    CREATE TABLE product_analysis_2 AS
    SELECT
      pd.segment_name,
      SUM(s.qty) AS total_quantity,
      SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
      ROUND(SUM(s.qty * s.price * s.discount / 100), 2) AS total_discount_amount
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY pd.segment_name;
    
    -- 3
    DROP TABLE IF EXISTS product_analysis_3;
    CREATE TABLE product_analysis_3 AS
    WITH product_revenue AS (
      SELECT 
          pd.segment_name,
          pd.product_name,
          SUM(s.qty ) AS total_quantity,
          RANK() OVER (PARTITION BY pd.segment_name ORDER BY SUM(s.qty) DESC) AS rn
      FROM balanced_tree.sales s
      JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
      WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
      GROUP BY pd.segment_name, pd.product_name
    )
    SELECT segment_name, product_name, total_quantity
    FROM product_revenue
    WHERE rn = 1;
    
    -- 4
    DROP TABLE IF EXISTS product_analysis_4;
    CREATE TABLE product_analysis_4 AS
    SELECT
      pd.category_id,
      pd.category_name,
      SUM(s.qty) AS total_quantity,
      SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
      ROUND(SUM(s.qty * s.price * s.discount / 100), 2) AS total_discount_amount
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY pd.category_id, pd.category_name;
    
    -- 5
    DROP TABLE IF EXISTS product_analysis_5;
    CREATE TABLE product_analysis_5 AS
    WITH product_revenue AS (
      SELECT 
          pd.category_name,
          pd.product_name,
          SUM(s.qty ) AS total_quantity,
          RANK() OVER (PARTITION BY pd.category_name ORDER BY SUM(s.qty) DESC) AS rn
      FROM balanced_tree.sales s
      JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
      WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
      GROUP BY pd.category_name, pd.product_name
    )
    SELECT category_name, product_name, total_quantity
    FROM product_revenue
    WHERE rn = 1;
    
    -- 6
    DROP TABLE IF EXISTS product_analysis_6;
    CREATE TABLE product_analysis_6 AS
    SELECT 
      pd.segment_name,
      pd.product_name,
      SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
      ROUND(100.0 * SUM((s.qty * s.price) * (1 - s.discount / 100)) / SUM(SUM((s.qty * s.price) * (1 - s.discount / 100))) OVER (PARTITION BY pd.segment_name), 2) AS pct_of_segment_revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY pd.segment_name, pd.product_name;
    
    -- 7
    DROP TABLE IF EXISTS product_analysis_7;
    CREATE TABLE product_analysis_7 AS
    SELECT 
      pd.segment_name,
      pd.category_name,
      SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
      ROUND(100.0 * SUM((s.qty * s.price) * (1 - s.discount / 100)) / SUM(SUM((s.qty * s.price) * (1 - s.discount / 100))) OVER (PARTITION BY pd.category_name), 2) AS pct_of_segment_revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY pd.category_name, pd.segment_name;
    
    -- 8
    DROP TABLE IF EXISTS product_analysis_8;
    CREATE TABLE product_analysis_8 AS
    SELECT 
      pd.category_name,
      SUM((s.qty * s.price) * (1 - s.discount / 100)) AS revenue_after_discount,
      ROUND(100.0 * SUM((s.qty * s.price) * (1 - s.discount / 100)) / SUM(SUM((s.qty * s.price) * (1 - s.discount / 100))) OVER (), 2) AS pct_of_category_revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY pd.category_name;
    
    -- 9
    DROP TABLE IF EXISTS product_analysis_9;
    CREATE TABLE product_analysis_9 AS
    WITH total_txns AS (
    	SELECT COUNT(DISTINCT txn_id) AS total FROM balanced_tree.sales
      	WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
	)
    SELECT
        pd.product_id,
        pd.product_name,
        ROUND(100.0 * COUNT(DISTINCT s.txn_id) / tt.total, 2) AS penetration_percentage
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
    CROSS JOIN total_txns tt
    WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
    GROUP BY pd.product_name, pd.product_id, tt.total
	ORDER BY penetration_percentage DESC;
    
    -- 10
    DROP TABLE IF EXISTS product_analysis_10;
    CREATE TABLE product_analysis_10 AS
    WITH unique_products_per_txn AS (
      SELECT DISTINCT txn_id, prod_id
      FROM balanced_tree.sales
      WHERE EXTRACT(MONTH FROM start_txn_time) = report_month AND EXTRACT(YEAR FROM start_txn_time) = report_year
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
    
    
END $$;