/*
=============================================================
Initialize Database Schema and Permissions (PostgreSQL)
=============================================================
Script Purpose:
    This script creates the three schemas (bronze, silver, gold)
    within the existing 'data_warehouse' database.
    PostgreSQL automatically creates the database based on 
    the POSTGRES_DB environment variable in docker-compose.yml

WARNING:
    This script assumes the 'data_warehouse' database already exists.
    It will be created automatically by Docker during initialization.
*/

-- Create Schemas (database is already created by PostgreSQL)
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Grant permissions to public role
GRANT USAGE ON SCHEMA bronze TO public;
GRANT USAGE ON SCHEMA silver TO public;
GRANT USAGE ON SCHEMA gold TO public;