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