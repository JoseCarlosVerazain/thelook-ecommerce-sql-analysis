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
