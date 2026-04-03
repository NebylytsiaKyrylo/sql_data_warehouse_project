# SQL Data Warehouse Project

## 1. Building the Data Warehouse (Data Engineering)

### Objective

Develop a modern data warehouse using PostgreSQL to consolidate sales data, enabling analytical reporting and informed
decision-making.

### Specifications

* **Data Sources**: Import data from two source systems (ERP and CRM) provided as CSV files.
* **Data Quality**: Cleanse and resolve data quality issues prior to analysis.
* **Integration**: Combine both sources into a single, user-friendly data model designed for analytical queries.
* **Scope**: Focus on the latest dataset only; historization of data is not required.
* **Documentation**: Provide clear documentation of the data model to support both business stakeholders and analytics
  teams.

## 2. What I Built

I implemented a Medallion-style warehouse with three layers:

- **Bronze**: raw ingestion from CSV (CRM + ERP), minimal assumptions
- **Silver**: cleaned, standardized, deduplicated, validated data
- **Gold**: star schema optimized for analytics (`dim_customers`, `dim_products`, `fact_sales`)

I also added:

- scripted DDL and loading procedures for every layer
- data quality checks for Silver and Gold
- architecture, data flow, integration, and model diagrams
- a data catalog for business-facing tables

## 3. Project Plan I Followed

I've built this detailed project plan:

- [docs/project_plan_sql_DWH.md](docs/project_plan_sql_DWH.md)

Execution phases:

1. Requirements Analysis
2. Data Architecture Design
3. Project Initialization
4. Bronze Layer Implementation (Raw)
5. Silver Layer Implementation (Cleaned/Standardized)
6. Gold Layer Implementation (Business Model)
7. Testing and Data Validation
8. Documentation and Delivery
9. Operational Run Order (Quick Checklist)

## 4. Architecture and Why I Run It in Docker

I run PostgreSQL in a Docker container for reproducibility, portability, and isolation.

Why Docker is important in this project:

- same database version and setup on any machine
- one-command startup for local development
- deterministic mount points for datasets/scripts/tests
- easier onboarding and demonstration
- persistent volume support for data durability across container restarts

Main infrastructure file:

- [docker-compose.yml](docker-compose.yml)

Initialization file:

- [scripts/init/init_database.sql](scripts/init/init_database.sql)

### Architecture Diagram

![Data Architecture](https://github.com/NebylytsiaKyrylo/sql_data_warehouse_project/blob/master/docs/data_architecture.png?raw=true)

- [Open medallion_architecture.md](docs/medallion_architecture.md)

## 5. End-to-End Flow I Implemented

![Data Flow](https://github.com/NebylytsiaKyrylo/sql_data_warehouse_project/blob/master/docs/data_flow.png?raw=true)

### 5.1 From Sources to Bronze (Raw Ingestion)

I ingest CSV files from:

- `datasets/source_crm/`
- `datasets/source_erp/`

In Bronze, I keep source columns as `TEXT` to reduce ingestion risk and preserve raw fidelity.

Scripts used:

- [scripts/bronze/ddl_bronze.sql](scripts/bronze/ddl_bronze.sql)
- [scripts/bronze/proc_load_bronze.sql](scripts/bronze/proc_load_bronze.sql)

What I do in `proc_load_bronze.sql`:

- created helper procedure `bronze.load_table(...)`
- truncate target table before each load (idempotent reruns)
- load with PostgreSQL `COPY` for speed
- log duration per table and total batch duration
- orchestrate full CRM + ERP ingestion via `bronze.load_bronze()`


Once the Bronze layer was completed, I was able to design the **Data Integration** schema to visualize how the different sources (CRM & ERP) connect before moving to the Silver layer.


![Data Integration](https://github.com/NebylytsiaKyrylo/sql_data_warehouse_project/blob/master/docs/data_integration.png?raw=true)


### 5.2 From Bronze to Silver (Cleaning and Standardization)

In Silver, I transform raw data into trusted structured tables.

Scripts used:

- [scripts/silver/ddl_silver.sql](scripts/silver/ddl_silver.sql)
- [scripts/silver/proc_load_silver.sql](scripts/silver/proc_load_silver.sql)

What I implemented in `silver.load_silver()`:

- truncate Silver tables before reload (idempotency)
- deduplicate customers using `ROW_NUMBER()` over `cst_id`
- sanitize and cast IDs/dates with regex checks
- normalize names (`TRIM`, `INITCAP`)
- map coded attributes to readable values:
    - marital status (`M/S` to `Married/Single`)
    - gender (`M/F`, fallback `n/a`)
    - product lines (`R/S/M/T` to `Road/Sport/Mountain/Touring`)
- derive product validity windows with `LEAD(...)` for end dates
- repair sales anomalies:
    - fallback date logic if order/ship/due dates are missing
    - recalculate `sales` and `price` when inconsistent with quantity
- clean ERP customer IDs and country values
- apply date sanity checks for birthdates
- log per-table and total runtime


### 5.3 From Silver to Gold (Star Schema)

In Gold, I build business-facing tables for BI tools and SQL analytics.

Scripts used:

- [scripts/gold/ddl_gold.sql](scripts/gold/ddl_gold.sql)
- [scripts/gold/proc_load_gold.sql](scripts/gold/proc_load_gold.sql)

What I implemented in `gold.load_gold()`:

- rebuild `gold.dim_customers` with CRM+ERP enrichment
- rebuild `gold.dim_products` with category joins
- keep only current product rows (`prd_end_dt IS NULL`) for clean dimensional analysis
- populate `gold.fact_sales` with surrogate keys from dimensions
- log per-section and batch runtime

![Data Model (Star Schema)](https://github.com/NebylytsiaKyrylo/sql_data_warehouse_project/blob/master/docs/data_model.png?raw=true)

### 5.4 Data Catalog

After building the Gold layer, I created a **comprehensive data catalog** to document all tables and columns across all three layers.

**Purpose:**
- **For Business Users** : Understand what data is available and what each field means
- **For Data Analysts** : Know where to find specific metrics and dimensions
- **For Data Engineers** : Reference for governance, lineage, and data ownership

**Contents:**
- Table definitions and descriptions (what data is in each table)
- Column metadata (name, type, business definition, example values)
- Data lineage (how data flows from Bronze → Silver → Gold)
- Quality thresholds (acceptable value ranges, validation rules)
- Last updated timestamps for audit trail

**File:** [data_catalog.md](docs/data_catalog.md)

This ensures **single source of truth** for data semantics, reducing confusion and supporting self-service analytics.


## 6. Project Structure (with Role of Each Folder)

```text
.
|-- datasets/                    # Source CSV files (CRM and ERP)
|   |-- source_crm/              # Raw customer, product, and sales data from CRM system
|   `-- source_erp/              # Raw customer location and product category data from ERP
|
|-- docs/                        # Architecture diagrams and business documentation
|   |-- data_architecture.png    # High-level 3-layer medallion architecture diagram
|   |-- data_flow.png            # End-to-end data movement from sources to Gold
|   |-- data_integration.png     # Technical integration of CRM + ERP data sources
|   |-- data_model.png           # Final Star Schema (ERD with dimensions and facts)
|   |-- data_catalog.md          # Business definitions and metadata for all tables
|   |-- naming_conventions.md    # Standards for table, column, and procedure naming
|   |-- requirements.md          # Project scope, objectives, and business requirements
|   `-- project_plan_sql_DWH.md  # Detailed execution roadmap and timeline
|
|-- scripts/                     # SQL scripts organized by layer
|   |-- init/                    # Database initialization (one-time setup)
|   |   `-- init_database.sql    # Creates schemas (bronze, silver, gold)
|   |
|   |-- bronze/                  # Raw data ingestion layer
|   |   |-- ddl_bronze.sql       # Creates 6 raw tables (3 CRM + 3 ERP)
|   |   `-- proc_load_bronze.sql # Procedures to load CSV data into Bronze tables
|   |
|   |-- silver/                  # Data cleaning & standardization layer
|   |   |-- ddl_silver.sql       # Creates 6 cleaned tables (with proper data types)
|   |   `-- proc_load_silver.sql # Procedures to transform and deduplicate Bronze data
|   |
|   `-- gold/                    # Analytics-ready business layer
|       |-- ddl_gold.sql         # Creates Star Schema (2 dimensions + 1 fact table)
|       `-- proc_load_gold.sql   # Procedures to populate Gold tables with surrogate keys
|
|-- tests/                       # Data quality validation scripts
|   |-- quality_checks_silver.sql # Validates Silver layer data integrity
|   `-- quality_checks_gold.sql   # Validates Gold layer referential integrity
|
|-- docker-compose.yml           # Infrastructure definition (PostgreSQL container)
|-- .env.example                 # Template for database credentials (copy to .env)
|-- .gitignore                   # Specifies files to exclude from version control
`-- README.md                    # Main project documentation (this file)
```

## 7. How to Run the Project

### 7.1 Prerequisites

- Docker Desktop
- `psql` client (optional if you execute via `docker exec`)

### 7.2 Setup

1. Clone repository:

```bash
git clone https://github.com/NebylytsiaKyrylo/sql_data_warehouse_project.git
cd sql_data_warehouse_project
```

2. Create env file:

```bash
cp .env.example .env
```

3. Start PostgreSQL container:

```bash
docker compose up -d
```

4. Confirm service health:

```bash
docker ps
```

Notes:

- `scripts/init/init_database.sql` runs automatically at first database initialization.
- If you need a full clean reset, recreate volumes:

```bash
docker compose down -v
docker compose up -d
```

### 7.3 Run DDL and Load Procedures

You can execute the SQL scripts either **manually** using your preferred SQL client (connected to `localhost:5432`) or
via **command line** using `docker exec`.

#### Option A: Manual Execution

If you prefer using a graphical interface like **DBeaver**, **pgAdmin**, or **SQL Workbench**, follow these steps:

1. **Initialize Schemas** — Run all scripts in `scripts/init/` to set up the database structure
2. **Create Tables (DDL)** — Run the DDL scripts in order:
    - `scripts/bronze/ddl_bronze.sql` — Creates raw data tables
    - `scripts/silver/ddl_silver.sql` — Creates cleaned data tables
    - `scripts/gold/ddl_gold.sql` — Creates analytics-ready star schema tables
3. **Create Procedures** — Run the procedure scripts in order:
    - `scripts/bronze/proc_load_bronze.sql` — Deploys raw data loading logic
    - `scripts/silver/proc_load_silver.sql` — Deploys data transformation logic
    - `scripts/gold/proc_load_gold.sql` — Deploys star schema population logic
4. **Execute Pipeline** — Run the stored procedures from Step 3 below
```sql
-- Load data from CSV files into Bronze layer (raw stage)
CALL bronze.load_bronze();

-- Transform and clean Bronze data into Silver layer (trusted stage)
CALL silver.load_silver();

-- Build Gold layer star schema from Silver data (analytics stage)
CALL gold.load_gold();
```

#### Option B: Automated via Terminal (Bash Script)

**Step 1 — Create schemas and tables (DDL):**  
- 1.1. Create Bronze layer (raw ingestion tables)
```bash
docker exec -it postgresql_dwh psql -U postgres -d data_warehouse -f /workspace/scripts/bronze/ddl_bronze.sql
```
- 1.2. Create Silver layer (cleaned & standardized tables)
```bash
docker exec -it postgresql_dwh psql -U postgres -d data_warehouse -f /workspace/scripts/silver/ddl_silver.sql
```
- 1.3. Create Gold layer (business-ready star schema)
```bash
docker exec -it postgresql_dwh psql -U postgres -d data_warehouse -f /workspace/scripts/gold/ddl_gold.sql
```

**Step 2 — Deploy stored procedures:**
- 2.1. Deploy Bronze layer procedures (load raw CSV data)
```bash
docker exec -it postgresql_dwh psql -U postgres -d data_warehouse -f /workspace/scripts/bronze/proc_load_bronze.sql
```
- 2.2. Deploy Silver layer procedures (clean & transform data)
```bash
docker exec -it postgresql_dwh psql -U postgres -d data_warehouse -f /workspace/scripts/silver/proc_load_silver.sql
```
- 2.3. Deploy Gold layer procedures (build analytics tables)
```bash
docker exec -it postgresql_dwh psql -U postgres -d data_warehouse -f /workspace/scripts/gold/proc_load_gold.sql
```

**Step 3 — Execute the full pipeline:**

```bash
docker exec -it postgresql_dwh psql -U postgres -d data_warehouse -c "CALL bronze.load_bronze(); CALL silver.load_silver(); CALL gold.load_gold();"
```

Each procedure logs per-table and total runtime on completion.

## 8. Data Quality Strategy (What I Validate)

In Silver checks, I validate:

- null/duplicate keys
- trimming issues on text fields
- standardized value domains (gender, marital status, product line, country)
- date validity and ordering
- sales consistency (`sales = quantity * price`)

File quality_checks_silver.sql:

- [tests/quality_checks_silver.sql](tests/quality_checks_silver.sql)

In Gold checks, I validate:

- surrogate key uniqueness in dimensions
- referential integrity from fact to dimensions
- row-count and total-sales lineage checks between Silver and Gold

File quality_checks_gold.sql:

- [tests/quality_checks_gold.sql](tests/quality_checks_gold.sql)

## 9. What Is Next

The Data Engineering scope is complete in this repository.

Next, I will use the Gold layer in the EDA & Data Analysis project.

### Objective — BI: Analytics & Reporting (Data Analysis)

Develop SQL-based analytics to deliver detailed insights into:

* **Customer Behavior**: Understanding how customers interact with products.
* **Product Performance**: Identifying top-selling items and revenue drivers.
* **Sales Trends**: Analyzing sales growth or decline over specific periods.

### Impact

These insights empower stakeholders with key business metrics, enabling strategic decision-making.
