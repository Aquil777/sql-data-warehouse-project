-- check for nulls and duplicates in pk.
-- expectation: null

select cst_id, count(*)
from silver.crm_cust_info
group by cst_id having count(*) > 1 or cst_id is null;

select * from
(select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
from silver.crm_cust_info)t where flag_last != 1;

-- check for unwanted spaces
-- if the og value aint equal to the same value after trimming, it means there are spaces
-- expectation: null
-- mudar os valores de categoria para friendly names
-- confirmar q as colunas de data sao de tipo data e nao nvarchar
-- remove empty values
select cst_firstname from silver.crm_cust_info
where cst_firstname != trim(cst_firstname);

select cst_lastname from silver.crm_cust_info
where cst_lastname != trim(cst_lastname);

select cst_gndr from silver.crm_cust_info
where cst_gndr != trim(cst_gndr);

select distinct cst_gndr from silver.crm_cust_info;
select distinct cst_marital_status from silver.crm_cust_info;

select * from silver.crm_cust_info;
-- ============================ tabela crm_prd_info ==================================== 
select prd_id, count(*) from silver.crm_prd_info
group by prd_id having count(*) > 1 or prd_id = null;

select * from silver.crm_prd_info;

select prd_nm from silver.crm_prd_info
where prd_nm != trim(prd_nm);

select distinct prd_line from silver.crm_prd_info;

-- check for invalid date orders
select * from silver.crm_prd_info where prd_end_dt < prd_start_dt;

-- ============================ tabela crm_sales_details ===================================
select nullif(sls_order_dt, 0) as sls_order_dt
from silver.crm_sales_details
where sls_order_dt <= 0 or len(sls_order_dt) != 8 
or sls_order_dt > 20500101 or sls_order_dt < 19000101;

select nullif(sls_ship_dt, 0) as sls_ship_dt
from silver.crm_sales_details
where sls_ship_dt <= 0 or len(sls_ship_dt) != 8 
or sls_ship_dt > 20500101 or sls_ship_dt < 19000101;

select nullif(sls_due_dt, 0) as sls_due_dt
from silver.crm_sales_details
where sls_due_dt <= 0 or len(sls_due_dt) != 8 
or sls_due_dt > 20500101 or sls_due_dt < 19000101;

select * from silver.crm_sales_details where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt;

-- sales = quantity * price
-- values mustnt be null, negative or 0
select distinct sls_sales, sls_quantity, sls_price from silver.crm_sales_details
where sls_sales != sls_quantity * sls_price or
sls_sales is null or sls_quantity is null or sls_price is null or
sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0;

select * from silver.crm_sales_details;

-- ================================Tabela erp_cust_az12==================================
select * from silver.erp_cust_az12;

select 
case when cid like 'NAS%' then substring(cid, 4, len(cid))
	else cid
end as cid,
bdate, gen
from silver.erp_cust_az12
where case when cid like 'NAS%' then substring(cid, 4, len(cid))
	else cid
end not in (select distinct cst_key from silver.crm_cust_info);

select distinct bdate from silver.erp_cust_az12 where bdate > getdate();

select distinct gen from silver.erp_cust_az12;

select cst_id, cst_key from silver.crm_cust_info;

-- ================================ Tabela erp_loc_a101 ==================================
select * from silver.erp_loc_a101;
select cst_key from silver.crm_cust_info;

-- ver se a fk daqui e diferente ao og
select cid from silver.erp_loc_a101 where cid not in (select cst_key from silver.crm_cust_info); 

select distinct cntry from silver.erp_loc_a101;

-- ================================= tabela erp_px_cat_g1v2 ==============================
select * from bronze.erp_px_cat_g1v2;