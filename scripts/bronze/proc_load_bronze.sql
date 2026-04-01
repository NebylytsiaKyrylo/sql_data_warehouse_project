/*
===============================================================================
Stored Procedure: bronze.load_table
Description: Automates the TRUNCATE -> COPY -> LOG cycle for a specific table.
Script Purpose:
    This helper stored procedure loads data into a specific table in the 'bronze'
    schema from an external CSV file.
    It performs the following actions:
    - Truncates the target table to ensure idempotency.
    - Uses the `COPY` command to rapidly load data from CSV files.
    - Tracks execution time for performance monitoring.

Parameters:
    - p_table_name : Target table name (e.g., 'crm_cust_info')
    - p_file_path  : Absolute path to the source CSV file
    - p_columns    : Comma-separated list of target columns

Usage Example:
    CALL bronze.load_table('crm_cust_info', '/path/to/file.csv', 'col1, col2');
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_table(
    p_table_name TEXT, -- p_ -> parameter
    p_file_path TEXT,
    p_columns TEXT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_start_time TIMESTAMPTZ; -- v_ -> variables
    v_end_time   TIMESTAMPTZ;
    v_duration   NUMERIC;
BEGIN
    v_start_time := CLOCK_TIMESTAMP();

    -- Truncate table to ensure idempotency (clean start for every load)
    -- %I handles identifiers safely, %s is used for the column list string
    RAISE NOTICE '>> Truncating Table: bronze.%', p_table_name;
    EXECUTE FORMAT('TRUNCATE TABLE bronze.%I', p_table_name);

    -- Load data using COPY command
    RAISE NOTICE '>> Inserting Data Into: bronze.%', p_table_name;
    EXECUTE FORMAT('COPY bronze.%I (%s) FROM %L WITH (FORMAT CSV, HEADER, DELIMITER '','')',
                   p_table_name, p_columns, p_file_path);

    v_end_time := CLOCK_TIMESTAMP();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    RAISE NOTICE '>> Load Duration of %: % seconds', p_table_name, v_duration;
    RAISE NOTICE '>> -------------';
END;
$$;


/*
===============================================================================
Stored Procedure: bronze.load_bronze
Description: Orchestrates the full loading process for the Bronze Layer.
Usage Example:
    CALL bronze.load_bronze();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_batch_start_time TIMESTAMPTZ;
    v_batch_end_time   TIMESTAMPTZ;
    v_total_duration   NUMERIC;
    v_error_msg        TEXT;
    v_error_state      TEXT;
BEGIN
    -- Record the start time of the entire batch process
    v_batch_start_time := CLOCK_TIMESTAMP();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '================================================';

    -- ------------------------------------------------
    -- SECTION: CRM Tables
    -- ------------------------------------------------

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';

    CALL bronze.load_table('crm_cust_info',
                           '/workspace/datasets/source_crm/cust_info.csv',
                           'cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date');

    CALL bronze.load_table('crm_prd_info',
                           '/workspace/datasets/source_crm/prd_info.csv',
                           'prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt');

    CALL bronze.load_table('crm_sales_details',
                           '/workspace/datasets/source_crm/sales_details.csv',
                           'sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price');

    -- ------------------------------------------------
    -- SECTION: ERP Tables
    -- ------------------------------------------------

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------------';

    CALL bronze.load_table('erp_cust_az12',
                           '/workspace/datasets/source_erp/CUST_AZ12.csv',
                           'cid, bdate, gen');

    CALL bronze.load_table('erp_loc_a101',
                           '/workspace/datasets/source_erp/LOC_A101.csv',
                           'cid, cntry');

    CALL bronze.load_table('erp_px_cat_g1v2',
                           '/workspace/datasets/source_erp/PX_CAT_G1V2.csv',
                           'id, cat, subcat, maintenance');


    -- Record the end time of the entire batch process
    v_batch_end_time := CLOCK_TIMESTAMP();
    v_total_duration := EXTRACT(EPOCH FROM (v_batch_end_time - v_batch_start_time));

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Bronze Layer is Completed';
    RAISE NOTICE '   - Total Load Duration: % seconds', v_total_duration;
    RAISE NOTICE '==========================================';

-- Error handling block
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT,
            v_error_state = RETURNED_SQLSTATE;

        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        RAISE NOTICE 'Error Message: %', v_error_msg;
        RAISE NOTICE 'SQL State: %', v_error_state;
        RAISE NOTICE '==========================================';
        -- Re-throw the error so the transaction rolls back properly
        RAISE;
END;
$$;

