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
