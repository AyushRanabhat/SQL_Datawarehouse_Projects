/***************************************************************
  Validation + Transformation workflow
  - Validate raw source tables for structural and domain issues
  - Deduplicate and standardize fields where necessary
  - Load cleaned data into Silver.* tables using deterministic rules
  - Run post-load sanity checks to assert expectations
***************************************************************/

/* -------------------------
   1) CUSTOMER (crm_cust_info)
   Purpose: ensure primary key uniqueness, remove trailing/leading spaces,
            normalize marital status & gender and keep most recent record.
   ------------------------- */

-- 1.1 Validate uniqueness / missing primary key
-- Rationale: primary key must be unique and not null; return offending rows for investigation.
SELECT cst_id, COUNT(*) AS cnt
FROM Bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 1.2 Identify older duplicate records (keep the latest by create date)
-- Rationale: mark records not selected by the dedupe rule so analysts can review deletion candidates.
SELECT *
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rn
  FROM Bronze.crm_cust_info
) t
WHERE rn <> 1;

-- 1.3 Quick inspection for a specific suspicious customer id (example)
SELECT *
FROM Bronze.crm_cust_info
WHERE cst_id = 29466;

-- 1.4 Detect unwanted leading/trailing spaces on name/gender fields
-- Rationale: trimming strings prevents false duplicates and supports joins/filters.
SELECT cst_firstname, cst_lastname, cst_gndr
FROM Bronze.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname  <> TRIM(cst_lastname)
   OR cst_gndr      <> TRIM(cst_gndr);

-- 1.5 Survey domain values before normalization
SELECT DISTINCT cst_marital_status FROM Bronze.crm_cust_info;
SELECT DISTINCT cst_gndr           FROM Bronze.crm_cust_info;

-- 1.6 Load into Silver.crm_cust_info (dedupe + standardize)
TRUNCATE TABLE Silver.crm_cust_info;

INSERT INTO Silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT
    cst_id,
    cst_key,
    COALESCE(TRIM(cst_firstname), '') AS cst_firstname,
    COALESCE(TRIM(cst_lastname),  '') AS cst_lastname,
    CASE
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        ELSE 'n/a' -- preserve unknowns explicitly instead of NULL
    END AS cst_marital_status,
    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
FROM (
    SELECT
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rn
    FROM Bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE rn = 1;

-- 1.7 Post-load checks (expect zero rows)
-- Check duplicates/null PK
SELECT cst_id, COUNT(*) AS cnt
FROM Silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check trailing/leading spaces remain
SELECT cst_firstname, cst_lastname, cst_gndr
FROM Silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname  <> TRIM(cst_lastname)
   OR cst_gndr      <> TRIM(cst_gndr);

-- Domain summary for verification
SELECT DISTINCT cst_marital_status FROM Silver.crm_cust_info;
SELECT DISTINCT cst_gndr           FROM Silver.crm_cust_info;


/* -------------------------
   2) PRODUCT (crm_prd_info)
   Purpose: normalize product keys and names, map product line codes,
            compute product end date as one day before next start date.
   ------------------------- */

-- 2.1 Surface NULL/zero prd_id
SELECT prd_id
FROM Bronze.crm_prd_info
WHERE prd_id IS NULL OR prd_id = 0;

-- 2.2 Derived columns preview — extract category id and cleaned product key
-- Rationale: downstream joins use normalized cat_id and prd_key formats.
SELECT
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key_clean
FROM Bronze.crm_prd_info;

-- 2.3 Name trimming check
SELECT prd_nm
FROM Bronze.crm_prd_info
WHERE prd_nm IS NULL
   OR prd_nm <> TRIM(prd_nm);

-- 2.4 Price check (null or non-positive)
SELECT COALESCE(prd_cost, 0) AS prd_cost
FROM Bronze.crm_prd_info
WHERE prd_cost <= 0 OR prd_cost IS NULL;

-- 2.5 Line mapping preview (show raw values then mapped)
SELECT DISTINCT prd_line FROM Bronze.crm_prd_info;
SELECT DISTINCT
    prd_line,
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line_mapped
FROM Bronze.crm_prd_info;

-- 2.6 Invalid date rows (start after end)
SELECT *
FROM Bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- 2.7 Compute end date using LEAD — preview
SELECT *,
       CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS derived_prd_end_dt
FROM Bronze.crm_prd_info
ORDER BY prd_key, prd_start_dt;

-- 2.8 Load to Silver.crm_prd_info (normalize, dedupe on prd_id)
TRUNCATE TABLE Silver.crm_prd_info;

INSERT INTO Silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
    TRIM(prd_nm) AS prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    CASE UPPER(TRIM(prd_line))
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'M' THEN 'Mountain'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(
      LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1
      AS DATE
    ) AS prd_end_dt
FROM Bronze.crm_prd_info;

-- 2.9 Post-load checks
SELECT prd_id, COUNT(*) AS cnt
FROM Silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

SELECT prd_nm
FROM Silver.crm_prd_info
WHERE prd_nm IS NULL OR prd_nm <> TRIM(prd_nm);

SELECT prd_cost
FROM Silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

SELECT *
FROM Silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;


/* -------------------------
   3) SALES (crm_sales_details)
   Purpose: clean dates, correct sales/quantity/price inconsistencies,
            enforce positive quantities/prices and consistent sales figures.
   ------------------------- */

-- 3.1 CTE-based approach: normalize date fields, derive corrected sales and quantity
WITH RAW AS (
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) <> 8 THEN NULL
             ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE) END AS sls_order_dt,
        CASE WHEN sls_ship_dt  <= 0 OR LEN(sls_ship_dt)  <> 8 THEN NULL
             ELSE CAST(CAST(sls_ship_dt  AS NVARCHAR) AS DATE) END AS sls_ship_dt,
        CASE WHEN sls_due_dt   <= 0 OR LEN(sls_due_dt)   <> 8 THEN NULL
             ELSE CAST(CAST(sls_due_dt   AS NVARCHAR) AS DATE) END AS sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    FROM Bronze.crm_sales_details
),
FIXED_SALES AS (
    SELECT *,
        -- Rule: if sales missing/invalid, compute from quantity * abs(price)
        CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS corr_sls_sales,
        -- Force quantity to absolute value (business decision to treat negatives as sign errors)
        ABS(sls_quantity) AS corr_sls_qty
    FROM RAW
)

-- 3.2 Preview corrected values for a particular order for inspection
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    corr_sls_sales AS sls_sales,
    corr_sls_qty  AS sls_quantity,
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0 OR sls_price <> corr_sls_sales / NULLIF(corr_sls_qty, 0)
        THEN corr_sls_sales / NULLIF(corr_sls_qty, 0)
        ELSE sls_price
    END AS sls_price
FROM FIXED_SALES
WHERE sls_ord_num = 'SO61570'
ORDER BY sls_prd_key;

-- 3.3 Source-level anomalies to inspect
SELECT sls_ord_num FROM Bronze.crm_sales_details WHERE sls_ord_num IS NULL;
SELECT sls_ord_num FROM Bronze.crm_sales_details WHERE sls_ord_num <> TRIM(sls_ord_num);
SELECT sls_prd_key  FROM Bronze.crm_sales_details WHERE sls_prd_key IS NULL OR sls_prd_key <> TRIM(sls_prd_key);
SELECT sls_cust_id  FROM Bronze.crm_sales_details WHERE sls_cust_id IS NULL;

-- 3.4 Date range sanity checks (source)
SELECT NULLIF(sls_order_dt, 0) FROM Bronze.crm_sales_details
WHERE sls_order_dt IS NULL
   OR sls_order_dt <= 0
   OR LEN(sls_order_dt) <> 8
   OR sls_order_dt > 20501231
   OR sls_order_dt < 19501231;

SELECT * FROM Bronze.crm_sales_details WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- 3.5 Rule-based row validation for numeric fields (source)
SELECT *
FROM Bronze.crm_sales_details
WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
   OR sls_sales <> ABS(sls_quantity) * ABS(sls_price);

-- 3.6 Clean load into Silver.crm_sales_details using same correction rules
TRUNCATE TABLE Silver.crm_sales_details;

INSERT INTO Silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    TRIM(sls_ord_num) AS sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) <> 8 THEN NULL
         ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE) END AS sls_order_dt,
    CASE WHEN sls_ship_dt  <= 0 OR LEN(sls_ship_dt)  <> 8 THEN NULL
         ELSE CAST(CAST(sls_ship_dt  AS NVARCHAR) AS DATE) END AS sls_ship_dt,
    CASE WHEN sls_due_dt   <= 0 OR LEN(sls_due_dt)   <> 8 THEN NULL
         ELSE CAST(CAST(sls_due_dt   AS NVARCHAR) AS DATE) END AS sls_due_dt,
    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> ABS(sls_quantity) * ABS(sls_price)
        THEN ABS(sls_quantity) * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    ABS(sls_quantity) AS sls_quantity,
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
        THEN (sls_sales) / NULLIF(ABS(sls_quantity), 0)
        ELSE sls_price
    END AS sls_price
FROM Bronze.crm_sales_details;

-- 3.7 Post-load sanity checks (expect minimal to no rows)
SELECT * FROM Silver.crm_sales_details WHERE sls_order_dt IS NULL;
SELECT sls_order_dt FROM Silver.crm_sales_details
WHERE sls_order_dt < '1950-01-01' OR sls_order_dt > '2050-12-31';
SELECT * FROM Silver.crm_sales_details WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;
SELECT * FROM Silver.crm_sales_details
WHERE sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
   OR sls_sales <> ABS(sls_quantity) * ABS(sls_price);


/* -------------------------
   4) ERP / AUXILIARY Tables (erp_cust_az12, erp_loc_a101, erp_px_cat_g1v2)
   Purpose: normalize external system ids, birthdays, gender and country codes.
   ------------------------- */

-- 4.1 Prepare cid (strip NAS prefix) and ensure mapping to Silver.crm_cust_info keys
SELECT cid,
       CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END AS cid_clean,
       bdate,
       gen
FROM Bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END
      NOT IN (SELECT DISTINCT cst_key FROM Silver.crm_cust_info);

-- 4.2 BDATE checks (future dates or unrealistically old)
SELECT BDATE,
       CASE WHEN BDATE >= GETDATE() THEN NULL ELSE BDATE END AS bdate_normalized
FROM Bronze.erp_cust_az12
WHERE BDATE <= '1925-01-01' OR BDATE IS NULL OR BDATE >= GETDATE()
ORDER BY BDATE;

-- 4.3 Gender normalization preview
SELECT DISTINCT GEN FROM Bronze.erp_cust_az12;
SELECT DISTINCT
  GEN AS old_gen,
  CASE
    WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(GEN)) IN ('M','MALE')   THEN 'Male'
    ELSE 'n/a'
  END AS gen_normalized
FROM Bronze.erp_cust_az12;

-- 4.4 Load cleaned erp_cust_az12 -> Silver (no dedupe here; keep as-is for joins)
INSERT INTO Silver.erp_cust_az12 (cid, bdate, gen)
SELECT
  CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END AS cid,
  CASE WHEN BDATE >= GETDATE() THEN NULL ELSE BDATE END AS bdate,
  CASE WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
       WHEN UPPER(TRIM(GEN)) IN ('M','MALE')   THEN 'Male'
       ELSE 'n/a' END AS gen
FROM Bronze.erp_cust_az12;

-- 4.5 Location table: remove dashes and normalize country codes
INSERT INTO Silver.erp_loc_a101 (cid, cntry)
SELECT
  REPLACE(TRIM(CID), '-', '') AS cid,
  CASE
    WHEN CNTRY = 'DE' THEN 'Germany'
    WHEN CNTRY IN ('US','USA') THEN 'United States'
    WHEN CNTRY = '' OR CNTRY IS NULL THEN 'n/a'
    ELSE CNTRY
  END AS cntry
FROM Bronze.erp_loc_a101;

-- 4.6 Category table sanity and load
SELECT * FROM Bronze.erp_px_cat_g1v2
WHERE ID IS NULL OR CAT IS NULL OR SUBCAT IS NULL OR MAINTENANCE IS NULL;

-- Verify ID mapping to product categories
SELECT ID FROM Bronze.erp_px_cat_g1v2 WHERE ID <> TRIM(ID);

-- Load into Silver
INSERT INTO Silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
SELECT
  ID,
  CAT,
  SUBCAT,
  MAINTENANCE
FROM Bronze.erp_px_cat_g1v2;
