/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- join, data integration (check and choose columns), rename columns
-- =============================================================================
DROP VIEW IF EXISTS gold.dim_customers;
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- surrogate key
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the primary source for gender
        ELSE cb.gen -- Fallback to ERP data
    END AS gender,
    cb.bdate AS birthdate,
    ci.cst_marital_status AS marital_status,
    cl.cntry AS country,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
         LEFT JOIN silver.erp_cust_az12 AS cb ON ci.cst_key = cb.cid
         LEFT JOIN silver.erp_loc_a101 AS cl ON ci.cst_key = cl.cid;

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
DROP VIEW IF EXISTS gold.dim_products;
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pri.prd_start_dt, pri.prd_key) AS product_key,
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
         LEFT JOIN silver.erp_px_cat_g1v2 AS pc ON pri.prd_cat_id = pc.id;

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
DROP VIEW IF EXISTS gold.fact_sales;
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details AS sd
         LEFT JOIN gold.dim_customers AS dc ON sd.sls_cust_id = dc.customer_id
         LEFT JOIN gold.dim_products AS dp ON sd.sls_prd_key = dp.product_number;