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
