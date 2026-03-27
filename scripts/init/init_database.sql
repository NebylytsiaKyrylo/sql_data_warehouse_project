/*
=============================================================
Create Database and Schemas (PostgreSQL)
=============================================================
Script Purpose:
    This script creates a new database named 'data_warehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'data_warehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.
*/

-- Drop the 'data_warehouse' database if it exists
DROP DATABASE IF EXISTS data_warehouse;

-- Create the 'data_warehouse' database
CREATE DATABASE data_warehouse;

-- Connect to the new database
\c data_warehouse

-- Create Schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;

-- Grant permissions (optional)
GRANT USAGE ON SCHEMA bronze TO public;
GRANT USAGE ON SCHEMA silver TO public;
GRANT USAGE ON SCHEMA gold TO public;