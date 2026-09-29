-- load o data seguido de testes basicos
create or alter procedure bronze.load_bronze as 
begin
	declare @start_time datetime, @end_time datetime, @layer_start_time datetime, @layer_end_time datetime;
	begin try
		set @layer_start_time = GETDATE();
		print '================================================';
		print 'Loading Bronze Layer';
		print '================================================';

		print 'Loading crm folder'
		print '================================================';
		set @start_time = getdate();
		truncate table bronze.crm_cust_info; -- esvaziar tabela
		print 'Inserting data into bronze.crm_cust_info'
		bulk insert bronze.crm_cust_info
		from 'C:\Users\Aquil\Desktop\Cyberseguranca\Analise de dados\sql-data-warehouse-project-2\datasets\source_crm\cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ','
		);
		set @end_time = getDate();
		print 'Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		print ' ------------------------------------------------';

		-- tabela bronze.crm_prd_info
		set @start_time = getdate();
		truncate table bronze.crm_prd_info;
		print 'Inserting data into bronze.crm_prd_info'
		bulk insert bronze.crm_prd_info
		from 'C:\Users\Aquil\Desktop\Cyberseguranca\Analise de dados\sql-data-warehouse-project-2\datasets\source_crm\prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ','
		);
		set @end_time = getDate();
		print 'Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		print ' ------------------------------------------------';

		-- tabela bronze.crm_sales_details
		set @start_time = getdate();
		truncate table bronze.crm_sales_details;
		print 'Inserting data into bronze.crm_sales_details'
		bulk insert bronze.crm_sales_details
		from 'C:\Users\Aquil\Desktop\Cyberseguranca\Analise de dados\sql-data-warehouse-project-2\datasets\source_crm\sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ','
		);
		set @end_time = getDate();
		print 'Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		print ' ------------------------------------------------';

		print '================================================';
		print 'Loading erp folder';
		print '================================================';
		-- tabela bronze.erp_cust_az12
		set @start_time = getdate();
		truncate table bronze.erp_cust_az12;
		print 'Inserting data into bronze.erp_cust_az12'
		bulk insert bronze.erp_cust_az12
		from 'C:\Users\Aquil\Desktop\Cyberseguranca\Analise de dados\sql-data-warehouse-project-2\datasets\source_erp\CUST_AZ12.csv'
		with (
			firstrow = 2,
			fieldterminator = ','
		);
		set @end_time = getDate();
		print 'Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		print ' ------------------------------------------------';

		-- tabela bronze.erp_loc_a101
		set @start_time = getdate();
		truncate table bronze.erp_loc_a101;
		print 'Inserting data into bronze.erp_loc_a101'
		bulk insert bronze.erp_loc_a101
		from 'C:\Users\Aquil\Desktop\Cyberseguranca\Analise de dados\sql-data-warehouse-project-2\datasets\source_erp\LOC_A101.csv'
		with (
			firstrow = 2,
			fieldterminator = ','
		);
		set @end_time = getDate();
		print 'Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		print ' ------------------------------------------------';

		-- tabela bronze.erp_px_cat_g1v2
		set @start_time = getdate();
		truncate table bronze.erp_px_cat_g1v2;
		print 'Inserting data into bronze.erp_px_cat_g1v2'
		bulk insert bronze.erp_px_cat_g1v2
		from 'C:\Users\Aquil\Desktop\Cyberseguranca\Analise de dados\sql-data-warehouse-project-2\datasets\source_erp\PX_CAT_G1V2.csv'
		with (
			firstrow = 2,
			fieldterminator = ','
		);
		set @end_time = getDate();
		print 'Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		print ' ------------------------------------------------';
		set @layer_end_time = GETDATE();
		print 'Layer Load Duration:' + cast(datediff(second, @layer_start_time, @layer_end_time) 
		as nvarchar) + ' seconds';
	end try
	begin catch
		print 'Error Message: ' + ERROR_MESSAGE();
		print 'Error Message: ' + cast (ERROR_NUMBER() as nvarchar);
	end catch
end