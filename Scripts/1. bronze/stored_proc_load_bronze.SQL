/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS

BEGIN
		DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		PRINT '==================================================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '==================================================';

		PRINT '--------------------------------------------------';
		PRINT 'LOADING CRM TABLES';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE();

		SET @batch_start_time = GETDATE();
		PRINT '>>TRUNCATING THE TABLE: Bronze.crm_cust_info';
		TRUNCATE TABLE Bronze.crm_cust_info;

		PRINT '>>INSERTING THE DATA INTO: Bronze.crm_cust_info';

		BULK INSERT Bronze.crm_cust_info
		FROM 'C:\SQL-projects\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001',  -- UTF-8
			TABLOCK,
			CHECK_CONSTRAINTS
			--ERRORFILE = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\ErrorLogs\cust_info_errors.log'
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + cast(Datediff(Second, @start_time, @end_time) as NVARCHAR) + 'Seconds';
		PRINT '>> ---------------'

		SET @start_time = GETDATE();
		PRINT '>>TRUNCATING THE TABLE: Bronze.crm_prd_info';
		TRUNCATE TABLE Bronze.crm_prd_info;

		PRINT '>>INSERTING THE DATA INTO: Bronze.crm_prd_info';
		BULK INSERT Bronze.crm_prd_info
		FROM 'C:\SQL-projects\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001',  -- UTF-8
			TABLOCK,
			CHECK_CONSTRAINTS
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + cast(Datediff(Second, @start_time, @end_time) as NVARCHAR) + 'Seconds';
		PRINT '>> ---------------'

		SET @start_time = GETDATE();
		PRINT '>>TRUNCATING THE TABLE: Bronze.crm_sales_details';
		TRUNCATE TABLE Bronze.crm_sales_details;

		PRINT '>>INSERTING THE DATA INTO: Bronze.crm_sales_details';
		BULK INSERT Bronze.crm_sales_details
		FROM 'C:\SQL-projects\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001',  -- UTF-8
			TABLOCK,
			CHECK_CONSTRAINTS
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + cast(Datediff(Second, @start_time, @end_time) as NVARCHAR) + 'Seconds';
		PRINT '>> ---------------'


		PRINT '--------------------------------------------------';
		PRINT 'LOADING ERP TABLES';
		PRINT '--------------------------------------------------';


		SET @start_time = GETDATE();
		PRINT '>>TRUNCATING THE TABLE: Bronze.erp_cust_az12';
		TRUNCATE TABLE Bronze.erp_cust_az12;

		PRINT '>>INSERTING THE DATA INTO: Bronze.erp_cust_az12';
		BULK INSERT Bronze.erp_cust_az12
		FROM 'C:\SQL-projects\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',	
			CODEPAGE = '65001',  -- UTF-8
			TABLOCK,
			CHECK_CONSTRAINTS
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + cast(Datediff(Second, @start_time, @end_time) as NVARCHAR) + 'Seconds';
		PRINT '>> ---------------'


		SET @start_time = GETDATE();
		PRINT '>>TRUNCATING THE TABLE: Bronze.erp_loc_a101';
		TRUNCATE TABLE Bronze.erp_loc_a101;
	
		PRINT '>>INSERTING THE DATA INTO: Bronze.erp_loc_a101';
		BULK INSERT Bronze.erp_loc_a101
		FROM 'C:\SQL-projects\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001',  -- UTF-8
			TABLOCK,
			CHECK_CONSTRAINTS
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + cast(Datediff(Second, @start_time, @end_time) as NVARCHAR) + 'Seconds';
		PRINT '>> ---------------'


		SET @start_time = GETDATE();
		PRINT '>>TRUNCATING THE TABLE: Bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE Bronze.erp_px_cat_g1v2;

		PRINT '>>INSERTING THE DATA INTO: Bronze.erp_px_cat_g1v2';
		BULK INSERT Bronze.erp_px_cat_g1v2
		FROM 'C:\SQL-projects\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			CODEPAGE = '65001',  -- UTF-8
			TABLOCK,
			CHECK_CONSTRAINTS
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + cast(Datediff(Second, @start_time, @end_time) as NVARCHAR) + 'Seconds';
		PRINT '>> ---------------'


		SET @batch_end_time = GETDATE();
		PRINT ' >>>>>>>>>>>>>>>>>>>>>>>>'
		PRINT 'LOADING BRONZE LAYER IS COMPLETE'
		PRINT '		- TOTAL LOAD DURATION : ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + 'SECONDS'
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
END CATCH;
END
