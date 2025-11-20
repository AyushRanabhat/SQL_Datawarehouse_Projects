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