-- WHATEVER
-- checking for duplicates or nulls

--expectation: no results

-- primary key must be unique and not null

select cst_id,
	count(*)
from Bronze.crm_cust_info
group by cst_id
having count(cst_id) > 1 or cst_id is null

-- RANKING THE UNWANTED DUPLICATES
select *
from (
select
*,
ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) flag_last
from Bronze.crm_cust_info)t
where flag_last != 1


select * from Bronze.crm_cust_info where cst_id = 29466 


-- CHECK FOR UNWANTED SPACES

SELECT cst_firstname,
		cst_lastname,
		cst_gndr
FROM Bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
OR		cst_lastname != TRIM(cst_lastname)
OR		cst_gndr !=  TRIM (cst_gndr)

SELECT cst_lastname
FROM Bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

select cst_gndr
from Bronze.crm_cust_info
where cst_gndr != TRIM (cst_gndr)

-- DATA STANDARDIZATION AND CONSISTENCY

SELECT DISTINCT cst_marital_status
	FROM Bronze.crm_cust_info


SELECT DISTINCT cst_gndr
	FROM Bronze.crm_cust_info


-- NOW, DOING THE FULL TRANSFORMATION  AND 
-- LOADING IT INTO SILVER TABLE


TRUNCATE TABLE silver.crm_cust_info
INSERT INTO silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)

	SELECT
		cst_id,
		cst_key,
		COALESCE(TRIM(cst_firstname),'') AS cst_firstname,
		COALESCE(TRIM(cst_lastname),'') AS cst_lastname,
		CASE 
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			ELSE 'n/a' 
		END AS cst_marital_status,
		CASE
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			ELSE 'n/a'
		END AS cst_gndr,
		--data_source,
		cst_create_date
	FROM (SELECT
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date,
		--'Bronze.crm_cust_info' AS data_source,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) flag_last
	FROM Bronze.crm_cust_info
	WHERE cst_id is not null)t
	WHERE flag_last = 1

	--select COUNT (*) FROM	Bronze.crm_cust_info
	--SELECT COUNT(*) FROM Silver.crm_cust_info

	-- QUALITY CHECKS Silver.crm_cust_info

--checking for duplicates or nulls

--expectation: no results

-- primary key must be unique and not null

select cst_id,
	count(*)
from Silver.crm_cust_info
group by cst_id
having count(cst_id) > 1 or cst_id is null

-- RANKING THE UNWANTED DUPLICATES
select *
from (
select
*,
ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) flag_last
from Silver.crm_cust_info)t
where flag_last != 1


select * from Silver.crm_cust_info where cst_id = 29466 


-- CHECK FOR UNWANTED SPACES

SELECT cst_firstname,
		cst_lastname,
		cst_gndr
FROM Silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
OR		cst_lastname != TRIM(cst_lastname)
OR		cst_gndr !=  TRIM (cst_gndr)

SELECT cst_lastname
FROM Silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

select cst_gndr
from Silver.crm_cust_info
where cst_gndr != TRIM (cst_gndr)

-- DATA STANDARDIZATION AND CONSISTENCY

SELECT DISTINCT cst_marital_status
	FROM Silver.crm_cust_info


SELECT DISTINCT cst_gndr
	FROM Silver.crm_cust_info

SELECT *
	FROM Bronze.crm_cust_info
	where cst_marital_status is null
	
select distinct cst_marital_status from Bronze.crm_cust_info

select * from silver.crm_cust_info
where cst_id in (29466, 29473, 29483);
SELECT *
	FROM Bronze.crm_cust_info
	where cst_id = 29466

	-- QUALITY CHECKS 

--checking for duplicates or nulls

--expectation: no results

-- primary key must be unique and not null

select cst_id,
	count(*)
from Silver.crm_cust_info
group by cst_id
having count(cst_id) > 1 or cst_id is null

-- RANKING THE UNWANTED DUPLICATES
select *
from (
select
*,
ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) flag_last
from Silver.crm_cust_info)t
where flag_last != 1


select * from Silver.crm_cust_info where cst_id = 29466 


-- CHECK FOR UNWANTED SPACES

SELECT cst_firstname,
		cst_lastname,
		cst_gndr
FROM Silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
OR		cst_lastname != TRIM(cst_lastname)
OR		cst_gndr !=  TRIM (cst_gndr)

SELECT cst_lastname
FROM Silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

select cst_gndr
from Silver.crm_cust_info
where cst_gndr != TRIM (cst_gndr)

-- DATA STANDARDIZATION AND CONSISTENCY

SELECT DISTINCT cst_marital_status
	FROM Silver.crm_cust_info


SELECT DISTINCT cst_gndr
	FROM Silver.crm_cust_info

SELECT *
	FROM Bronze.crm_cust_info
	where cst_marital_status is null
	
select distinct cst_marital_status from Bronze.crm_cust_info

select * from silver.crm_cust_info
where cst_id in (29466, 29473, 29483);
SELECT *
	FROM Bronze.crm_cust_info
	where cst_id = 29466

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

-- CLEANING AND LOADING THE DATA

TRUNCATE table silver.crm_prd_info
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
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, -- Extracting category id
			SUBSTRING(prd_key,7, LEN(prd_key)) AS prd_key,  -- Extracting product key
			TRIM(prd_nm) AS prd_nm, 
			ISNULL(prd_cost,0) AS prd_cost,
		CASE UPPER(TRIM(prd_line))
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'M' THEN 'Mountain'
			WHEN 'T' THEN 'Touring'
			ELSE 'n/a'
		END prd_line, -- Mapping product line codes to descriptive values
		CAST(prd_start_dt AS DATE) AS prd_start_date,
		CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) as prd_end_dt -- calculating the end date and one day before the next start date
	FROM Bronze.crm_prd_info
	--WHERE SUBSTRING(prd_key,7, LEN(prd_key)) IN (SELECT sls_prd_key FROM Bronze.crm_sales_details ) -- to check
	--WHERE SUBSTRING(prd_key,7, LEN(prd_key)) NOT IN (SELECT sls_prd_key FROM Bronze.crm_sales_details ) -- to check

	--QUALITY CHECKS Silver.crm_prd_info

--CHECKING FOR DUPLICATES OR NULLS IN PRIMARY KEY

SELECT
prd_id,
count(*)
FROM Silver.crm_prd_info
--WHERE prd_id IS NULL OR prd_id = 0
group by prd_id
HAVING count(*) > 1 or prd_id IS NULL

--SUBSTRINGING THE PDF_KEY AS IT'S GOING TO BE USED WITH THE Silver.erp_px_cat_g1v2 and sales details

SELECT
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
SUBSTRING(prd_key,7, LEN(prd_key)) AS prd_key
FROM Silver.crm_prd_info

-- CHECKING THE PRD_NM
-- CHECKING THE UNWANTED SPACES

SELECT prd_nm
FROM Silver.crm_prd_info
WHERE prd_nm IS NULL OR
		prd_nm != TRIM(prd_nm)

--CHECKING THE PRD_COST
-- CHECKING FOR NULLS OR NEGATIVE

SELECT prd_cost
FROM Silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- CHECKING THE PRD_LINE
-- DATA STANDARDIZATION & CONSISTENCY

SELECT DISTINCT prd_line FROM Silver.crm_prd_info

SELECT DISTINCT prd_line,
CASE 
	WHEN prd_line = 'M' THEN 'Mountains'
	WHEN prd_line = 'R' THEN 'Roads'
	WHEN prd_line = 'S' THEN 'Other Sales'
	WHEN prd_line = 'T' THEN 'Touring'
	ELSE 'n/a'
END prd_line
FROM Silver.crm_prd_info

--CHECKING THE INVALID DATE

SELECT *
FROM Silver.crm_prd_info
WHERE prd_start_dt>prd_end_dt
-- where prd_end_dt>prd_start_dt

SELECT *,
CAST(LEAD(prd_start_dt) OVER ( PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_test_end_date
FROM Silver.crm_prd_info

SELECT * FROM Silver.crm_sales_details;
SELECT * FROM Silver.crm_cust_info
SELECT * FROM Silver.crm_prd_info
SELECT * FROM Silver.crm_prd_info
SELECT * FROM Silver.erp_px_cat_g1v2
SELECT * FROM Silver.crm_prd_info
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

-- DATA CHECK silver.crm_sales_details

select * from Bronze.crm_sales_details

-- CHECKING THE sales order numbers

SELECT sls_ord_num
FROM Bronze.crm_sales_details
WHERE sls_ord_num IS NULL

SELECT sls_ord_num
FROM Bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

-- CHECKING THE sales product key

SELECT sls_prd_key
FROM Bronze.crm_sales_details
WHERE sls_prd_key is null or
	sls_prd_key != TRIM(sls_prd_key);

select sls_cust_id from Bronze.crm_sales_details
WHERE sls_cust_id is null;

select * from Bronze.crm_sales_details
where sls_prd_key in
(select prd_key from silver.crm_prd_info)


select * from Bronze.crm_sales_details
where sls_prd_key not in
(select prd_key from silver.crm_prd_info)

SELECT * from Bronze.crm_sales_details
where sls_cust_id IN (SELECT cst_id FROM silver.crm_cust_info)
select * from Bronze.crm_sales_details
select * from Silver.crm_cust_info

-- CHECKING FOR INVALID DATES

-- for order date

SELECT NULLIF(sls_order_dt,0)
FROM Bronze.crm_sales_details
WHERE sls_order_dt is null
	OR sls_order_dt <= 0 	
	OR LEN(sls_order_dt) != 8
	OR sls_order_dt > 20501231 
	OR sls_order_dt < 19501231

SELECT * FROM Bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt
	
-- for shipping date

SELECT NULLIF(sls_ship_dt,0)
FROM Bronze.crm_sales_details
WHERE sls_ship_dt is null
	OR sls_ship_dt <= 0 	 
	OR LEN(sls_ship_dt) != 8
	OR sls_ship_dt > 20501231 
	OR sls_ship_dt < 19501231

SELECT * FROM Bronze.crm_sales_details
WHERE sls_ship_dt > sls_due_dt

-- for due date

SELECT NULLIF(sls_due_dt,0)
FROM Bronze.crm_sales_details
WHERE sls_due_dt is null
	OR sls_due_dt <= 0 	
	OR LEN(sls_due_dt) != 8
	OR sls_due_dt > 20501231 
	OR sls_due_dt < 19501231

SELECT * FROM Bronze.crm_sales_details
WHERE sls_due_dt < sls_order_dt

-- checking the sales, quantity and the price

select * 
from Bronze.crm_sales_details
where sls_sales is null or sls_quantity is null or sls_price is null or
		sls_sales <= 0 or sls_quantity <= 0  or sls_price <= 0 or
		sls_sales != abs(sls_quantity) * abs(sls_price)

-- Rules
--1. If sales is negative, zero or null, derive it using quantity * price.
--2. If pirce is null or zero, calculate it using sales/price, vise versa for the quantity as well.
--3. If price is negative, convert it into a positive value.

select 
*
from(

select *,
	CASE 
		WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales!= ABS(sls_quantity) * ABS(sls_price) 
		THEN ABS(sls_quantity) * ABS(sls_price)
		ELSE sls_sales
	END sls_sales1,
		ABS(sls_quantity) AS sls_quantity1,
	CASE 
		WHEN sls_price IS NULL OR sls_price <=0-- OR sls_price!= (sls_sales)/NULLIF(ABS(sls_quantity),0)
		THEN (sls_sales)/NULLIF(ABS(sls_quantity),0)
		ELSE sls_price
	END sls_price1
FROM Bronze.crm_sales_details
where sls_sales is null or sls_sales <=0)t
where sls_sales1 != sls_quantity1 * sls_price1


-- CLEANING AND LOADING THE DATA INTO SILVER.CRM_SALES_DETAILS
TRUNCATE TABLE silver.crm_sales_details
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
	CASE
		WHEN sls_order_dt <= 0 or len(sls_order_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE)
	END sls_order_dt,
	CASE
		WHEN sls_ship_dt <= 0 or len(sls_ship_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE)
	END sls_ship_dt,
	CASE
		WHEN sls_due_dt <= 0 or len(sls_due_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE)
	END sls_due_dt,
	CASE 
		WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales!= ABS(sls_quantity) * ABS(sls_price) 
		THEN ABS(sls_quantity) * ABS(sls_price)
		ELSE sls_sales
	END sls_sales,
		ABS(sls_quantity) AS sls_quantity,
	CASE 
		WHEN sls_price IS NULL OR sls_price <=0 
		THEN (sls_sales)/NULLIF(ABS(sls_quantity),0)
		ELSE sls_price
	END sls_price
FROM Bronze.crm_sales_details
--where sls_ord_num = 'SO61570'
--where len(sls_order_dt) != 8

-- QUALITY CHECK silver.crm_sales_details

select * from Silver.crm_sales_details
where --sls_order_dt is null
		sls_ord_num IN ('SO64338','SO64339','SO64340')
-- CHECKING THE sales order numbers

SELECT sls_ord_num
FROM Silver.crm_sales_details
WHERE sls_ord_num IS NULL

SELECT sls_ord_num
FROM Silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

-- CHECKING THE sales product key

SELECT sls_prd_key
FROM Silver.crm_sales_details
WHERE sls_prd_key is null or
	sls_prd_key != TRIM(sls_prd_key);

select sls_cust_id from Silver.crm_sales_details
WHERE sls_cust_id is null;

select * from Silver.crm_sales_details
where sls_prd_key in
(select prd_key from silver.crm_prd_info)


select * from Silver.crm_sales_details
where sls_prd_key not in
(select prd_key from silver.crm_prd_info)

SELECT * from Silver.crm_sales_details
where sls_cust_id IN (SELECT cst_id FROM silver.crm_cust_info)
select * from Silver.crm_sales_details
select * from Silver.crm_cust_info

-- CHECKING FOR INVALID DATES

-- for order date

SELECT sls_order_dt
FROM Silver.crm_sales_details
WHERE 
    sls_order_dt IS NULL
    OR sls_order_dt < '1950-01-01'
    OR sls_order_dt > '2050-12-31';


SELECT * FROM Silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt
	
-- for shipping date

SELECT sls_ship_dt
FROM Silver.crm_sales_details
WHERE 
    sls_ship_dt IS NULL
    OR sls_ship_dt < '1950-01-01'
    OR sls_ship_dt > '2050-12-31';


SELECT * FROM Silver.crm_sales_details
WHERE sls_ship_dt > sls_due_dt

-- for due date

SELECT sls_due_dt
FROM Silver.crm_sales_details
WHERE 
    sls_due_dt IS NULL
    OR sls_due_dt < '1950-01-01'
    OR sls_due_dt > '2050-12-31';

SELECT * FROM Silver.crm_sales_details
WHERE sls_due_dt < sls_order_dt

-- checking the sales, quantity and the price

select * 
from Silver.crm_sales_details
where sls_sales is null or sls_quantity is null or sls_price is null or
		sls_sales <= 0 or sls_quantity <= 0  or sls_price <= 0 or
		sls_sales != abs(sls_quantity) * abs(sls_price)

-- Rules
--1. If sales is negative, zero or null, derive it using quantity * price.
--2. If pirce is null or zero, calculate it using sales/price, vise versa for the quantity as well.
--3. If price is negative, convert it into a positive value.

select 
*
from(

select *,
	CASE 
		WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales!= ABS(sls_quantity) * ABS(sls_price) 
		THEN ABS(sls_quantity) * ABS(sls_price)
		ELSE sls_sales
	END sls_sales1,
		ABS(sls_quantity) AS sls_quantity1,
	CASE 
		WHEN sls_price IS NULL OR sls_price <=0-- OR sls_price!= (sls_sales)/NULLIF(ABS(sls_quantity),0)
		THEN (sls_sales)/NULLIF(ABS(sls_quantity),0)
		ELSE sls_price
	END sls_price1
FROM Silver.crm_sales_details
where sls_sales is null or sls_sales <=0)t
where sls_sales1 != sls_quantity1 * sls_price1

-- checking data from epr.cust_az12


-- PREPARING CID FOR CST_KEY IN CRM_SALES_DETAILS 
SELECT 
		cid,
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
		ELSE cid 
	END cid,
		bdate,
		gen
FROM Bronze.erp_cust_az12
WHERE CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
		ELSE cid 
	END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info )

SELECT * FROM Silver.crm_cust_info

-- CHECKING THE BDATE

SELECT BDATE,
	CASE
		WHEN BDATE >= GETDATE() THEN NULL
		ELSE BDATE
	END BDATE1
FROM Bronze.erp_cust_az12
WHERE BDATE <= '1925-01-01' OR BDATE IS NULL OR BDATE >= GETDATE()
ORDER BY BDATE

-- CHECKING THE GEN COLUMN

SELECT DISTINCT GEN
FROM Bronze.erp_cust_az12

SELECT DISTINCT
		GEN AS OLD_GEN,
	CASE
		WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
		ELSE 'n/a'
	END GEN
FROM Bronze.erp_cust_az12

-- CLEAN AND LOADING THE erp_cust_az12

INSERT INTO Silver.erp_cust_az12(
		cid,
		bdate,
		gen
)
SELECT 
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
		ELSE cid 
	END cid,
	CASE
		WHEN BDATE >= GETDATE() THEN NULL
		ELSE BDATE
	END BDATE,
	CASE
		WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
		ELSE 'n/a'
	END GEN
FROM Bronze.erp_cust_az12

-- QUALITY checking data from epr.cust_az12


-- PREPARING CID FOR CST_KEY IN CRM_SALES_DETAILS 
SELECT 
		cid,
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
		ELSE cid 
	END cid,
		bdate,
		gen
FROM Silver.erp_cust_az12
WHERE CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
		ELSE cid 
	END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info )

SELECT * FROM Silver.crm_cust_info

-- CHECKING THE BDATE

SELECT BDATE,
	CASE
		WHEN BDATE >= GETDATE() THEN NULL
		ELSE BDATE
	END BDATE1
FROM Silver.erp_cust_az12
WHERE BDATE <= '1925-01-01' OR BDATE IS NULL OR BDATE >= GETDATE()
ORDER BY BDATE

-- CHECKING THE GEN COLUMN

SELECT DISTINCT GEN
FROM Silver.erp_cust_az12

SELECT DISTINCT
		GEN AS OLD_GEN,
	CASE
		WHEN UPPER(TRIM(GEN)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(GEN)) IN ('M','MALE') THEN 'Male'
		ELSE 'n/a'
	END GEN
FROM Silver.erp_cust_az12

-- CHECKING THE SILVER.erp_loc_a101 TABLE

-- LOOKING FOR UNWANTED SPACES

SELECT CID
FROM Bronze.erp_loc_a101
WHERE CID != TRIM(CID)

SELECT REPLACE(TRIM(CID),'-','') AS CID
FROM Bronze.erp_loc_a101

SELECT * FROM Bronze.erp_loc_a101

-- SURVEYING CTRY COLUMN
-- DATA STANDARDIZATION AND CONSISTENCY

SELECT DISTINCT CNTRY,
	CASE 
		WHEN CNTRY = 'DE' THEN 'Germany'
		WHEN CNTRY IN ('US','USA') THEN 'United States'
		WHEN CNTRY = '' OR CNTRY IS NULL THEN 'n/a'
		ELSE CNTRY
	END CNTRY1
FROM Bronze.erp_loc_a101
ORDER BY CNTRY

-- CLEAN AND LOAD TO Silver.erp_loc_a101

INSERT INTO Silver.erp_loc_a101(
		cid,
		cntry
)
SELECT 
		REPLACE(TRIM(CID),'-','') AS cid,
	CASE 
		WHEN CNTRY = 'DE' THEN 'Germany'
		WHEN CNTRY IN ('US','USA') THEN 'United States'
		WHEN CNTRY = '' OR CNTRY IS NULL THEN 'n/a'
		ELSE CNTRY
	END cntry
FROM Bronze.erp_loc_a101

-- QIALITY CHECKING THE SILVER.erp_loc_a101 TABLE

-- LOOKING FOR UNWANTED SPACES

SELECT CID
FROM Silver.erp_loc_a101
WHERE CID != TRIM(CID)

SELECT REPLACE(TRIM(CID),'-','') AS CID
FROM Silver.erp_loc_a101

SELECT * FROM Silver.erp_loc_a101

-- SURVEYING CTRY COLUMN
-- DATA STANDARDIZATION AND CONSISTENCY

SELECT DISTINCT CNTRY
FROM Silver.erp_loc_a101
ORDER BY CNTRY

-- CHECKING FOR ERRORS

	-- CHECKING FOR NULLS, MISSING VALUE

	SELECT *
	FROM Bronze.erp_px_cat_g1v2
	WHERE ID IS NULL OR
			CAT IS NULL OR
			SUBCAT IS NULL OR
			MAINTENANCE IS NULL

-- CHECKING THE ID COLUMN

SELECT ID
FROM Bronze.erp_px_cat_g1v2
WHERE ID <> TRIM(ID)

SELECT ID
FROM Bronze.erp_px_cat_g1v2

SELECT * FROM Bronze.erp_px_cat_g1v2
WHERE ID NOT IN ( SELECT cat_id FROM Silver.crm_prd_info)

SELECT cat_id FROM Silver.crm_prd_info WHERE cat_id = 'CO-PD'

-- CHECKING THE CATEGORIES COLUMN
-- DATA STANDARDIZATION & CONSISTENCY
-- CHECKING FOR UNWANTED SPACES

SELECT DISTINCT CAT
FROM Bronze.erp_px_cat_g1v2
WHERE CAT <> TRIM(CAT)

-- CHECKING THE SUB CATEGORIES COLUMN
-- DATA STANDARDIZATION & CONSISTENCY

SELECT DISTINCT SUBCAT
FROM Bronze.erp_px_cat_g1v2
WHERE SUBCAT <> TRIM(SUBCAT)

--CHECKING THE MAINTENANCE COLUMN
-- DATA STANDARDIZATION & CONSISTENCY

SELECT DISTINCT MAINTENANCE
FROM Bronze.erp_px_cat_g1v2
WHERE MAINTENANCE <> TRIM(MAINTENANCE)


select * from Silver.crm_prd_info
select * from Bronze.erp_px_cat_g1v2

-- QUALITY CHECK & HEALTH SURVEY

SELECT * FROM Silver.erp_px_cat_g1v2

-- LOADING THE DATA IN Silver.erp_px_cat_g1v2


INSERT INTO Silver.erp_px_cat_g1v2 (
		id,
		cat,
		subcat,
		maintenance
)
SELECT 
		ID,
		CAT,
		SUBCAT,
		MAINTENANCE
FROM Bronze.erp_px_cat_g1v2

