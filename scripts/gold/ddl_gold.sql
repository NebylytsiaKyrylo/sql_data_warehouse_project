/*
===============================================================================
DDL Script: Create Gold Tables
===============================================================================
Script Purpose:
    This script creates tables for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema).
    Run this script to re-define the DDL structure of 'gold' Tables.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
DROP TABLE IF EXISTS gold.dim_customers;
CREATE TABLE gold.dim_customers (
    customer_key    SERIAL PRIMARY KEY,
    customer_id     INT,
    customer_number TEXT,
    first_name      TEXT,
    last_name       TEXT,
    gender          TEXT,
    birthdate       DATE,
    marital_status  TEXT,
    country         TEXT,
    create_date     DATE,
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
DROP TABLE IF EXISTS gold.dim_products;
CREATE TABLE gold.dim_products (
    product_key     SERIAL PRIMARY KEY,
    product_id      INT,
    product_number  TEXT,
    product_name    TEXT,
    category_id     TEXT,
    category        TEXT,
    subcategory     TEXT,
    product_line    TEXT,
    cost            NUMERIC,
    maintenance     TEXT,
    start_date      DATE,
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
DROP TABLE IF EXISTS gold.fact_sales;
CREATE TABLE gold.fact_sales (
    order_number    TEXT,
    product_key     INT,
    customer_key    INT,
    order_date      DATE,
    shipping_date   DATE,
    due_date        DATE,
    sales_amount    NUMERIC,
    quantity        INT,
    price           NUMERIC,
    dwh_create_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);