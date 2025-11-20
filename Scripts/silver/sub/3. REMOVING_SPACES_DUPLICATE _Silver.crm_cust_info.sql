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

