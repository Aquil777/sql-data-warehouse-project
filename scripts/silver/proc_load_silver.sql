-- executar stored procedure
exec silver.load_silver;

create or alter procedure silver.load_silver as 
begin
	declare @start_time datetime, @end_time datetime, @start_layer_time datetime, @end_layer_time datetime;
	begin try
	set @start_layer_time = GETDATE();
	print '================================================';
	print 'Loading Silver Layer';
	print '================================================';
	print 'Loading crm folder'
	print '================================================';
	-- uma vez q os dados estao limpos, insere no silver table
	set @start_time = GETDATE();
	truncate table silver.crm_cust_info;
	print 'Loading data from silver.crm_cust_info';
	insert into silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status,
	cst_gndr, cst_create_date)
	select cst_id, 
	cst_key,
	trim(cst_firstname) as cst_firstname,  
	trim(cst_lastname) as cst_lastname,
	case when upper(trim(cst_marital_status)) = 'S' then 'Single'
		when upper(trim(cst_marital_status)) = 'M' then 'Married'
		else 'n/a'
	end cst_marital_status,
	case when upper(trim(cst_gndr)) = 'M' then 'Male'
		when upper(trim(cst_gndr)) = 'F' then 'Female'
		else 'n/a'
	end cst_gndr,
	cst_create_date
	from
	(select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
	from bronze.crm_cust_info)t where flag_last = 1;
	set @end_time = GETDATE();
	print 'Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
	print '================================================';

	--verificar de novo se esta limpo com as queries antes usadas

	-- tabela bronze.crm_prd_info
	set @start_time = GETDATE();
	truncate table silver.crm_prd_info;
	print 'Loading data from silver.crm_prd_info';
	insert into silver.crm_prd_info (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt,
	prd_end_dt)
	select prd_id,
	replace(substring(prd_key,1,5), '-', '_') as cat_id,
	substring(prd_key, 7, len(prd_key)) as prd_key,
	prd_nm,
	isnull(prd_cost, 0) as prd_cost,
	case upper(trim(prd_line))
		when 'M' then 'Mountain'
		when 'R' then 'Road'
		when 'S' then 'Other Sales'
		when 'T' then 'Touring'
		else 'n/a'
	end as prd_line,
	prd_start_dt,
	cast(cast(lead(prd_start_dt) over 
	(partition by prd_key order by prd_start_dt) as datetime) -1 as date) as prd_end_dt --calculate end date as one day before the next start date
	from bronze.crm_prd_info;
	set @end_time = GETDATE();
	print 'Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
	print '================================================';

	-- tabela crm_sales_details
	set @start_time = GETDATE();
	truncate table silver.crm_sales_details;
	print 'Loading data from silver.crm_sales_details';
	insert into silver.crm_sales_details (sls_order_num, sls_prd_key, sls_cust_id, sls_order_dt,
	sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
	select sls_order_num, sls_prd_key, sls_cust_id,
	case when sls_order_dt <= 0 or len(sls_order_dt) != 8 then null
		else cast(cast(sls_order_dt as varchar) as date)
	end as sls_order_dt,
	case when sls_ship_dt <= 0 or len(sls_ship_dt) != 8 then null
		else cast(cast(sls_ship_dt as varchar) as date)
	end as sls_ship_dt,
	case when sls_due_dt <= 0 or len(sls_due_dt) != 8 then null
		else cast(cast(sls_due_dt as varchar) as date)
	end as sls_due_dt,
	case when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * sls_price
		then sls_quantity * abs(sls_price)
		else sls_sales
	end as sls_sales,
	sls_quantity,
	case when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity,0)
		else sls_price
	end as sls_price
	from bronze.crm_sales_details;
	set @end_time = GETDATE();
	print 'Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
	print '================================================';

	print 'Loading erp folder'
	print '================================================';
	-- tabela erp_cust_az12
	set @start_time = GETDATE();
	truncate table silver.erp_cust_az12;
	print 'Loading data from silver.erp_cust_az12';
	insert into silver.erp_cust_az12 (cid, bdate, gen)
	select 
	case when cid like 'NAS%' then substring(cid, 4, len(cid))
		else cid
	end as cid,
	case when bdate > GETDATE() then null
		else bdate
	end as bdate,
	case when upper(trim(gen)) in ('M', 'MALE') then 'Male'
		 when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
		 else 'n/a'
	end as gen
	from bronze.erp_cust_az12;
	set @end_time = GETDATE();
	print 'Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
	print '================================================';

	-- tabela erp_loc_a101
	set @start_time = GETDATE();
	truncate table silver.erp_loc_a101;
	print 'Loading data from silver.erp_loc_a101';
	insert into silver.erp_loc_a101 (cid, cntry)
	select 
	replace(cid, '-', '') as cid,
	case 
		when trim(cntry)  = 'DE' then 'Germany'
		when trim(cntry)  in ('USA','US') then 'United States'
		when trim(cntry)  is null or  trim(cntry)  = '' then 'n/a'
		else cntry
	end as cntry
	from bronze.erp_loc_a101;
	set @end_time = GETDATE();
	print 'Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
	print '================================================';

	-- tabela erp_px_cat_g1v2
	set @start_time = GETDATE();
	truncate table silver.erp_px_cat_g1v2;
	print 'Loading data from silver.erp_px_cat_g1v2';
	insert into silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
	select id, cat, subcat, maintenance from bronze.erp_px_cat_g1v2;
	set @end_time = GETDATE();
	print 'Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
	print '================================================';
	set @end_layer_time = GETDATE();
	print 'Silver Layer Load duration: ' + cast(datediff(second, @start_layer_time, @end_layer_time) as nvarchar) + 'seconds';
	print '================================================';
	end try
	begin catch
		print 'Error Message: ' + ERROR_MESSAGE();
		print 'Error Message: ' + cast(ERROR_NUMBER() as nvarchar);
	end catch
end