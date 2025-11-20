
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
