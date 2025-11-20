--CHECKING FOR DUPLICATES OR NULLS
SELECT
prd_id
FROM Bronze.crm_prd_info
WHERE prd_id IS NULL OR prd_id = 0

--SUBSTRINGING THE PDF_KEY AS IT'S GOING TO BE USED WITH THE Bronze.erp_px_cat_g1v2 and sales details

SELECT
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
SUBSTRING(prd_key,7, LEN(prd_key)) AS prd_key
FROM Bronze.crm_prd_info

-- CHECKING THE PRD_NM

SELECT prd_nm
FROM Bronze.crm_prd_info
WHERE prd_nm IS NULL OR
		prd_nm != TRIM(prd_nm)

--CHECKING THE PRD_COST

SELECT COALESCE(prd_cost,0)
FROM Bronze.crm_prd_info
WHERE prd_cost <= 0 OR prd_cost IS NULL

-- CHECKING THE PRD_LINE

SELECT DISTINCT prd_line,
CASE 
	WHEN prd_line = 'M' THEN 'Mountains'
	WHEN prd_line = 'R' THEN 'Roads'
	WHEN prd_line = 'S' THEN 'Other Sales'
	WHEN prd_line = 'T' THEN 'Touring'
	ELSE 'n/a'
END prd_line
FROM Bronze.crm_prd_info

--CHECKING THE INVALID DATE

SELECT *
FROM Bronze.crm_prd_info
WHERE prd_start_dt>prd_end_dt


SELECT *,
CAST(LEAD(prd_start_dt) OVER ( PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_test_end_date
FROM Bronze.crm_prd_info

SELECT * FROM Bronze.crm_sales_details;
SELECT * FROM Bronze.crm_cust_info
SELECT * FROM Bronze.crm_prd_info
SELECT * FROM Bronze.crm_prd_info
SELECT * FROM Bronze.erp_px_cat_g1v2
SELECT * FROM Silver.crm_prd_info
