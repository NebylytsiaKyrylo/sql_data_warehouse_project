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
    r_num = 1; -- Select the most recent record per customer
