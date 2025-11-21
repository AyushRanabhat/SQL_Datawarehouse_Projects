-- CTE METHOD TO CLEAN DATA FOR LOAD

WITH RAW AS(
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
		CASE WHEN sls_order_dt <= 0 or len(sls_order_dt) <> 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE)
		END sls_order_dt,
		CASE WHEN sls_ship_dt <= 0 or len(sls_ship_dt) <> 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE)
		END sls_ship_dt,
		CASE WHEN sls_due_dt <= 0 or len(sls_due_dt) <> 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE)
		END sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		FROM Bronze.crm_sales_details
),
 FIXED_SALES AS (
		SELECT
		*,
	CASE
		WHEN sls_sales is null or sls_sales<=0 or sls_sales <> sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS corr_sls_sales,
		ABS(sls_quantity) as CORR_sales_qty
		FROM RAW
 )

 SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	corr_sls_sales as sls_sales,
	CORR_sales_qty as sls_quantity,
CASE
	WHEN sls_price IS NULL OR sls_price <= 0 or sls_price <> corr_sls_sales/CORR_sales_qty
	THEN corr_sls_sales/CORR_sales_qty
	ELSE sls_price
END sls_price
FROM FIXED_SALES
WHERE sls_ord_num = 'SO61570'
ORDER BY sls_prd_key
