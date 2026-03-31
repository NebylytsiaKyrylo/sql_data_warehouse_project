-- Truncating Table: silver.crm_cust_info
TRUNCATE TABLE silver.crm_cust_info;

-- Inserting Data Into: silver.crm_cust_info
INSERT INTO
    silver.crm_cust_info (
                             cst_id,
                             cst_key,
                             cst_firstname,
                             cst_lastname,
                             cst_marital_status,
                             cst_gndr,
                             cst_create_date
                         )
WITH
    crm_cust_info_dedup AS (
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
INSERT INTO
    silver.crm_prd_info(
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



