# Data Catalog for Gold Layer

## 1. Overview

The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It
consists of **dimension tables** and **fact tables** for specific business metrics.

---

## 2. Dimensions

### 2.1. **gold.dim_customers**

- **Purpose:** Stores customer details enriched with demographic and geographic data. Contains unique, cleaned, and
  integrated information about customers from both CRM and ERP systems.
- **Columns:**

| Column            | Data Type   | Description                                                                                   |
|:------------------|:------------|:----------------------------------------------------------------------------------------------|
| `customer_key`    | SERIAL      | Surrogate key (Primary Key) uniquely identifying each customer record in the dimension table. |
| `customer_id`     | INT         | Unique numerical identifier assigned to each customer.                                        |
| `customer_number` | TEXT        | Alphanumeric identifier representing the customer, used for tracking and referencing.         |
| `first_name`      | TEXT        | The customer's first name, as recorded in the system.                                         |
| `last_name`       | TEXT        | The customer's last name or family name.                                                      |
| `gender`          | TEXT        | The gender of the customer (e.g., 'Male', 'Female', 'n/a').                                   |
| `birthdate`       | DATE        | The date of birth of the customer, formatted as YYYY-MM-DD (e.g., 1971-10-06).                |
| `marital_status`  | TEXT        | The marital status of the customer (e.g., 'Married', 'Single').                               |
| `country`         | TEXT        | The country of residence for the customer (e.g., 'Australia').                                |
| `create_date`     | DATE        | The date and time when the customer record was created in the system.                         |
| `dwh_create_date` | TIMESTAMPTZ | Technical timestamp of record insertion into the DWH.                                         |

---

### 2.2. **gold.dim_products**

- **Purpose:** Provides information about the products and their attributes.
- **Columns:**

| Column            | Data Type   | Description                                                                                          |
|:------------------|:------------|:-----------------------------------------------------------------------------------------------------|
| `product_key`     | SERIAL      | Surrogate key (Primary Key) uniquely identifying each product record in the product dimension table. |
| `product_id`      | INT         | A unique identifier (Natural ID) assigned to the product for internal tracking and referencing.      |
| `product_number`  | TEXT        | Business key (SKU) representing the product, often used for categorization or inventory.             |
| `product_name`    | TEXT        | Descriptive name of the product, including key details such as type, color, and size.                |
| `category_id`     | TEXT        | A unique identifier for the product's category, linking to its high-level classification.            |
| `category`        | TEXT        | The broader classification of the product (e.g., Bikes, Components) to group related items.          |
| `subcategory`     | TEXT        | A more detailed classification of the product within the category, such as product type.             |
| `product_line`    | TEXT        | The specific product line or series to which the product belongs (e.g., Road, Mountain).             |
| `cost`            | NUMERIC     | The cost or base price of the product, measured in monetary units.                                   |
| `maintenance`     | TEXT        | Indicates whether the product requires maintenance (e.g., 'Yes', 'No').                              |
| `start_date`      | DATE        | The date when the product became available for sale or use, stored in the source system.             |
| `dwh_create_date` | TIMESTAMPTZ | Technical timestamp of record insertion into the DWH.                                                |

---

## 3. Fact Table

### 3.1. **gold.fact_sales**

- **Purpose:** Stores transactional sales data for analytical purposes.
- **Columns:**

| Column            | Data Type   | Description                                                                           |
|:------------------|:------------|:--------------------------------------------------------------------------------------|
| `order_number`    | TEXT        | A unique alphanumeric identifier for each sales order (e.g., 'SO54496').              |
| `product_key`     | INT         | Surrogate key linking the order to the product dimension table `gold.dim_products`.   |
| `customer_key`    | INT         | Surrogate key linking the order to the customer dimension table `gold.dim_customers`. |
| `order_date`      | DATE        | The date when the order was placed                                                    |
| `shipping_date`   | DATE        | The date when the order was shipped to the customer.                                  |
| `due_date`        | DATE        | The date when the order payment was due.                                              |
| `sales_amount`    | NUMERIC     | The total monetary value of the sale for the line item.                               |
| `quantity`        | INT         | The number of units of the product ordered for the line item (e.g., 1).               |
| `price`           | NUMERIC     | The price per unit of the product for the line item.                                  |
| `dwh_create_date` | TIMESTAMPTZ | Technical timestamp of record insertion into the DWH.                                 |