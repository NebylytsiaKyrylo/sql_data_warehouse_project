# Medallion Architecture Specification

## 1. Bronze Layer (Raw)
* **Definition**: Raw, unprocessed data as-is from source systems.
* **Objective**: Ensure data traceability and facilitate debugging.
* **Object Type**: Physical Tables.
* **Load Method**: Full Load (Truncate & Insert).
* **Transformation**: None (As-is).
* **Target Audience**: Data Engineers.

---

## 2. Silver Layer (Cleaned)
* **Definition**: Cleaned, standardized, and enriched data.
* **Objective**: Intermediate layer used to prepare data for downstream analysis.
* **Object Type**: Physical Tables.
* **Load Method**: Full Load (Truncate & Insert).
* **Transformations**: 
    * Data Cleaning (Deduplication, Null handling)
    * Data Standardization (Date formats, Units)
    * Data Normalization
    * Derived Columns & Data Enrichment
* **Target Audience**: Data Analysts, Data Engineers.

---

## 3. Gold Layer (Business)
* **Definition**: Business-ready data, curated for high-level reporting.
* **Objective**: Provide reliable data consumed for BI, Analytics, and Reporting.
* **Object Type**: Views (preferred) or Materialized Tables.
* **Load Method**: None (Dynamic calculation via Views).
* **Transformations**:
    * Data Integration (Joining domains)
    * Data Aggregation (Sum, Avg, Count)
    * Application of Business Logic & Rules
* **Data Modeling**: Star Schema (Fact and Dimension tables).
* **Target Audience**: Data Analysts, Business Users, Stakeholders.