/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT
    *
FROM silver.crm_cust_info
LIMIT 10;

SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY
    cst_id
HAVING
     COUNT(*) > 1
  OR cst_id IS NULL;

SELECT
    cst_create_date
FROM silver.crm_cust_info
WHERE
    cst_create_date IS NULL;


-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT
    cst_key
FROM silver.crm_cust_info
WHERE
    cst_key != TRIM(cst_key);

SELECT
    cst_firstname
FROM silver.crm_cust_info
WHERE
    cst_firstname != TRIM(cst_firstname);

SELECT
    cst_lastname
FROM silver.crm_cust_info
WHERE
    cst_lastname != TRIM(cst_lastname);

-- Data Standardization & Consistency
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;

-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT
    *
FROM silver.crm_prd_info
LIMIT 10;

SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY
    prd_id
HAVING
     COUNT(*) > 1
  OR prd_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE
    prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Values in Cost
-- Expectation: No Results
SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE
     prd_cost IS NULL
  OR prd_cost < 0;

-- Data Standardization & Consistency
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- Check for Invalid Date Orders (Start Date > End Date)
-- Expectation: No Results
SELECT
    *
FROM silver.crm_prd_info
WHERE
    prd_start_dt > prd_end_dt;

-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================

SELECT
    *
FROM silver.crm_sales_details;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT
    *
FROM silver.crm_sales_details
WHERE
    sls_ord_num IS NULL;

SELECT
    *
FROM silver.crm_sales_details
WHERE
    sls_prd_key IS NULL;

SELECT
    *
FROM silver.crm_sales_details
WHERE
    sls_cust_id IS NULL;

-- Check for Invalid Dates
-- Expectation: No Invalid Dates
SELECT
    *
FROM silver.crm_sales_details
WHERE
    sls_order_dt IS NULL;

SELECT
    *
FROM silver.crm_sales_details
WHERE
    sls_ship_dt IS NULL;

SELECT
    *
FROM silver.crm_sales_details
WHERE
    sls_due_dt IS NULL;

-- Check for Invalid Date Orders (Order Date > Shipping/Due Dates)
-- Expectation: No Results
SELECT
    *
FROM silver.crm_sales_details
WHERE
     sls_order_dt > sls_ship_dt
  OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE
     sls_sales IS NULL
  OR sls_quantity IS NULL
  OR sls_price IS NULL
  OR sls_sales <= 0
  OR sls_quantity <= 0
  OR sls_price <= 0
  OR sls_sales != sls_quantity * sls_price
  OR sls_price != sls_sales / sls_quantity;

-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================

SELECT
    *
FROM silver.erp_cust_az12
LIMIT 10;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT
    *
FROM silver.erp_cust_az12
WHERE
    cid IS NULL;

-- Check for Duplicates in CID
-- Expectation: No Results
SELECT
    cid,
    COUNT(*)
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;

-- Identify prefix of CID to check for consistency
SELECT DISTINCT
    SUBSTRING(cid FROM '^[A-Za-z]+') AS prefixe,
    COUNT(*) AS nombre_de_lignes,
    MIN(cid) AS exemple_complet
FROM silver.erp_cust_az12
GROUP BY
    1
ORDER BY
    2 DESC;

-- Check for Invalid bdates
-- Expectation: No Results
SELECT
    bdate
FROM silver.erp_cust_az12
WHERE
     bdate < '1900-01-01'
  OR bdate > CURRENT_DATE;

-- Data Standardization & Consistency
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;

-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================

SELECT
    *
FROM silver.erp_loc_a101
LIMIT 10;

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT
    cid
FROM silver.erp_loc_a101
WHERE cid is NULL;

SELECT
    cid,
    count(*) as cnt_doubles
FROM silver.erp_loc_a101
GROUP BY cid
HAVING count(*) > 1
ORDER BY cnt_doubles;

-- Identify prefix of CID to check for consistency
SELECT
    substring(cid from '^[a-zA-Z-]+') as prefix,
    count(*) as cnt,
    min(cid) as exemple_cid
FROM silver.erp_loc_a101
GROUP BY 1
ORDER BY 2;

-- Data Standardization & Consistency
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101;

