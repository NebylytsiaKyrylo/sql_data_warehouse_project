# SQL Data Warehouse Project Plan

This plan is the execution backbone for the Data Engineering scope of the project.

## 1. Requirements Analysis
- [x] Analyze business objective for a unified analytics foundation
- [x] Identify source systems and formats (CRM CSV + ERP CSV)
- [x] Define project boundaries: latest snapshot only, no historization
- [x] Split scope into:
  - Data Engineering (this repository)
  - BI & Reporting (separate repository)
- [x] Document requirements in [`docs/requirements.md`](requirements.md)

## 2. Data Architecture Design
- [x] Choose Medallion architecture (Bronze/Silver/Gold)
- [x] Define layer responsibilities:
  - Bronze: raw ingestion, no business transformation
  - Silver: cleaning, standardization, validation
  - Gold: star schema for analytics
- [x] Produce architecture and process diagrams:
  - [`docs/data_architecture.drawio`](data_architecture.drawio)
  - [`docs/data_flow.drawio`](data_flow.drawio)
  - [`docs/data_integration.drawio`](data_integration.drawio)
  - [`docs/data_model.drawio`](data_model.drawio)

## 3. Project Initialization
- [x] Prepare repository structure and naming conventions
- [x] Configure environment variables (`.env`, `.env.example`)
- [x] Configure Docker runtime in [`docker-compose.yml`](../docker-compose.yml)
- [x] Bootstrap schemas with [`scripts/init/init_database.sql`](../scripts/init/init_database.sql)
- [x] Mount scripts, datasets, and tests in container (`/workspace/*`)

## 4. Bronze Layer Implementation (Raw)
- [x] Design raw ingestion tables in [`scripts/bronze/ddl_bronze.sql`](../scripts/bronze/ddl_bronze.sql)
- [x] Implement reusable `bronze.load_table(...)` helper
- [x] Implement orchestration procedure `bronze.load_bronze()`
- [x] Load all CRM and ERP files with PostgreSQL `COPY`
- [x] Add runtime telemetry (table-level + batch-level)
- [x] Ensure idempotency with table truncation before load

## 5. Silver Layer Implementation (Cleaned/Standardized)
- [x] Define typed Silver tables in [`scripts/silver/ddl_silver.sql`](../scripts/silver/ddl_silver.sql)
- [x] Implement transformations in [`scripts/silver/proc_load_silver.sql`](../scripts/silver/proc_load_silver.sql)
- [x] Apply key data quality logic:
  - [x] deduplication (`ROW_NUMBER()`)
  - [x] trim + casing normalization
  - [x] regex-driven type safety for IDs/dates
  - [x] value standardization (gender/marital status/product line/country)
  - [x] sales coherence repairs (`sales`, `quantity`, `price`)
  - [x] date fallback rules (order, ship, due dates)
- [x] Ensure idempotent reloads with truncation
- [x] Add runtime telemetry and error handling

## 6. Gold Layer Implementation (Business Model)
- [x] Define star schema DDL in [`scripts/gold/ddl_gold.sql`](../scripts/gold/ddl_gold.sql)
- [x] Build dimensions:
  - [x] `gold.dim_customers`
  - [x] `gold.dim_products`
- [x] Build fact table:
  - [x] `gold.fact_sales`
- [x] Map natural keys to surrogate keys
- [x] Filter to active product records (`prd_end_dt IS NULL`)
- [x] Add batch telemetry and robust exception handling

## 7. Testing and Data Validation
- [x] Implement Silver validations in [`tests/quality_checks_silver.sql`](../tests/quality_checks_silver.sql)
- [x] Implement Gold validations in [`tests/quality_checks_gold.sql`](../tests/quality_checks_gold.sql)
- [x] Validate:
  - [x] null/duplicate key anomalies
  - [x] string hygiene and standardized domains
  - [x] date validity/order constraints
  - [x] referential integrity in star schema
  - [x] lineage checks (row counts and sales totals)

## 8. Documentation and Delivery
- [x] Document technical naming rules in [`docs/naming_conventions.md`](naming_conventions.md)
- [x] Document business model in [`docs/data_catalog.md`](data_catalog.md)
- [x] Publish complete implementation story and runbook in [`README.md`](../README.md)
- [ ] Publish BI continuation project (separate repository)

## 9. Operational Run Order (Quick Checklist)
1. Start Docker database (`docker compose up -d`)
2. Execute Bronze/Silver/Gold DDL files
3. Execute Bronze/Silver/Gold procedure files
4. Run `CALL bronze.load_bronze();`
5. Run `CALL silver.load_silver();`
6. Run `CALL gold.load_gold();`
7. Execute Silver and Gold quality checks
