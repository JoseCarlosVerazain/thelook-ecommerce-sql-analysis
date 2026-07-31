-- ============================================================
-- Project : TheLook E-commerce (BigQuery public dataset)
-- File    : 01_exploration_products.sql
-- Purpose : Initial exploration of the `products` table —
--           schema, volume, grain and primary key integrity
-- ============================================================


-- #0.1 List tables in the dataset
SELECT
  table_name,
  table_type
FROM `bigquery-public-data.thelook_ecommerce`.INFORMATION_SCHEMA.TABLES;


-- #0.2 Table schema (column names and data types)
SELECT
  column_name,
  data_type
FROM `bigquery-public-data.thelook_ecommerce`.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'products';
-- 'id' is the primary key candidate.
-- 'distribution_center_id' is a foreign key pointing to another table.
-- 'cost' and 'retail_price' are numeric → measures.


-- #1 Data preview
SELECT *
FROM `bigquery-public-data.thelook_ecommerce.products`
LIMIT 10;
-- Grain: one row per product in the catalog.
-- Primary key candidate: 'id'.
-- Measures: 'cost', 'retail_price'. Remaining fields are dimensional.
-- No dates or quantities → dimension table.
-- Small enough to run a full row count safely.


-- #2 Table volume
SELECT
  COUNT(*) AS total_rows
FROM `bigquery-public-data.thelook_ecommerce.products`;
-- 29,120 rows.


-- #3 Primary key integrity check
SELECT
  COUNT(*)          AS total_rows,
  COUNT(DISTINCT id) AS unique_ids,
  COUNT(id)          AS non_null_ids
FROM `bigquery-public-data.thelook_ecommerce.products`;
-- total_rows = unique_ids = non_null_ids
-- → 'id' is a valid primary key: unique and with no nulls.


-- #4 Null coverage across the fields
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(cost IS NULL) AS null_cost,
  COUNTIF(category IS NULL) AS null_category,
  COUNTIF(name IS NULL) AS null_name,
  COUNTIF(brand IS NULL) AS null_brand,
  COUNTIF(retail_price IS NULL) AS null_retail_price,
  COUNTIF(department IS NULL) AS null_department,
  COUNTIF(sku IS NULL) AS null_sku,
  COUNTIF(distribution_center_id IS NULL) AS null_distribution_center_id
FROM `bigquery-public-data.thelook_ecommerce.products`;
-- Full coverage on all fields except:
--   name  → 2 nulls
--   brand → 24 nulls
-- Note: any GROUP BY brand will silently drop those 24 products.

-- #5 Hidden missing values and invalid measures
SELECT
  COUNTIF(TRIM(name) = '') AS empty_name,
  COUNTIF(TRIM(category) = '') AS empty_category,
  COUNTIF(TRIM(brand) = '') AS empty_brand,
  COUNTIF(TRIM(department) = '') AS empty_department,
  COUNTIF(TRIM(sku) = '') AS empty_sku,
  COUNTIF(cost = 0) AS zero_cost,
  COUNTIF(retail_price = 0) AS zero_price,
  COUNTIF(cost < 0) AS negative_cost,
  COUNTIF(retail_price < 0) AS negative_price,
  COUNTIF(cost > retail_price) AS cost_above_price
FROM `bigquery-public-data.thelook_ecommerce.products`;
-- All checks returned 0:
--   no empty or whitespace-only strings
--   no zero or negative values in cost / retail_price
--   no product priced below its cost
-- Measures are safe to aggregate without cleaning.

-- #6 Dimension cardinality
SELECT 
  COUNT(DISTINCT name) AS distinct_name, 
  COUNT(DISTINCT category) AS distinct_category, 
  COUNT(DISTINCT brand) AS distinct_brand, 
  COUNT(DISTINCT department) AS distinct_department, 
  COUNT(DISTINCT sku) AS distinct_sku,
  COUNT(DISTINCT distribution_center_id) AS distribution_center_id
FROM `bigquery-public-data.thelook_ecommerce.products`;
-- Low cardinality (safe as grouping axis): 
-- department = 2, category = 26, distribution_center = 10.
-- High cardinality: brand, name -> use as filter or top-N, not as axis.
-- sku = 29,120 = total rows -> sku is a valid alternate key.
-- name = 27,309 < total rows -> product names repeat.



-- #7 Numeric distribution o measures
SELECT
  ROUND(MIN(cost), 2) AS min_cost,
  ROUND(AVG(cost), 2) AS avg_cost,
  ROUND(MAX(cost), 2) AS max_cost,
  ROUND(STDDEV(cost), 2) AS stddev_cost,
  ROUND(MIN(retail_price), 2) AS min_retail_price,
  ROUND(MAX(retail_price), 2) AS max_price,
  ROUND(AVG(retail_price), 2) AS avg_price,
  ROUND(STDDEV(retail_price), 2) AS stddev_price
FROM `bigquery-public-data.thelook_ecommerce.products`;
-- cost:  min 0.01 | avg 28.00 | max 557.15 | stddev 30.00
-- price: min 0.02 | avg 59.00 | max 999.00 | stddev 65.00
-- Coefficient of variation (stddev/avg) > 1 on both measures
-- -> dispersion exceeds the mean. Cause to be confirmed in #7.1.

-- #7.1 Quartiles of measure
SELECT
  APPROX_QUANTILES(cost, 4) AS cost_quartiles,
  APPROX_QUANTILES(retail_price, 4) AS price_quartiles
FROM `bigquery-public-data.thelook_ecommerce.products`;
-- cost:  0.01 | 11.24 | 19.72 | 34.43 | 557.15
-- price: 0.02 | 24.00 | 39.99 | 69.95 | 999.00
-- Mean sits ~45% above the median on both measures and max is far
-- beyond Q3 -> right-skewed distribution with a long tail.
-- Implication: median is the representative value, not the mean.
-- Median markup = 39.99 / 19.72 = 2.03x (~50% gross margin).
-- Note: min cost of 0.008 passed the zero-check in #5 but is not a
--   plausible unit cost. Zero-checks do not catch implausible positives.
