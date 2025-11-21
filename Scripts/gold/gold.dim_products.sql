/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/
-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY pd.prd_start_dt, pd.prd_key) AS product_key,
    pd.prd_id AS product_id,
    pd.prd_key AS product_number,
    pd.prd_nm AS product_name,
    pd.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pd.prd_cost AS product_cost,
    pc.maintenance,
    pd.prd_start_dt AS start_date,
    pd.prd_line AS product_line
FROM Silver.crm_prd_info pd
LEFT JOIN Silver.erp_px_cat_g1v2 pc
    ON pd.cat_id = pc.id
WHERE pd.prd_end_dt IS NULL;
