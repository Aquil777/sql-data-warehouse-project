-- passos a se fazer antes de por no gold layer

-- o q esta por fora de parenteses e confirmacao de nao ter duplo pk
select cst_id, count(*) from
(select  ci.cst_id, ci.cst_key, ci.cst_firstname, ci.cst_lastname, ci.cst_marital_status, ci.cst_gndr,
cst_create_date, ca.bdate, ca.gen, la.cntry
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid)t
group by cst_id, cst_key having count(*) > 1; 

-- data integration: tem duas colunas iguais no resultado, entao confirmar q os dados sao iguais nas
-- duas tabelas
select distinct ci.cst_gndr, ca.gen
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid order by 1,2;

-- se ver inconsistencia, entao perguntar qual o certo
-- se o crm estiver certo:
select distinct ci.cst_gndr, ca.gen,
case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is the master for gender info
	else coalesce(ca.gen, 'n/a')
end as new_gen
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid;

-- ja integrados, so e por na consulta
select  ci.cst_id, ci.cst_key, ci.cst_firstname, ci.cst_lastname, ci.cst_marital_status, 
case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is the master for gender info
	else coalesce(ca.gen, 'n/a')
end as new_gen,
cst_create_date, ca.bdate, la.cntry
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid;

-- dar friendly name as colunas
select  ci.cst_id as customer_id, ci.cst_key as customer_number, ci.cst_firstname as first_name, 
ci.cst_lastname as last_name, ci.cst_marital_status as marital_status, 
case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is the master for gender info
	else coalesce(ca.gen, 'n/a')
end as gender,
cst_create_date as create_date, ca.bdate as birthdate, la.cntry as country
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid;

-- sort the columns into logical groups to improve readibility
select  ci.cst_id as customer_id, ci.cst_key as customer_number, ci.cst_firstname as first_name, 
ci.cst_lastname as last_name, la.cntry as country, ci.cst_marital_status as marital_status, 
case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is the master for gender info
	else coalesce(ca.gen, 'n/a')
end as gender,
ca.bdate as birthdate, cst_create_date as create_date
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid;

-- dimension or fact table?
-- surrogate key para as tabelas caso a tabela resultante nao tenha pk q pode rely on
-- sempre termina com "key". e um numero gerado automaticamente
select row_number() over(order by cst_id) as customer_key, ci.cst_id as customer_id, 
ci.cst_key as customer_number, ci.cst_firstname as first_name, ci.cst_lastname as last_name, 
la.cntry as country, ci.cst_marital_status as marital_status, 
case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- crm is the master for gender info
	else coalesce(ca.gen, 'n/a')
end as gender,
ca.bdate as birthdate, cst_create_date as create_date
from silver.crm_cust_info ci left join silver.erp_cust_az12 ca on ci.cst_key = ca.cid left join
silver.erp_loc_a101 as la on ci.cst_key = la.cid;

-- criar o object. sera virtual, ja q e gold layer aka view
-- confirmar q esta limpo
select distinct gender from gold.dim_customers;

-- ==============================================================================================
-- Object Products

-- sacar historization (caso nao precise dela)
select prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt
from silver.crm_prd_info where prd_end_dt is null;

-- join com o erp irmao e ver a qualidade do resultado (ver se ha duplicates)
select prd_key, count(*) from
( select pi.prd_id, pi.cat_id, pi.prd_key, pi.prd_nm, pi.prd_cost, pi.prd_line, pi.prd_start_dt,
pc.cat, pc.subcat, pc.maintenance
from silver.crm_prd_info as pi left join silver.erp_px_cat_g1v2 as pc on pi.cat_id = pc.id
where pi.prd_end_dt is null)t group by prd_key having count(*) > 1;

-- reorganizar as colunas e dar friendly names
select pi.prd_id as product_id, pi.prd_key as product_number, pi.prd_nm as product_name, 
pi.cat_id as category_id, pc.cat as category, pc.subcat as subcategory, pc.maintenance, 
pi.prd_cost as product_cost, pi.prd_line as product_line, pi.prd_start_dt as product_start_date
from silver.crm_prd_info as pi left join silver.erp_px_cat_g1v2 as pc on pi.cat_id = pc.id
where pi.prd_end_dt is null;

-- fact or dimension? surrogate key
select row_number() over (order by pi.prd_start_dt, pi.prd_key) as product_key, pi.prd_id as product_id, 
pi.prd_key as product_number, pi.prd_nm as product_name, pi.cat_id as category_id, 
pc.cat as category, pc.subcat as subcategory, pc.maintenance, pi.prd_cost as product_cost, 
pi.prd_line as product_line, pi.prd_start_dt as product_start_date
from silver.crm_prd_info as pi left join silver.erp_px_cat_g1v2 as pc on pi.cat_id = pc.id
where pi.prd_end_dt is null;

select * from gold.dim_products;

-- ==============================================================================================
-- Object Sales

-- nao tem join algum, entao ir directo a dimension or fact?
-- se for fact, entao substituir os fk actuais pelos sk das dimensoes
select * from silver.crm_sales_details;

-- fazer data lookup: use the dimension's sk instead of ids to easily connect facts with dimensions
select sd.sls_order_num, pr.product_key, cu.customer_key, sd.sls_order_dt, sls_ship_dt, sd.sls_due_dt,
sd.sls_sales, sd.sls_quantity, sd.sls_price
from silver.crm_sales_details as sd left join gold.dim_products as pr on sd.sls_prd_key = pr.product_number
left join gold.dim_customers as cu on sd.sls_cust_id = cu.customer_id;

-- dar friendly names
select sd.sls_order_num as order_number, pr.product_key, cu.customer_key, sd.sls_order_dt as order_date,
sd.sls_ship_dt as shipping_date, sd.sls_due_dt as due_date, sd.sls_sales as sales_amount,
sd.sls_quantity as quantity, sd.sls_price as price
from silver.crm_sales_details as sd left join gold.dim_products as pr on sd.sls_prd_key = pr.product_number
left join gold.dim_customers as cu on sd.sls_cust_id = cu.customer_id;

-- facts tables devem estar organizados de seguinte forma: dimension keys, dates, measures and metrics

-- para confirmar q o fact table esta nice, deve fazer join com as suas dimensions
select * 
from gold.fact_sales as fs left join gold.dim_products as pr on fs.product_key = pr.product_key
where pr.product_key is null;

select * 
from gold.fact_sales as fs left join gold.dim_customers as pr on fs.customer_key = pr.customer_key
where pr.customer_key is null;

-- num star schema, a relacao entre o dimension e fact e 1:n