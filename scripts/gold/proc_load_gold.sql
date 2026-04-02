/*
===============================================================================
Stored Procedure: gold.load_gold
Description:
    Orchestrates the Transformation and Loading (ETL) process from the 'silver'
    layer to the 'gold' layer (Star Schema).
Script Purpose:
    - Integrates data from multiple Silver tables.
    - Maps natural keys to surrogate keys.
    - Ensures idempotency by truncating gold tables before each load.
    - Provides execution telemetry.

Usage Example:
    CALL gold.load_gold();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE gold.load_gold()
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_start_time       TIMESTAMPTZ;
    v_end_time         TIMESTAMPTZ;
    v_duration         NUMERIC;
    v_batch_start_time TIMESTAMPTZ;
    v_batch_end_time   TIMESTAMPTZ;
    v_batch_duration   NUMERIC;
    v_error_msg        TEXT;
    v_error_state      TEXT;
BEGIN
    -- Record the start time of the entire batch process
    v_batch_start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Gold Layer';
    RAISE NOTICE '================================================';

    -- ------------------------------------------------
    -- SECTION: gold.dim_customers
    -- ------------------------------------------------
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading Customer Dimension';
    RAISE NOTICE '------------------------------------------------';
    v_start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating Table: gold.dim_customers';
    TRUNCATE TABLE gold.dim_customers RESTART IDENTITY;

    RAISE NOTICE '>> Inserting Data Into: gold.dim_customers';
    INSERT INTO gold.dim_customers (
        customer_id,
        customer_number,
        first_name,
        last_name,
        gender,
        birthdate,
        marital_status,
        country,
        create_date
    )
    SELECT
        ci.cst_id AS customer_id,
        ci.cst_key AS customer_number,
        ci.cst_firstname AS first_name,
        ci.cst_lastname AS last_name,
        CASE
            WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
            ELSE cb.gen
        END AS gender,
        cb.bdate AS birthdate,
        ci.cst_marital_status AS marital_status,
        cl.cntry AS country,
        ci.cst_create_date AS create_date
    FROM silver.crm_cust_info AS ci
             LEFT JOIN silver.erp_cust_az12 AS cb ON ci.cst_key = cb.cid
             LEFT JOIN silver.erp_loc_a101 AS cl ON ci.cst_key = cl.cid;

    v_end_time := CLOCK_TIMESTAMP();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    RAISE NOTICE '>> Load Duration: % seconds', v_duration;
    RAISE NOTICE '>> -------------';

    -- ------------------------------------------------
    -- SECTION: gold.dim_products
    -- ------------------------------------------------
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading Product Dimension';
    RAISE NOTICE '------------------------------------------------';
    v_start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating Table: gold.dim_products';
    TRUNCATE TABLE gold.dim_products RESTART IDENTITY;

    RAISE NOTICE '>> Inserting Data Into: gold.dim_products';
    INSERT INTO gold.dim_products (
        product_id,
        product_number,
        product_name,
        category_id,
        category,
        subcategory,
        product_line,
        cost,
        maintenance,
        start_date
    )
    SELECT
        pri.prd_id AS product_id,
        pri.prd_key AS product_number,
        pri.prd_nm AS product_name,
        pri.prd_cat_id AS category_id,
        pc.cat AS category,
        pc.subcat AS subcategory,
        pri.prd_line AS product_line,
        pri.prd_cost AS cost,
        pc.maintenance AS maintenance,
        pri.prd_start_dt AS start_date
    FROM silver.crm_prd_info AS pri
             LEFT JOIN silver.erp_px_cat_g1v2 AS pc ON pri.prd_cat_id = pc.id
    WHERE
        prd_end_dt IS NULL; -- Filter SCD Type 1 to avoir duplicate records in fact_sales table;

    v_end_time := CLOCK_TIMESTAMP();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    RAISE NOTICE '>> Load Duration: % seconds', v_duration;
    RAISE NOTICE '>> -------------';

    -- ------------------------------------------------
    -- SECTION: gold.fact_sales
    -- ------------------------------------------------
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading Sales Fact Table';
    RAISE NOTICE '------------------------------------------------';
    v_start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '>> Truncating Table: gold.fact_sales';
    TRUNCATE TABLE gold.fact_sales;

    RAISE NOTICE '>> Inserting Data Into: gold.fact_sales';
    INSERT INTO gold.fact_sales (
        order_number,
        product_key,
        customer_key,
        order_date,
        shipping_date,
        due_date,
        sales_amount,
        quantity,
        price
    )
    SELECT
        sd.sls_ord_num AS order_number,
        dp.product_key AS product_key,
        dc.customer_key AS customer_key,
        sd.sls_order_dt AS order_date,
        sd.sls_ship_dt AS shipping_date,
        sd.sls_due_dt AS due_date,
        sd.sls_sales AS sales_amount,
        sd.sls_quantity AS quantity,
        sd.sls_price AS price
    FROM silver.crm_sales_details AS sd
             LEFT JOIN gold.dim_customers AS dc ON sd.sls_cust_id = dc.customer_id
             LEFT JOIN gold.dim_products AS dp ON sd.sls_prd_key = dp.product_number;

    v_end_time := CLOCK_TIMESTAMP();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    RAISE NOTICE '>> Load Duration: % seconds', v_duration;
    RAISE NOTICE '>> -------------';

    -- Record the end time of the entire batch process
    v_batch_end_time := CLOCK_TIMESTAMP();
    v_batch_duration := EXTRACT(EPOCH FROM (v_batch_end_time - v_batch_start_time));

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Gold Layer is Completed';
    RAISE NOTICE '   - Total Load Duration: % seconds', v_batch_duration;
    RAISE NOTICE '==========================================';

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT,
            v_error_state = RETURNED_SQLSTATE;

        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING GOLD LAYER';
        RAISE NOTICE 'Error Message: %', v_error_msg;
        RAISE NOTICE 'SQL State: %', v_error_state;
        RAISE NOTICE '==========================================';
        RAISE;
END;
$$;