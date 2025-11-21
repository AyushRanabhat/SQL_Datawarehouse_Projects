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