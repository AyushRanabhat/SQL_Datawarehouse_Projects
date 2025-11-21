/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/


CREATE OR ALTER PROCEDURE proc_load_silver AS
	BEGIN 
		DECLARE @start_time as DATETIME, @end_time as DATETIME, @batch_start_time as DATETIME, @batch_end_time as DATETIME;
	BEGIN TRY 
			PRINT '=================================================';
			PRINT 'COMMENICING TO LOAD DATA INTO SILVER TABLE';
			PRINT '=================================================';

			PRINT '------------------------------------------------';
			PRINT 'Loading CRM Tables';
			PRINT '------------------------------------------------';

			SET @start_time = GETDATE();
			SET @batch_start_time = GETDATE();

			PRINT '>>>>>>>TRUNCATING TABLE: silver.crm_cust_info' ;

	TRUNCATE TABLE silver.crm_cust_info
			PRINT '---------------------------------------------------';

			PRINT 'INSERTING INTO TABLE: silver.crm_cust_info';

	INSERT INTO silver.crm_cust_info(
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

		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS'
		PRINT '=================================================';
	---------------------------------------------

			SET @Start_time = GETDATE();

			PRINT '>>>>>>>TRUNCATING TABLE: silver.crm_prd_info' ;

	TRUNCATE table silver.crm_prd_info

			PRINT '---------------------------------------------------';

			PRINT 'INSERTING INTO TABLE: silver.crm_prd_info';

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

				SET @end_time = GETDATE();
				PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS'
				PRINT '=================================================';
		---------------------------------------------

			
			SET @Start_time = GETDATE();

			PRINT '>>>>>>>TRUNCATING TABLE: silver.crm_sales_details' ;
			
	TRUNCATE TABLE silver.crm_sales_details

			PRINT '---------------------------------------------------';

			PRINT 'INSERTING INTO TABLE: silver.crm_sales_details';

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

			SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS'
		PRINT '=================================================';
	---------------------------------------------
		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

			SET @start_time = GETDATE();

			PRINT 'TRUNCATING INTO TABLE: silver.erp_cust_az12';

	TRUNCATE TABLE Silver.erp_cust_az12;

			PRINT '---------------------------------------------------';

			PRINT 'INSERTING INTO TABLE: silver.erp_cust_az12';

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

			SET @end_time = GETDATE();
			PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS'
			PRINT '=================================================';
	---------------------------------------------
			SET @Start_time = GETDATE();

			PRINT '>>>>>>>TRUNCATING TABLE: silver.erp_loc_a101' ;

	TRUNCATE table silver.erp_loc_a101

			PRINT '---------------------------------------------------';

			PRINT 'INSERTING INTO TABLE: silver.erp_loc_a101';
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

			SET @end_time = GETDATE();
			PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS'
			PRINT '=================================================';

	---------------------------------------------
			SET @Start_time = GETDATE();

			PRINT '>>>>>>>TRUNCATING TABLE: silver.erp_px_cat_g1v2' ;

	TRUNCATE table silver.erp_px_cat_g1v2

			PRINT '---------------------------------------------------';

			PRINT 'INSERTING INTO TABLE: silver.erp_px_cat_g1v2';

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

		SET @end_time = GETDATE();
		PRINT 'LOAD DURATION : ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS'
		PRINT '=================================================';
		SET @batch_end_time = GETDATE();
		PRINT ' >>>>>>>>>>>>>>>>>>>>>>>>'
		PRINT 'LOADING SILVER LAYER IS COMPLETE'
		PRINT '		>>> TOTAL LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + 'SECONDS'
		PRINT ' >>>>>>>>>>>>>>>>>>>>>>>>'
	END TRY
	BEGIN CATCH
			PRINT '==============================================';
			PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
			PRINT 'ERROR MESSAGE ' + ERROR_MESSAGE();
			PRINT ' ERROR NUMBER ' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT('Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR));
			PRINT('Error State: ' + CAST(ERROR_STATE() AS NVARCHAR));
			PRINT('Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR));
			PRINT('Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A'));
			PRINT '==============================================';
	END CATCH
END
