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
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS

SELECT 
	sls_ord_num AS order_number,
	p.product_key,
	c.customer_key,
	s.sls_order_dt AS order_date,
	s.sls_ship_dt AS shipping_date,
	s.sls_due_dt AS due_date,
	s.sls_sales AS sales,
	s.sls_quantity AS quantity,
	s.sls_price AS price
FROM Silver.crm_sales_details AS S
LEFT JOIN gold.dim_customers AS C
ON		s.sls_cust_id = c.customer_id
LEFT JOIN gold.dim_products AS P
ON		S.sls_prd_key = p.product_number
