# SQL Data Warehouse Project Plan

## 1. Requirements Analysis
- [ ] Analyse and Understand the Business Requirements
- [ ] Identify Source Systems and Data Formats (API, CSV, Logs)
- [ ] Define Key Performance Indicators (KPIs) and Business Questions

## 2. Design Data Architecture
- [ ] Choose Data Management Approach (ELT vs ETL)
- [ ] Design the Medallion Layers (Bronze, Silver, Gold)
- [ ] Draw the Data Architecture and Data Flow (Draw.io)

## 3. Project Initialization
- [ ] Create Detailed Project Tasks and Timeline
- [ ] Define Project Naming Conventions and Coding Standards
- [ ] Create Git Repository and Prepare Folder Structure
- [ ] Security: Create .env and .gitignore to protect secrets
- [ ] Infrastructure: Configure docker-compose.yml and Docker Networks
- [ ] Create Database and Schemas in PostgreSQL

## 4. Build Bronze Layer (Raw Data)
- [ ] Analyzing Source Systems and Schema Mapping
- [ ] Coding: Data Ingestion Pipelines (Python/SQL)
- [ ] Quality: Validating Data Completeness and Schema Checks
- [ ] Document: Update Data Flow Diagrams
- [ ] Commit Code in Git Repository

## 5. Build Silver Layer (Cleaned & Standardized)
- [ ] Analyzing: Explore and Understand Raw Data
- [ ] Coding: Data Cleansing (Deduplication, Formatting, Null Handling)
- [ ] Quality: Validating Data Correctness and Referential Integrity
- [ ] Document: Extend Data Flow and Transformation Logic
- [ ] Commit Code in Git Repository

## 6. Build Gold Layer (Business Ready)
- [ ] Analyzing: Explore Business Objects and Aggregation Needs
- [ ] Coding: Data Integration and Dimensional Modeling (Star Schema)
- [ ] Quality: Validating Business Logic and Data Consistency
- [ ] Document: Draw Data Model of Star Schema
- [ ] Document: Create Data Catalog for End-Users
- [ ] Commit Code in Git Repository

## 7. Project Finalization
- [ ] Perform End-to-End Integration Testing
- [ ] Create README.md with Setup Instructions
- [ ] Final Presentation of KPIs and Business Insights