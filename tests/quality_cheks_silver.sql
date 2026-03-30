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
WHERE cst_create_date is NULL;


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

