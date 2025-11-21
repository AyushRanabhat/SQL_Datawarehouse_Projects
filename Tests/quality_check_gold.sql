-- ====================================================================================
-- CUSTOMER DATA INTEGRATION AND QUALITY CHECKS
-- ====================================================================================
-- Objective: Integrate customer information from CRM and ERP, 
-- prioritize master CRM values, and ensure no duplicate or inconsistent data exists.

-- STEP 1: Identify potential duplicate customer records after joining tables
SELECT 
    cst_id, 
    COUNT(*) AS duplicate_count
FROM (
    SELECT 
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_marital_status,
        ci.cst_gndr,
        ci.cst_create_date,
        ca.bdate,
        ca.gen,
        cl.cntry
    FROM Silver.crm_cust_info AS ci
    LEFT JOIN Silver.erp_cust_az12 AS ca ON ci.cst_key = ca.cid
    LEFT JOIN Silver.erp_loc_a101 AS cl ON ci.cst_key = cl.cid
) t
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- STEP 2: Resolve gender inconsistencies prioritizing CRM
SELECT DISTINCT
    ci.cst_gndr AS crm_gender,
    ca.gen AS erp_gender,
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS final_gender
FROM Silver.crm_cust_info AS ci
LEFT JOIN Silver.erp_cust_az12 AS ca ON ci.cst_key = ca.cid
LEFT JOIN Silver.erp_loc_a101 AS cl ON ci.cst_key = cl.cid
ORDER BY crm_gender, erp_gender;

-- STEP 3: Create a consolidated customer dimension table
SELECT 
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    cl.cntry AS country,
    ci.cst_marital_status AS marital_status,
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,
    ca.bdate AS birth_date,
    ci.cst_create_date AS create_date
FROM Silver.crm_cust_info AS ci
LEFT JOIN Silver.erp_cust_az12 AS ca ON ci.cst_key = ca.cid
LEFT JOIN Silver.erp_loc_a101 AS cl ON ci.cst_key = cl.cid;

-- STEP 4: Verify gender values in the gold dimension table
SELECT DISTINCT gender FROM gold.dim_customers;

-- STEP 5: Sample validation of final customer table
SELECT * FROM gold.dim_customers;

-- ====================================================================================
-- PRODUCT DATA INTEGRATION AND QUALITY CHECKS
-- ====================================================================================
-- Objective: Integrate product information from CRM and ERP categories, 
-- remove duplicates, and maintain referential integrity.

-- STEP 1: Consolidate product information with category details
SELECT 
    ROW_NUMBER() OVER (PARTITION BY prd_start_dt, prd_key) AS product_key,
    pd.prd_id AS product_id,
    pd.prd_key AS product_number,
    pd.prd_nm AS product_name,
    pd.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pd.prd_cost AS product_cost,
    pd.prd_line AS product_line,
    pc.maintenance,
    pd.prd_start_dt AS start_date
FROM Silver.crm_prd_info pd
LEFT JOIN Silver.erp_px_cat_g1v2 pc ON pd.cat_id = pc.id
WHERE pd.prd_end_dt IS NULL;

-- STEP 2: Identify duplicates in the product table after join
SELECT product_key, COUNT(*) AS duplicate_count
FROM (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY pd.prd_start_dt, pd.prd_key) AS product_key,
        pd.prd_id,
        pd.prd_key,
        pd.prd_nm,
        pd.cat_id,
        pc.cat,
        pc.subcat,
        pd.prd_cost,
        pd.prd_line,
        pc.maintenance,
        pd.prd_start_dt
    FROM Silver.crm_prd_info pd
    LEFT JOIN Silver.erp_px_cat_g1v2 pc ON pd.cat_id = pc.id
    WHERE pd.prd_end_dt IS NULL
) t
GROUP BY product_key
HAVING COUNT(*) > 1;

-- STEP 3: Identify product keys with multiple active versions
SELECT *
FROM Silver.crm_prd_info pd
WHERE pd.prd_key IN (
    SELECT pd.prd_key
    FROM Silver.crm_prd_info pd
    WHERE pd.prd_end_dt IS NULL
    GROUP BY pd.prd_key
    HAVING COUNT(*) > 1
)
ORDER BY pd.prd_key, pd.prd_start_dt;

-- STEP 4: Sample validation of product dimension
SELECT * FROM gold.dim_products;

-- ====================================================================================
-- FACT TABLE INTEGRITY CHECKS
-- ====================================================================================
-- Objective: Ensure foreign key references in fact_sales are valid

SELECT *
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c ON s.customer_key = c.customer_key
LEFT JOIN gold.dim_products AS p ON s.product_key = p.product_key
WHERE s.customer_key IS NULL OR s.product_key IS NULL;

-- STEP 2: Optional – Count unmatched foreign keys to quantify integrity issues
SELECT 
    COUNT(*) AS invalid_sales_count
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c ON s.customer_key = c.customer_key
LEFT JOIN gold.dim_products AS p ON s.product_key = p.product_key
WHERE s.customer_key IS NULL OR s.product_key IS NULL;

-- STEP 3: Optional – Check for sales without matching customers
SELECT s.*
FROM gold.fact_sales AS s
WHERE NOT EXISTS (
    SELECT 1 
    FROM gold.dim_customers AS c 
    WHERE s.customer_key = c.customer_key
);

-- STEP 4: Optional – Check for sales without matching products
SELECT s.*
FROM gold.fact_sales AS s
WHERE NOT EXISTS (
    SELECT 1 
    FROM gold.dim_products AS p 
    WHERE s.product_key = p.product_key
);
