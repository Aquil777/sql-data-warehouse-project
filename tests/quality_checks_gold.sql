-- object customer
create view gold.dim_customers as 
select row_number() over(order by cst_id) as customer_key, ci.cst_id as customer_id, 
ci.cst_key as customer_number, ci.cst_firstname as first_name, ci.cst_lastname as last_name, 
la.cntry as country, ci.cst_marital_status as marital_status, 
case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is the master for gender info
	else coalesce(ca.gen, 'n/a')
end as gender,
ca.bdate as birthdate, cst_create_date as create_date
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid;

-- object product
create view gold.dim_products as 
select row_number() over (order by pi.prd_start_dt, pi.prd_key) as product_key, pi.prd_id as product_id, 
pi.prd_key as product_number, pi.prd_nm as product_name, pi.cat_id as category_id, 
pc.cat as category, pc.subcat as subcategory, pc.maintenance, pi.prd_cost as product_cost, 
pi.prd_line as product_line, pi.prd_start_dt as product_start_date
from silver.crm_prd_info as pi left join silver.erp_px_cat_g1v2 as pc on pi.cat_id = pc.id
where pi.prd_end_dt is null;

-- object sales\
create view gold.fact_sales as
select sd.sls_order_num as order_number, pr.product_key, cu.customer_key, sd.sls_order_dt as order_date,
sd.sls_ship_dt as shipping_date, sd.sls_due_dt as due_date, sd.sls_sales as sales_amount,
sd.sls_quantity as quantity, sd.sls_price as price
from silver.crm_sales_details as sd left join gold.dim_products as pr on sd.sls_prd_key = pr.product_number
left join gold.dim_customers as cu on sd.sls_cust_id = cu.customer_id;