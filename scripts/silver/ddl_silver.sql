/*
===============================================================================
DDL Script: Create silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables
    if they already exist.
    Run this script to re-define the DDL structure of 'silver' Tables
===============================================================================
*/

-- =============================================================================
-- CRM Source Tables
-- =============================================================================

DROP TABLE IF EXISTS silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info
(
    cst_id             INT,
    cst_key            TEXT,
    cst_firstname      TEXT,
    cst_lastname       TEXT,
    cst_marital_status TEXT,
    cst_gndr           TEXT,
    cst_create_date    DATE,

    -- Technical columns
    dwh_create_date      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);