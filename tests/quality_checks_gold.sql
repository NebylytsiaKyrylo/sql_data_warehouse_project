/*
===============================================================================
Quality Checks: Gold Layer
===============================================================================
Script Purpose:
    This script performs quality checks to ensure the integrity, consistency,
    and business logic of the Gold layer (Star Schema).
    Checks include:
    - Referential Integrity (Fact to Dimensions).
    - Uniqueness of Surrogate Keys.
    - Data Volume Consistency (Silver vs Gold).

Usage Notes:
    - Run these checks after executing gold.load_gold().
===============================================================================
*/

-- ====================================================================
-- 1. Checking 'gold.dim_customers'
-- ====================================================================

-- Check for NULLs or Duplicates in Surrogate Key (customer_key)
-- Expectation: 0 Results
SELECT
    customer_key,
    COUNT(*)
FROM gold.dim_customers
GROUP BY
    customer_key
HAVING
     COUNT(*) > 1
  OR customer_key IS NULL;

-- Data Lineage Check: Silver vs Gold
-- Expectation: Total count should match silver.crm_cust_info
SELECT
    'silver.crm_cust_info' AS table_name,
    COUNT(*) AS cnt
FROM silver.crm_cust_info
UNION ALL
SELECT
    'gold.dim_customers' AS table_name,
    COUNT(*) AS cnt
FROM gold.dim_customers;


-- ====================================================================
-- 2. Checking 'gold.dim_products'
-- ====================================================================

-- Check for NULLs or Duplicates in Surrogate Key (product_key)
-- Expectation: 0 Results
SELECT
    product_key,
    COUNT(*)
FROM gold.dim_products
GROUP BY
    product_key
HAVING
     COUNT(*) > 1
  OR product_key IS NULL;

-- Check for Data Integrity: Ensure all products from Silver are present
-- Expectation: 0 Results
SELECT
    pri.prd_key
FROM silver.crm_prd_info AS pri
         LEFT JOIN gold.dim_products AS dp ON pri.prd_key = dp.product_number
WHERE
    dp.product_key IS NULL;

-- Data Lineage Check: Silver vs Gold
-- Expectation: Gold count should be less than or equal to Silver
-- (due to 'prd_end_dt IS NULL' filter for current version only)
SELECT
    'silver.crm_prd_info' as table_name,
    count(*) as cnt
FROM silver.crm_prd_info
UNION ALL
SELECT
    'gold.dim_products' as table_name,
    count(*) as cnt
FROM gold.dim_products;


-- ====================================================================
-- 3. Checking 'gold.fact_sales' (Referential Integrity)
-- ====================================================================

-- Check for orphaned sales (Sales with no matching Customer)
-- Expectation: 0 Results
SELECT
    COUNT(*) AS orphaned_sales_customers
FROM gold.fact_sales f
         LEFT JOIN gold.dim_customers d ON f.customer_key = d.customer_key
WHERE
    d.customer_key IS NULL;

-- Check for orphaned sales (Sales with no matching Product)
-- Expectation: 0 Results
SELECT
    COUNT(*) AS orphaned_sales_products
FROM gold.fact_sales f
         LEFT JOIN gold.dim_products d ON f.product_key = d.product_key
WHERE
    d.product_key IS NULL;

-- Check for Data Consistency: Sales totals
-- Expectation: Should match exactly with silver.crm_sales_details
SELECT
    'silver.crm_sales_details' AS table_name,
    SUM(sls_sales) AS total_sales
FROM silver.crm_sales_details
UNION ALL
SELECT
    'gold.fact_sales' AS table_name,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales;