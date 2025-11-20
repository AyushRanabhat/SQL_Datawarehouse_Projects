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