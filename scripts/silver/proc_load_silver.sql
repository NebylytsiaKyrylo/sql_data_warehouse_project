-- Truncating Table: silver.crm_cust_info
TRUNCATE TABLE silver.crm_cust_info;

-- Inserting Data Into: silver.crm_cust_info
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
WITH crm_cust_info_dedup AS (
    SELECT
        *,
        ROW_NUMBER()
        OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC, dwh_load_date DESC) AS r_num
    FROM bronze.crm_cust_info
    WHERE
          cst_id IS NOT NULL
      AND TRIM(cst_id) ~ '^[0-9]+$'
                            )

SELECT
    CAST(TRIM(cst_id) AS INT) AS cst_id,
    TRIM(cst_key) AS cst_key,
    INITCAP(TRIM(cst_firstname)) AS cst_firstname,
    INITCAP(TRIM(cst_lastname)) AS cst_lastname,

    CASE
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        ELSE 'n/a'
    END AS cst_marital_status,

    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        ELSE 'n/a'
    END AS cst_gndr,

    CASE
        WHEN TRIM(cst_create_date) ~ '^\d{4}-\d{2}-\d{2}$' THEN CAST(TRIM(cst_create_date) AS DATE)
        ELSE NULL
    END AS cst_create_date

FROM crm_cust_info_dedup
WHERE
    r_num = 1;
-- Select the most recent record per customer


-- Truncating Table: silver.crm_prd_info
TRUNCATE TABLE silver.crm_prd_info;

-- Inserting Data Into: silver.crm_prd_info
INSERT INTO silver.crm_prd_info(
    prd_id,
    prd_cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    CAST(TRIM(prd_id) AS INT) AS prd_id,
    REPLACE(LEFT(prd_key, 5), '-', '_') AS prd_cat_id,
    SUBSTR(prd_key, 7) AS prd_key,
    TRIM(prd_nm) AS prd_nm,
    CAST(COALESCE(TRIM(prd_cost), '0') AS NUMERIC) AS prd_cost,

    CASE
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Sport'
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,     -- Map product line codes to descriptive values

    CASE
        WHEN TRIM(prd_start_dt) ~ '^\d{4}-\d{2}-\d{2}$' THEN CAST(TRIM(prd_start_dt) AS DATE)
        ELSE NULL
    END AS prd_start_dt, -- Convert start date to DATE type with regex check

    LEAD(CAST(TRIM(prd_start_dt) AS DATE)) OVER (PARTITION BY prd_key ORDER BY CAST(TRIM(prd_start_dt) AS DATE)) -
    1 AS prd_end_dt      -- Calculate end date as one day before the next start date
FROM bronze.crm_prd_info
WHERE
      prd_id IS NOT NULL
  AND prd_id ~ '^[0-9]+$';

-- Truncating Table: silver.crm_prd_info
TRUNCATE TABLE silver.crm_sales_details;

-- Inserting Data Into: silver.crm_sales_details
INSERT INTO silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
WITH crm_sales_values AS (
    SELECT
        TRIM(sls_ord_num) AS sls_ord_num,
        TRIM(sls_prd_key) AS sls_prd_key,
        CAST(TRIM(sls_cust_id) AS INT) AS sls_cust_id,

        CASE
            WHEN TRIM(sls_order_dt) ~ '^\d{8}$' THEN TO_DATE(sls_order_dt, 'YYYYMMDD')
            ELSE NULL
        END AS sls_order_dt,

        CASE
            WHEN TRIM(sls_ship_dt) ~ '^\d{8}$' THEN TO_DATE(sls_ship_dt, 'YYYYMMDD')
            ELSE NULL
        END AS sls_ship_dt,

        CASE
            WHEN TRIM(sls_due_dt) ~ '^\d{8}$' THEN TO_DATE(sls_due_dt, 'YYYYMMDD')
            ELSE NULL
        END AS sls_due_dt,

        ABS(CAST(COALESCE(NULLIF(TRIM(sls_sales), ''), '0') AS NUMERIC)) AS sls_sales,
        ABS(CAST(COALESCE(NULLIF(TRIM(sls_quantity), ''), '0') AS NUMERIC)) AS sls_quantity,
        ABS(CAST(COALESCE(NULLIF(TRIM(sls_price), ''), '0') AS NUMERIC)) AS sls_price

    FROM bronze.crm_sales_details
                         )
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    CASE
        WHEN sls_order_dt IS NULL THEN sls_ship_dt - INTERVAL '1 day'
        ELSE sls_order_dt
    END AS sls_order_dt,

    CASE
        WHEN sls_ship_dt IS NULL THEN sls_order_dt + INTERVAL '1 day'
        ELSE sls_ship_dt
    END AS sls_ship_dt,

    CASE
        WHEN sls_due_dt IS NULL THEN sls_ship_dt + INTERVAL '5 days'
        ELSE sls_due_dt
    END AS sls_due_dt,

    CASE
        WHEN (sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * sls_price)
            AND (sls_quantity > 0 AND sls_price > 0)
            THEN sls_quantity * sls_price
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    CASE
        WHEN (sls_price IS NULL OR sls_price <= 0 OR sls_price != sls_sales / NULLIF(sls_quantity, 0))
            AND (sls_sales > 0 AND sls_quantity > 0)
            THEN sls_sales / sls_quantity
        ELSE sls_price
    END AS sls_price
FROM crm_sales_values;


-- Truncating Table: silver.erp_cust_az12
TRUNCATE TABLE silver.erp_cust_az12;

-- Inserting Data Into: silver.erp_cust_az12
INSERT INTO silver.erp_cust_az12(
    cid,
    bdate,
    gen
)
WITH erp_cust_az12_values AS (
    SELECT
        TRIM(cid) AS cid,
        TRIM(bdate) AS bdate,
        TRIM(gen) AS gen
    FROM bronze.erp_cust_az12
                             )
SELECT
    REGEXP_REPLACE(cid, '^NAS', '', 'i') AS cid,

    CASE
        WHEN bdate ~ '^\d{4}-\d{2}-\d{2}'
            AND TO_DATE(bdate, 'YYYY-MM-DD') < CURRENT_DATE
            AND TO_DATE(bdate, 'YYYY-MM-DD') > '1900-01-01'
            THEN TO_DATE(bdate, 'YYYY-MM-DD')
    END AS bdate,

    CASE
        WHEN UPPER(gen) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(gen) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM erp_cust_az12_values;

-- Truncating Table: silver.erp_loc_a101
TRUNCATE TABLE silver.erp_loc_a101;

-- Inserting Data Into: silver.erp_loc_a101
INSERT INTO silver.erp_loc_a101(
    cid,
    cntry
)
WITH erp_loc_a101_values AS (
    SELECT
        TRIM(cid) AS cid,
        TRIM(cntry) AS cntry
    FROM bronze.erp_loc_a101
                            )
SELECT
    REPLACE(cid, '-', '') AS cid,
    CASE
        WHEN cntry IS NULL OR cntry = '' THEN 'n/a'
        WHEN UPPER(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN UPPER(cntry) = 'DE' THEN 'Germany'
        ELSE cntry
    END AS cntry
FROM erp_loc_a101_values;
